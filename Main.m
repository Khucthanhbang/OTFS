function Main(FirstParamsNum, Step4ParamsNum, isRegression)
%
% Главный запускаемый файл модели
%   Входных переменных может быть 0, 1, 2 или 3. Значения по умолчанию:
%       FirstParamsNum = 1;
%       Step4ParamsNum = 1;
%       isRegression = 0;
%
% Входные переменные:
%   Если имеется только одна входная переменная, то FirstParamsNum - массив
%       значений номеров наборов параметров, для которых нужно выполнить
%       моделирование.
%   Если входных переменных две, то FirstParamsNum - номер первого набора
%       параметров, Step4ParamsNum - шаг для перехода к последующему
%       набору параметров. Пара этих переменных предназначена, прежде
%       всего, для запуска модели на нескольких узлах.

    % Очистка command window, закрытие всего
        clc;
        close all;
        
    % Инициализация всех случайных генераторов
        rng('default');

    % Проверим количество входных переменных
        if ~(nargin >= 0 && nargin <= 3)
            error(['The number of input arguments to the Main should ', ...
                'be equal to 0, 1, 2, or 3']);
        end

    % Определим значения FirstParamsNum, Step4ParamsNum   
        if nargin == 0
            FirstParamsNum = 1;
            Step4ParamsNum = 1;
            isRegression = 0;
        elseif nargin == 1
            Step4ParamsNum = 1;
            isRegression = 0;
        elseif nargin == 2
            isRegression = 0;
        else
        end
        
    % Проверка корректности значений входных переменных
        validateattributes(FirstParamsNum, {'double'}, {'vector', ...
            'integer', 'positive'});
        if nargin == 1
            validateattributes(FirstParamsNum, {'double'}, {'scalar'})
        end
        validateattributes(Step4ParamsNum, {'double'}, {'scalar', ...
            'integer', 'positive'});
        validateattributes(isRegression, {'double', 'logical'},...
            {'scalar', 'binary'});
        
    % Подготовим глобальные переменные Ruler и Objs для возможности очистки
    % выделенной под объекты памяти из любой точки программы, а также
    % FieldNames для упрощения перебора типовых операций для разных
    % объектов
        global Ruler Objs FieldNames
        
        FieldNames = { ...
            'SchSource', ...
            'NrSch', ...
            'NrSML', ...
            'NrOFDM', ...
            'NrOTFS', ...
            'SEFDM', ...
            'Sig', ...
            'NrChannel' ...
        };
    
    % Считывание параметров, значения которых отличаются от значений по
    % умолчанию
        if isRegression
            Params = ReadSetup('RegressionSetup');
        else
            Params = ReadSetup('AllSetup');
        end

    % Определим массив значений kVals - номеров параметров, для которых
    % должен быть выполнен расчёт (на данном узле)
        % Общее количество наборов параметров
            NumParams = length(Params);
        if nargin == 1
            kVals = FirstParamsNum;
        else
            kVals = FirstParamsNum : Step4ParamsNum : NumParams;
        end

    % Проверка значений kVals
        if (min(kVals) < 1) || (max(kVals) > NumParams)
            error('Invalid value of number for parameters set');
        end
        
    % Цикл по набору параметров
        for k = kVals
            % Создание Ruler, инициализация и проверка параметров Common и
            % BER
                Ruler = ClassBERRuler(Params{k}, k, NumParams);

            % Создание остальных объектов, инициализация и проверка их
            % параметров, кросспроверка параметров, установка параметров,
            % первичное и вторичное вычисление внутренних переменных
            % объектов
                Objs = PrepareObjects(Ruler, Params{k});

            % Переход в режим параллельных вычислений (при необходимости)
                Ruler.StartParallel();

            % Сброс генераторов случайных чисел в начальное состояние
                Ruler.ResetRandStreams();
                
            % Цикл для одного набора параметров
                while ~Ruler.isStop
                    % Обработка очередного блока кадров
                        if Ruler.NumWorkers > 1
                            parfor n = 1:Ruler.NumWorkers
                                Objs{n} = LoopFun(Objs{n}, Ruler, n); %#ok<PFGV,PFGP>
                            end
                        else
                            Objs{1} = LoopFun(Objs{1}, Ruler, 1);
                        end
                    % Обработка результатов
                        isPointFinished = Ruler.Step(Objs);
                        
                    % Сохранение результатов при окончании расчёта
                    % очередной точки
                        if isPointFinished
                            Ruler.Saves(Objs, Params{k});
                        end
                end

            % Выход из параллельных вычислений (при необходимости)
                if isequal(k, kVals(end))
                    Ruler.StopParallel();
                end

            % Удаление всех объектов
                DeleteObjects();
        end
        
        clear global Ruler Objs FieldNames
        
        restoredefaultpath;
end
function Objs = LoopFun(inObjs, Ruler, WorkerNum)
% Цикл для одного набора параметров

    % Хотя все объекты в модели типа handle, т.е. фактически это указатели,
    % тем не менее, для корректной работы parfor нужо делать явное
    % переприсвоение результатов на выход (https://www.mathworks.com/help/
    % distcomp/objects-and-handles-in-parfor-loops.html)
        Objs = inObjs;

    % Цикл по количеству кадров
        for k = 1:Ruler.OneWorkerNumOneIterFrames(WorkerNum)
            % Передатчик
                % Генерирование полезных данных
                    Frame.TxData = Objs.SchSource.Step();
                    
                % SCH Encoder
                    Frame.TxDataTmp = Objs.NrSch.StepTx(Frame.TxData);
                    
                % Отображение на модуляционные символы + scrambling + ...
                % LayerMapping
                    Frame.TxModSymbols = Objs.NrSML.StepTx( ...
                        Frame.TxDataTmp);
                    
                % Генерирование сигнала (OFDM, ...)
                    Frame.TxSignal = Objs.Sig.StepTx( ...
                        Frame.TxModSymbols);

            if Ruler.isBER
            % Канал
                [Frame.RxSignal, InstChan] = Objs.NrChannel.Step( ...
                    Objs, Frame.TxSignal, Ruler.h2dB);

            % Приёмник
                % Обработка принятого сигнала - вычисление
                % модуляционных символов
                    [Frame.RxModSymbols, VarVals] = Objs.Sig.StepRx( ...
                        Frame.RxSignal, InstChan);

                % Demodulation + descrambling
                    Frame.RxDataTmp = Objs.NrSML.StepRx( ...
                        Frame.RxModSymbols, VarVals);
                    
                % Decoding
                    [Frame.RxData, ~] = Objs.NrSch.StepRx( ...
                        Frame.RxDataTmp);
            end

            % Накопление статистики по текущему Frame
                Objs.Stat.Step(Frame, Objs.Sig);
        end
end
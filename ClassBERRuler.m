classdef ClassBERRuler < handle
% Класс-менеджер, управляющий работой модели для одного набора параметров.
% Предусмотрены два возможных режима - расчёт кривых помехоустойчивости
% (BER и FER) и расчёт комплементарной ЭФР (CCDF) для мгновенных значений
% мощности сигнала, нормированных на среднее значение и выраженных в дБ.
%
% -------------------------------------------------------------------------
% В режиме расчёта кривых помехоустойчивости расчёт текущей точки
% останавливается, если
%   ) превышена сложность или
%   ) набрана достаточная статистика и количество переданных кадров
%     больше либо равно, чем MinNumTrFrames
%
% Основной расчёт кривой помехоустойчивости останавливается, если
%   ) превышена сложность или
%   ) превышено ограничение максимального значения h2
%
% Сложность превышена, если передано бит больше, чем MaxNumTrBits, или
%   передано кадров больше, чем MaxNumTrFrames.
%
% Целевые вероятности ошибок достигнуты, если оценка вероятности
%   битовой ошибки меньше либо равна, чем MinBER, и оценка вероятности
%   кадровой ошибки меньше либо равна, чем MinFER.
%
% Статистика считается достаточной, если количество битовых ошибок
%   больше либо равно, чем MinNumErBits, и количество кадровых ошибок
%   больше либо равно, чем MinNumErFrames.
%
% Дополнительный расчёт точек кривой помехоустойчивости ведётся до тех
%   пор, пока для всех соседних точек кривой помехоустойчивости не
%   будет верно, что
%   ) отношение вероятностей битовой ошибки между соседними точками
%     меньше либо равно, чем MaxBERRate, или
%   ) разница h2 между этими точками меньше либо равна h2dBMinStep.
%
% -------------------------------------------------------------------------
% В режиме расчёта комплементарной ЭФР расчёт ведётся сразу для всего
% интересующего набора значений нормированной мгновенной мощности в дБ -
% PAPRVals - и останавливается, если
%   ) превышена сложность или
%   ) набрана достаточная статистика и количество сгенерированных кадров
%     больше либо равно, чем MinNumPAPRFrames
% 
% Сложность превышена, если сгенерировано бит больше, чем MaxNumPAPRBits,
% или сгенерировано кадров больше, чем MaxNumPAPRFrames или рассмотрено
% отсчётов сигнала больше, чем MaxNumPAPRSamples.
%
% Статистика считается достаточной, если среди рассматриваемых значений
% PAPRVals имеется хотя бы одно, вероятность появления которого <= заданной
% вероятности MinPAPRProb и количество появлений которого больше либо
% равно, чем MinNumPAPRSamples, также при этом количество сгенерированных
% кадров больше, чем MinNumPAPRFrames.

properties (Constant)
    % [MCS, h2dB] 24...31 - TBD
    h2dB0_1BERperMCSnoLDPC = ...
       [0,  0; ...
        1,  0; ...
        2,  0; ...
        3,  0; ...
        4,  0; ...
        5,  0; ...
        6,  0; ...
        7,  0; ...
        8,  0; ...
        9,  0; ...
        10, 3; ...
        11, 3; ...
        12, 3; ...
        13, 3; ...
        14, 3; ...
        15, 3; ...
        16, 3; ...
        17, 6; ...
        18, 6; ...
        19, 6; ...
        20, 6; ...
        21, 6; ...
        22, 6; ...
        23, 6; ...
        24, 0; ...
        25, 0; ...
        26, 0; ...
        27, 0; ...
        28, 0; ...
        29, 0; ...
        30, 0; ...
        31, 0];
    h2dB0_1BERperMCSwithLDPC = ...
       [0,  0.2; ...
        1,  0.2; ...
        2,  0.2; ...
        3,  0.2; ...
        4,  0.2; ...
        5,  0.2; ...
        6,  0.2; ...
        7,  0.2; ...
        8,  0.2; ...
        9,  0.2; ...
        10, 1.6; ...
        11, 2.8; ...
        12, 2.8; ...
        13, 2.8; ...
        14, 2.8; ...
        15, 3.4; ...
        16, 3.4; ...
        17, 4; ...
        18, 4; ...
        19, 4.6; ...
        20, 5.2; ...
        21, 5.6; ...
        22, 5.6; ...
        23, 6; ...
        24, 0; ...
        25, 0; ...
        26, 0; ...
        27, 0; ...
        28, 0; ...
        29, 0; ...
        30, 0; ...
        31, 0];
    
    h2dBMaxStepNo_AWGN_LDPC = 1.6;
end

properties % Переменные из параметров текущего объекта и их значения по
    % умолчанию - параметры, не связанные с расчётом кривых
    % помехоустойчивости
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Режим работы модели
        isBER = true;
    % Способ вычисления пик-фактора
    % 1 - с каждого Sig Symbol в статистику добавляются все значения
    %     отношения мгновенной мощности к средней
    % 2 - с каждого Sig Symbol в статистику добавляется одно значение, а
    %     именно - максимум отношения мгновенной мощности к средней
        PAPRType = 2;
    % Имя файла для сохранения результатов
    % Если в SaveFileName входит '%xd', то для создания фактического имени
    % будет использована функция sprintf('Results%02d', ParamsNumber), где
    % ParamsNumber - номер набора параметров
        SaveFileName = 'Results%02d';
    % Имя директории для сохранения результатов
    % Запрещённые имена: 'TestRegressionResults' и
    % 'ReferenceRegressionResults'. Проверка того, что эти имена не
    % используются выполняется в ReadSetup.
        SaveDirName = 'Results';
    % Количество кадров, генерируемых и обрабатываемых за одну итерацию.
    % При использовании Common.NumWorkers > 1 разумно, чтобы
    % NumOneIterFrames делилось на Common.NumWorkers без остатка.
        NumOneIterFrames = 100;
    % Количество ядер, используемых для параллельных вычислений        
        NumWorkers = 1;
end
properties % Переменные из параметров текущего объекта и их значения по
    % умолчанию - параметры, связанные с расчётом кривых помехоустойчивости

    % Количество учитываемых знаков после запятой при расчётах и выводе в
    % лог значений, связанных с h2
        h2Precision = 2;
    % Количество знаков после запятой для значения BER, указываемых в логе    
        BERPrecision = 8;
    % Количество символов, используемых для отображения числа переданных и
    % числа ошибочных бит в логе
        BERNumRateDigits = 10;
    % Количество символов, используемых для отображения числа переданных и
    % числа ошибочных кадров в логе
        FERNumRateDigits = 7;
        
    % ---------------------------------------------------------
    
    % Минимальное количество моделируемых для каждой точки кривой
    % помехоустойчивости кадров (это ограничение снизу необходимо для
    % корректного моделирования в условиях многолучёвости)
        MinNumTrFrames = 100;

    % ---------------------------------------------------------
    
    % Значение h2 (дБ) первой точки при расчёте помехоустойчивости
        h2dBInit = 0;
    % Начальное значение шага (дБ) для перехода к новым точкам при расчёте
    % помехоустойчивости
        h2dBInitStep = 0.2;
    % Максимальное значение шага (дБ) для перехода к новым точкам при
    % расчёте кривой помехоустойчивости
        h2dBMaxStep = 0.4;
    % Минимальное значение шага (дБ)
        h2dBMinStep = 0.1;
    % Максимальное значение рассматриваемого отношения сигнал/шум (если
    % кривая помехоустойчивости выйдет на насыщение со значением BER больше
    % требуемого, то это ограничение позволит прервать бесполезные
    % вычисления)
        h2dBMax = 30;

    % ---------------------------------------------------------
    
    % Требуемое минимальное значение BER, по достижении которого вычисления
    % будут остановлены (если, конечно, ограничение по сложности
    % (BER.MaxNumTrBits) или иное ограничение не наступит раньше)
        MinBER = 10^-3;
    % Минимальное количество ошибочных бит в каждой точке
        MinNumErBits = 5*10^2;
    % Требуемое минимальное значение FER, по достижении которого вычисления
    % будут остановлены
        MinFER = 1;
    % Минимальное количество ошибочных кадров в каждой точке
        MinNumErFrames = 10^2;

    % ---------------------------------------------------------
    
    % Максимальное количество переданных бит
        MaxNumTrBits = inf;
    % Максимальное количество переданных кадров
        MaxNumTrFrames = 10^4;

    % ---------------------------------------------------------
    
    % Максимальное отношение вероятностей битовых ошибок в соседних
    % точках, больше которого происходит уменьшение шага h2dB. Понятно, что
    % если идёт построение "нормальной" кривой помехоустойчивости, то
    % скорость спада значений вероятности ошибки тем больше, чем больше
    % значение h2 (дБ). При этом всегда важно отлавливать именно
    % изменения значения вероятности ошибки. Поэтому, если для
    % предыдущей пары отношение вероятностей ошибок было большое, то
    % для следующей пары оно будет ещё больше и, чтобы точнее
    % просчитать кривую помехоустойчивости (плюс, не уйти в ограничение по
    % сложности!), надо уменьшить шаг по оси h2 (дБ).
        MaxBERRate = 5;
    % Минимальное отношение вероятностей битовых ошибок в соседних
    % точках, меньше которого происходит увеличение шага h2dB. Возможна и
    % обратная ситуация, когда начало расчётов попадает на пологую
    % часть кривой помехоустойчивости. В такой ситуации можно смело
    % увеличивать шаг по оси h2 (дБ), не боясь потерять информацию об
    % изменении вероятности ошибки.
        MinBERRate = 2;
        
    % ---------------------------------------------------------
    % Нужно ли делать обновления лога command window для каждой новой
    % порции расчитанных NumOneIterFrames кадров
        isRealTimeLogCWin = 1;
    % Нужно ли делать обновления лога в файле для каждой новой
    % порции расчитанных NumOneIterFrames кадров
        isRealTimeLogFile = 0;
end

properties % Переменные из параметров текущего объекта и их значения по
    % умолчанию - параметры, связанные с расчётом комплементарной ЭФР
    
    % Количество символов, используемых для отображения числа рассмотренных
    % и подходящих отсчётов сигнала в логе
        NumSamplesDigits = 10;
    % Количество символов, используемых для отображения числа рассмотренных
    % кадров сигнала в логе
        NumFramesDigits = 6;
    % Количество символов, используемых для отображения числа
    % использованных бит в логе
        NumBitsDigits = 10;
    % Количество знаков после запятой для значения PAPR, указываемого в
    % логе
        PAPRPrecision = 2;
    % Количество знаков после запятой для значения вероятности,
    % указываемой в логе
        ProbPrecision = 6;
    
    % ---------------------------------------------------------
    
    % Рассматриваемые значения пик-фактора в дБ
        PAPRVals = 0:0.1:15;
    % Целевая вероятность
        MinPAPRProb = 10^-2;
    % Требуемое минимальное количество отсчётов сигнала в точке с целевой
    % вероятностью
        MinNumPAPRSamples = 1000;
        
    % ---------------------------------------------------------
    
    % Минимальное количество моделируемых кадров
        MinNumPAPRFrames = 100;
    % Максимальное количество использованных бит
        MaxNumPAPRBits = inf;
    % Максимальное количество сгенерированных кадров
        MaxNumPAPRFrames = inf;
    % Максимальное количество рассмотренных отсчётов сигнала
        MaxNumPAPRSamples = 10^10;
end

properties % Переменные из параметров или вычисляемых переменных других
    % объектов без значений по умолчанию
end
properties % Вычисляемые переменные - общие
    % Переменные, используемые снаружи
        isStop;
        OneWorkerNumOneIterFrames;
    % Лог, полные имена файлов для сохранения
        Log;
        FullSaveFileName;
        FullLogFileName;
end
properties % Вычисляемые переменные - связанные с расчётом кривых
    % помехоустойчивости 

    % Переменные, используемые снаружи
        h2dB;  
    % Внутренние переменные
        strh2Precision;
        strh2NumDigits;
        strBERPrecision;
        strBERNumRateDigits;
        strFERNumRateDigits;
    % Переменные, используемые для накопления статистики
        h2dBs;
        NumTrBits;
        NumTrFrames;
        NumErBits;
        NumErFrames;
    % Параметры, используемые для перехода между состояниями расчёта кривой
    % помехоустойчивости
        isMainCalcFinished;
        h2dBStep;
        Addh2dBs;
    % Переменная, получаемая объединением параметров isRealTimeLogCWin и
    % isRealTimeLogFile
        isRealTimeLog;
end
properties % Вычисляемые переменные - связанные с расчётом комплементарной
    % ЭФР
    
    % Внутренние переменные
        strNumSamplesDigits;
        strNumFramesDigits;
        strNumBitsDigits;
        strPAPRPrecision;
        strProbPrecision;
    % Переменные, используемые для накопления статистики
        NumCaptPAPRSamples;
        NumPAPRSamples;
        NumPAPRFrames;
        NumPAPRBits;
end
methods
    function obj = ClassBERRuler(Params, ParamsNum, NumParams)
    % Конструктор. Здесь инициализируются значения переменных из параметров
    % объекта. Для всех переменных из параметров, должны быть предусмотрены
    % значения по умолчанию, указанные в секции properties. Для всех
    % переменных из параметров нужно выполнить проверку наличия значения из
    % Setup, если в Setup есть значение, то оно заменяет значение по
    % умолчанию. Каждый параметр независимо от того получен он из Setup или
    % выставлен по умолчанию должен быть проверен на допустимость. Также в
    % конструкторе могут быть установлены значения некоторых/всех
    % вычисляемых переменных.

        % Инициализация значений переменных из параметров
            % Для сокращения записи выделим нужное поле/поля из Params
                if isfield(Params, 'Common')
                    Common = Params.Common;
                else
                    Common = [];
                end
                if isfield(Params, 'BER')
                    BER = Params.BER;
                else
                    BER = [];
                end
            % ---------------------------------------------------------    
                if isfield(BER, 'isBER')
                    obj.isBER = BER.isBER;
                end
                if isfield(BER, 'PAPRType')
                    obj.PAPRType = BER.PAPRType;
                end
                if isfield(Common, 'SaveFileName')
                    obj.SaveFileName = Common.SaveFileName;
                end
                if ~isempty(regexp(obj.SaveFileName, '%\d+d', 'once'))
                    obj.SaveFileName = sprintf(obj.SaveFileName, ...
                        ParamsNum);
                end
                if isfield(Common, 'SaveDirName')
                    obj.SaveDirName = Common.SaveDirName;
                end
                if isfield(Common, 'NumOneIterFrames')
                    obj.NumOneIterFrames = Common.NumOneIterFrames;
                end
                if isfield(Common, 'NumWorkers')
                    obj.NumWorkers = Common.NumWorkers;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'h2Precision')
                    obj.h2Precision = BER.h2Precision;
                end
                if isfield(BER, 'BERPrecision')
                    obj.BERPrecision = BER.BERPrecision;
                end
                if isfield(BER, 'BERNumRateDigits')
                    obj.BERNumRateDigits = BER.BERNumRateDigits;
                end
                if isfield(BER, 'FERNumRateDigits')
                    obj.FERNumRateDigits = BER.FERNumRateDigits;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinNumTrFrames')
                    obj.MinNumTrFrames = BER.MinNumTrFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'h2dBInit')
                    obj.h2dBInit = BER.h2dBInit;
                elseif isfield(Params, 'SchSource')
                if isfield(Params.SchSource, 'McsIndex')
                    if isfield(Params, 'NrSch')
						if isfield(Params.NrSch, 'isTransparent')
							if Params.NrSch.isTransparent
								obj.h2dBInit = obj.h2dB0_1BERperMCSnoLDPC(...
									Params.SchSource.McsIndex+1, 2);
							else
								obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
									Params.SchSource.McsIndex+1, 2);
							end
						else
							obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
								Params.SchSource.McsIndex+1, 2);
						end
					else
						obj.h2dBInit = obj.h2dB0_1BERperMCSwithLDPC(...
								Params.SchSource.McsIndex+1, 2);
                    end
					
                end
                end
                if isfield(BER, 'h2dBInitStep')
                    obj.h2dBInitStep = BER.h2dBInitStep;
                end
                if isfield(BER, 'h2dBMaxStep')
                    obj.h2dBMaxStep = BER.h2dBMaxStep;
                elseif isfield(Params, 'NrSch')
                if isfield(Params.NrSch, 'isTransparent')
				if  Params.NrSch.isTransparent
					obj.h2dBMaxStep = obj.h2dBMaxStepNo_AWGN_LDPC;
				end
                end
				elseif isfield(Params, 'NrChannel')
                if isfield(Params.NrChannel, 'Type')
				if  strcmp(Params.NrChannel.Type, 'Fading')
					obj.h2dBMaxStep = obj.h2dBMaxStepNo_AWGN_LDPC;
				end
                end
                end
                if isfield(BER, 'h2dBMinStep')
                    obj.h2dBMinStep = BER.h2dBMinStep;
                end
                if isfield(BER, 'h2dBMax')
                    obj.h2dBMax = BER.h2dBMax;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinBER')
                    obj.MinBER = BER.MinBER;
                end
                if isfield(BER, 'MinNumErBits')
                    obj.MinNumErBits = BER.MinNumErBits;
                end
                if isfield(BER, 'MinFER')
                    obj.MinFER = BER.MinFER;
                end
                if isfield(BER, 'MinNumErFrames')
                    obj.MinNumErFrames = BER.MinNumErFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MaxNumTrBits')
                    obj.MaxNumTrBits = BER.MaxNumTrBits;
                end
                if isfield(BER, 'MaxNumTrFrames')
                    obj.MaxNumTrFrames = BER.MaxNumTrFrames;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MaxBERRate')
                    obj.MaxBERRate = BER.MaxBERRate;
                end
                if isfield(BER, 'MinBERRate')
                    obj.MinBERRate = BER.MinBERRate;
                end
            % ---------------------------------------------------------
                if isfield(Common, 'isRealTimeLogCWin')
                    obj.isRealTimeLogCWin = Common.isRealTimeLogCWin;
                end
                if isfield(Common, 'isRealTimeLogFile')
                    obj.isRealTimeLogFile = Common.isRealTimeLogFile;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'NumSamplesDigits')
                    obj.NumSamplesDigits = BER.NumSamplesDigits;
                end
                if isfield(BER, 'NumFramesDigits')
                    obj.NumFramesDigits = BER.NumFramesDigits;
                end
                if isfield(BER, 'NumBitsDigits')
                    obj.NumBitsDigits = BER.NumBitsDigits;
                end
                if isfield(BER, 'PAPRPrecision')
                    obj.PAPRPrecision = BER.PAPRPrecision;
                end
                if isfield(BER, 'ProbPrecision')
                    obj.ProbPrecision = BER.ProbPrecision;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'PAPRVals')
                    obj.PAPRVals = BER.PAPRVals;
                end
                if isfield(BER, 'MinPAPRProb')
                    obj.MinPAPRProb = BER.MinPAPRProb;
                end
                if isfield(BER, 'MinNumPAPRSamples')
                    obj.MinNumPAPRSamples = BER.MinNumPAPRSamples;
                end
            % ---------------------------------------------------------
                if isfield(BER, 'MinNumPAPRFrames')
                    obj.MinNumPAPRFrames = BER.MinNumPAPRFrames;
                end
                if isfield(BER, 'MaxNumPAPRBits')
                    obj.MaxNumPAPRBits = BER.MaxNumPAPRBits;
                end
                if isfield(BER, 'MaxNumPAPRFrames')
                    obj.MaxNumPAPRFrames = BER.MaxNumPAPRFrames;
                end
                if isfield(BER, 'MaxNumPAPRSamples')
                    obj.MaxNumPAPRSamples = BER.MaxNumPAPRSamples;
                end

        % Определение значений вычисляемых переменных - общие
            % Инициализация параметров, используемых снаружи:
                obj.isStop = false;
                % Определение числа кадров, обрабатываемых за одну итерацию
                % для каждого worker
                    obj.OneWorkerNumOneIterFrames = zeros(1, ...
                        obj.NumWorkers) + round(obj.NumOneIterFrames ...
                        / obj.NumWorkers);
                    obj.OneWorkerNumOneIterFrames(end) = ...
                        obj.NumOneIterFrames - ...
                        sum(obj.OneWorkerNumOneIterFrames(1:end-1));

            % При необходимости создадим папку для сохранения результатов
                if ~isfolder(obj.SaveDirName)
                    mkdir(obj.SaveDirName);
                end

            % Имя файла для сохранения лога
                if isunix % Linux platform
                    % Code to run on Linux platform
                    PathDelimiter = '/';
                elseif ispc % Windows platform
                    % Code to run on Windows platform
                    PathDelimiter = '\';
                else
                    DeleteObjects();
                    error('Cannot recognize platform!');
                end            
                obj.FullLogFileName = [obj.SaveDirName, PathDelimiter, ...
                    obj.SaveFileName, '.log'];

            % Имя файла для сохранения результатов
                obj.FullSaveFileName = [obj.SaveDirName, PathDelimiter, ...
                    obj.SaveFileName, '.mat'];

            % isRealTimeLog
                obj.isRealTimeLog(1) = obj.isRealTimeLogCWin;
                obj.isRealTimeLog(2) = obj.isRealTimeLogFile;

            % Лог
            % На самом деле ведутся два лога, первый для вывода на экран,
            % второй - для сохранения в файл
                % Первая строка
                    LogStr1 = sprintf(['%s Start of calculation the ', ...
                        'curve %s (%d of %d).\n'], datestr(now), ...
                        obj.SaveFileName, ParamsNum, NumParams);
                % Вторая строка
                    LogStr2 = sprintf(['%s   Start of the main ', ...
                        'calculations.\n'], datestr(now));

                % Сохраним строки в лог
                    obj.Log = cell(2, 1); % заготовка под два лога
                    obj.Log{1} = {LogStr1; LogStr2};
                    obj.Log{2} = obj.Log{1}; % копируем первый лог во
                        % второй

                    for k = 1:2
                        if k == 1
                            obj.PrintLog(k, obj.isRealTimeLog(k));
                        else
                            obj.PrintLog(k, 1);
                        end
                        if obj.isRealTimeLog(k)
                            % Заготовка для следующей строки
                            obj.Log{k}{3} = '';
                        else
                            obj.Log{k} = cell(0);
                        end
                    end

        % Определение значений вычисляемых переменных - BER
            % Инициализация параметров, используемых снаружи: h2dB и isStop
                obj.h2dB   = obj.h2dBInit;

            % Определим строковые аналоги чисел, управляющих количеством
            % разрядов значений при выводе лога
                obj.strh2Precision = sprintf('%d', obj.h2Precision);
                if obj.h2Precision == 0
                    obj.strh2NumDigits = sprintf('%d', ...
                        obj.h2Precision + 2);
                else
                    obj.strh2NumDigits = sprintf('%d', ...
                        obj.h2Precision + 3);
                end
                obj.strBERPrecision     = sprintf('%d', obj.BERPrecision);
                obj.strBERNumRateDigits = sprintf('%d', ...
                    obj.BERNumRateDigits);
                obj.strFERNumRateDigits = sprintf('%d', ...
                    obj.FERNumRateDigits);

            % Округлим все значения h2
                obj.h2dBInit     = obj.Round(obj.h2dBInit);
                obj.h2dBInitStep = obj.Round(obj.h2dBInitStep);
                obj.h2dBMaxStep  = obj.Round(obj.h2dBMaxStep);
                obj.h2dBMinStep  = obj.Round(obj.h2dBMinStep);
                obj.h2dBMax      = obj.Round(obj.h2dBMax);

            % Инициализация параметров, используемых для накопления
            % статистики
                obj.h2dBs       = obj.h2dB;
                obj.NumTrBits   = 0;
                obj.NumTrFrames = 0;
                obj.NumErBits   = 0;
                obj.NumErFrames = 0;

            % Инициализация параметров, используемых для перехода между
            % состояниями расчёта кривой помехоустойчивости
                obj.isMainCalcFinished = false;
                obj.h2dBStep = obj.h2dBInitStep;
                obj.Addh2dBs = [];

        % Определение значений вычисляемых переменных - PAPR
            % Определим строковые аналоги чисел, управляющих количеством
            % разрядов значений при выводе лога
                obj.strNumSamplesDigits = sprintf('%d', ...
                    obj.NumSamplesDigits);
                obj.strNumFramesDigits  = sprintf('%d', ...
                    obj.NumFramesDigits);
                obj.strNumBitsDigits    = sprintf('%d', ...
                    obj.NumBitsDigits);
                obj.strPAPRPrecision    = sprintf('%d', ...
                    obj.PAPRPrecision);
                obj.strProbPrecision    = sprintf('%d', ...
                    obj.ProbPrecision);
                
            % Инициализация параметров, используемых для накопления
            % статистики
                obj.NumCaptPAPRSamples = zeros(size(obj.PAPRVals));
                obj.NumPAPRSamples = 0;
                obj.NumPAPRFrames  = 0;
                obj.NumPAPRBits    = 0;
    end
    function isPointFinished = Step(obj, Objs)
        if obj.isBER
            isPointFinished = StepBER(obj, Objs);
        else
            isPointFinished = true;
            StepPAPR(obj, Objs);
        end
    end
    function StepPAPR(obj, Objs)
        % Обновление статистики
            for k = 1:length(Objs)
                obj.NumCaptPAPRSamples = obj.NumCaptPAPRSamples + ...
                    Objs{k}.Stat.NumCaptPAPRSamples;
                obj.NumPAPRSamples = obj.NumPAPRSamples + ...
                    Objs{k}.Stat.NumPAPRSamples;
                obj.NumPAPRFrames = obj.NumPAPRFrames + ...
                    Objs{k}.Stat.NumPAPRFrames;
                obj.NumPAPRBits = obj.NumPAPRBits + ...
                    Objs{k}.Stat.NumPAPRBits;

                Objs{k}.Stat.Reset();
            end

        % Определим, превышена ли сложность расчёта
            isComplexityExceeded = false;
            if obj.NumPAPRBits > obj.MaxNumPAPRBits || ...
                    obj.NumPAPRFrames > obj.MaxNumPAPRFrames || ...
                    obj.NumPAPRSamples > obj.MaxNumPAPRSamples
                obj.isStop = true;
                isComplexityExceeded = true;
            end
            
        % Определим, набрана ли достаточная статистика
            PAPRProbs = obj.NumCaptPAPRSamples ./ obj.NumPAPRSamples;
            isFinished = false;
            if obj.NumPAPRFrames > obj.MinNumPAPRFrames
                Poses1 = PAPRProbs <= obj.MinPAPRProb;
                Poses2 = obj.NumCaptPAPRSamples >= obj.MinNumPAPRSamples;
                if sum(Poses1 & Poses2) > 0
                    obj.isStop = true;
                    isFinished = true;
                end
            end
            
            if isComplexityExceeded
                isFinished = true;
            end
            
        % Лог
            % Определим текущую точку, в которой набрана достаточная
            % статистика и при этом у неё минимальное значение PAPR
                Poses = obj.NumCaptPAPRSamples >= obj.MinNumPAPRSamples;
                if sum(Poses) > 0
                    BufPAPRProbs = PAPRProbs(Poses);
                    BufPAPRVals = obj.PAPRVals(Poses);
                    BufNumCaptPAPRSamples = obj.NumCaptPAPRSamples(Poses);
                    
                    [BufPAPRProbs, Pos] = min(BufPAPRProbs);
                    BufPAPRVals = BufPAPRVals(Pos(1));
                    BufNumCaptPAPRSamples = BufNumCaptPAPRSamples(Pos(1));
                else
                    BufPAPRProbs = 0;
                    BufPAPRVals = 0;
                    BufNumCaptPAPRSamples = 0;
                end
        
            % Новая строка
                LogStr = sprintf(['%s     NumSam = %', ...
                    obj.strNumSamplesDigits, 'd; NumFr = %', ...
                    obj.strNumFramesDigits, 'd; NumBits = %', ...
                    obj.strNumBitsDigits, 'd; PAPR = %0.', ...
                    obj.strPAPRPrecision, 'f; Prob = %0.', ...
                    obj.strProbPrecision, 'f = %', ...
                    obj.strNumSamplesDigits, 'd/%' , ...
                    obj.strNumSamplesDigits, 'd.'], datestr(now), ...
                    obj.NumPAPRSamples, obj.NumPAPRFrames, ...
                    obj.NumPAPRBits, BufPAPRVals, BufPAPRProbs, ...
                    BufNumCaptPAPRSamples, obj.NumPAPRSamples ...
                );

                if isFinished
                    SubS = ' Completed';
                    if isComplexityExceeded
                        SubS = [SubS, ' (complexity exceeded)'];
                    end
                    LogStr = [LogStr, SubS, '.'];
                end
                
                LogStr = sprintf('%s\n', LogStr);

            % Добавим новую строку к логу
                for k = 1:2
                    obj.Log{k} = cell(0);
                    obj.Log{k}{1} = LogStr;
                end

        % Вывод лога на экран и сохранение лога в файл
            for k = 1:2
                obj.PrintLog(k, false);
            end
    end
    function isPointFinished = StepBER(obj, Objs)
        % Обновление статистики
            for k = 1:length(Objs)
                obj.NumTrBits(end)   = obj.NumTrBits(end)   + ...
                    Objs{k}.Stat.NumTrBits;
                obj.NumTrFrames(end) = obj.NumTrFrames(end) + ...
                    Objs{k}.Stat.NumTrFrames;

                obj.NumErBits(end)   = obj.NumErBits(end)   + ...
                    Objs{k}.Stat.NumErBits;
                obj.NumErFrames(end) = obj.NumErFrames(end) + ...
                    Objs{k}.Stat.NumErFrames;

                Objs{k}.Stat.Reset();
            end

        % Определим, превышена ли сложность расчёта одной точки
            isComplexityExceeded = false;
            if (obj.NumTrBits(end) > obj.MaxNumTrBits) || ...
                    (obj.NumTrFrames(end) > obj.MaxNumTrFrames)
                isComplexityExceeded = true;
            end

        % Определим закончен ли расчёт для текущей точки - либо
        % достигнуты минимальные показатели, либо превышена сложность
        % расчёта
            isPointFinished = false;
            if ((obj.NumErBits(end) >= obj.MinNumErBits) && ...
                    (obj.NumErFrames(end) >= obj.MinNumErFrames) && ...
                    (obj.NumTrFrames(end) >= obj.MinNumTrFrames)) || ...
                    isComplexityExceeded
                isPointFinished = true;
            end

        % Лог
            % Новая строка
                LogStr = sprintf(['%s     h2 = %', ...
                    obj.strh2NumDigits, '.', obj.strh2Precision, ...
                    'f dB; h2Step = %', obj.strh2NumDigits, '.', ...
                    obj.strh2Precision, 'f dB; BER = %0.', ...
                    obj.strBERPrecision, 'f = %', ...
                    obj.strBERNumRateDigits, 'd/%', ...
                    obj.strBERNumRateDigits, 'd; FER = %', ...
                    obj.strFERNumRateDigits, 'd/%', ...
                    obj.strFERNumRateDigits, 'd\n'], datestr(now), ...
                    obj.h2dB, obj.h2dBStep, obj.NumErBits(end) / ...
                    obj.NumTrBits(end), obj.NumErBits(end), ...
                    obj.NumTrBits(end), obj.NumErFrames(end), ...
                    obj.NumTrFrames(end));

                if isPointFinished
                    SubS = ' Completed';
                    if isComplexityExceeded
                        SubS = [SubS, ' (complexity exceeded)'];
                    end
                    LogStr = [LogStr(1:end-1), SubS, LogStr(end)];
                end

            % Добавим новую строку к логу
                for k = 1:2
                    if obj.isRealTimeLog(k)
                        obj.Log{k}{end} = LogStr;
                    else
                        if isPointFinished
                            obj.Log{k} = {LogStr};
                        end
                    end
                end

        % Если мы находимся в основном расчёте, то по значениям BER,
        % FER и isComplexityExceeded проверим, не завершился ли он
            isMainCalcJustFinished = false; % для нужд лога
            if isPointFinished && ~obj.isMainCalcFinished
                BER = obj.NumErBits   ./ obj.NumTrBits;
                FER = obj.NumErFrames ./ obj.NumTrFrames;

                if ((BER(end) <= obj.MinBER) && ...
                    (FER(end) <= obj.MinFER)) || ...
                    isComplexityExceeded
                    obj.isMainCalcFinished = true;
                    obj.h2dBStep = nan; % Формально
                    isMainCalcJustFinished = true; % для нужд лога
                end

                if length(BER) > 1
                    BERRate = BER(1:end-1) ./ BER(2:end);
                else
                    BERRate = 0.5*(obj.MinBERRate + obj.MaxBERRate);
                end
            end

        % Переход к новой точке для случая основного расчёта точек
            if isPointFinished && ~obj.isMainCalcFinished
                % Обновим значение h2dBStep
                    if BERRate(end) > obj.MaxBERRate
                        % Вариант 1: стандартный
                            % Buf = obj.Round(0.5*obj.h2dBStep);
                            % obj.h2dBStep = max(Buf, obj.h2dBMinStep);
                        % Вариант 2: лучше работает в случае
                        % эффективных помехоустойчивых кодов
                            RRate = BERRate(end) / obj.MaxBERRate;
                            if                      (RRate <  4)
                                DecFact = 1/2;
                            elseif (RRate >=  4) && (RRate < 16)
                                DecFact = 1/4;
                            elseif (RRate >= 16) && (RRate < 64)
                                DecFact = 1/8;
                            elseif (RRate >= 64)
                                DecFact = 1/16;
                            end
                            Buf = obj.Round(DecFact*obj.h2dBStep);
                            obj.h2dBStep = max(Buf, obj.h2dBMinStep);
                    elseif BERRate(end) < obj.MinBERRate
                        Buf = obj.Round(2*obj.h2dBStep);
                        obj.h2dBStep = min(Buf, obj.h2dBMaxStep);
                    end
                % обновим значение h2dB
                    obj.h2dB = obj.h2dB + obj.h2dBStep;
                % Проверим не превышено ли значение h2dBMax
                    if obj.h2dB > obj.h2dBMax
                        obj.isMainCalcFinished = true;
                        isMainCalcJustFinished = true; % для нужд лога
                    end
                % Проверим, не получилось ли из-за округлений
                % obj.h2dBStep = 0
                    if obj.h2dBStep < eps
                        obj.isMainCalcFinished = true;
                        isMainCalcJustFinished = true; % для нужд лога
                    end
            end

        % Лог
            if isMainCalcJustFinished
                LogStr = '   The main calculations are completed.';
                if obj.h2dB > obj.h2dBMax
                    LogStr = [LogStr, ' (Maximum SNR is exceeded)'];
                end
                if obj.h2dBStep < eps
                    LogStr = [LogStr, ' (Zero h2 step obtained)'];
                end
                LogStr = sprintf('%s%s\n', datestr(now), LogStr);
                for k = 1:2
                    obj.Log{k}{end+1} = LogStr;
                end
            end

        % Если мы находимся в расчёте дополнительных точек и расчёт
        % очередной точки завершился из-за превышения сложности, то
        % нужно отбросить все точки с большими значениями h2
            if isPointFinished && obj.isMainCalcFinished && ...
                    isComplexityExceeded && ~isMainCalcJustFinished
                % Выкенем результаты с большими значениями h2
                    Poses = (obj.h2dBs <= obj.h2dB);
                    obj.h2dBs       = obj.h2dBs      (Poses);
                    obj.NumTrBits   = obj.NumTrBits  (Poses);
                    obj.NumTrFrames = obj.NumTrFrames(Poses);
                    obj.NumErBits   = obj.NumErBits  (Poses);
                    obj.NumErFrames = obj.NumErFrames(Poses);
                    NumDeleted1 = length(Poses) - sum(Poses);
                % Выкенем из рассмотрения лишние Addh2dBs
                    Poses = (obj.Addh2dBs <= obj.h2dB);
                    obj.Addh2dBs = obj.Addh2dBs(Poses);
                    NumDeleted2 = length(Poses) - sum(Poses);
                % Лог
                    LogStr = sprintf(['%s     %d results are deleted ', ...
                        'from main calculations and %d values of h2 ', ...
                        'are deleted from the set for additional ', ...
                        'calculations .\n'], datestr(now), NumDeleted1, ...
                        NumDeleted2);
                    for k = 1:2
                        obj.Log{k}{end+1} = LogStr;
                    end
            end

        % Переход к новой точке для случая расчёта дополнительных точек
            if isPointFinished && obj.isMainCalcFinished
                % Определим требуемые для расчёта дополнительные
                % значения h2dB или будем использовать расчитанные
                % ранее
                    if isempty(obj.Addh2dBs)
                        % Сортировка результата по возрастанию h2dBs
                            [obj.h2dBs, I]  = sort(obj.h2dBs);
                            obj.NumTrBits   = obj.NumTrBits  (I);
                            obj.NumTrFrames = obj.NumTrFrames(I);
                            obj.NumErBits   = obj.NumErBits  (I);
                            obj.NumErFrames = obj.NumErFrames(I);
                        % Вычисление BER и BERRate
                            BER = obj.NumErBits ./ obj.NumTrBits;
                            if length(BER) > 1
                                BERRate = BER(1:end-1) ./ BER(2:end);
                            else
                                BERRate = 0.5*(obj.MinBERRate + ...
                                    obj.MaxBERRate);
                            end
                        % Найдём места, где надо расчитать
                        % дополнительные точки
                            Poses = find(BERRate > obj.MaxBERRate);
                            obj.Addh2dBs = (obj.h2dBs(Poses+1) + ...
                                obj.h2dBs(Poses)) / 2;
                            obj.Addh2dBs = obj.Round(obj.Addh2dBs);
                        % Отбросим те случаи, где получилось
                        % слишком маленькое значение шага по оси h2
                            % Вариант 1 расчёта значений шага
                                % h2dBSteps = (obj.h2dBs(Poses+1) - ...
                                %     obj.h2dBs(Poses)) / 2;
                            % Вариант 2 расчёта значений шага
                                h2dBSteps = min([obj.Addh2dBs - ...
                                    obj.h2dBs(Poses); ...
                                    obj.h2dBs(Poses+1) - ...
                                    obj.Addh2dBs]);
                                % Вариант 2 - более стабильный из-за
                                % округления obj.Addh2dBs
                            Poses = (h2dBSteps + 1000*eps >= ...
                                obj.h2dBMinStep);
                                % + 1000*eps для более стабильной
                                % работы в случае, если h2dBSteps равно
                                % obj.h2dBMinStep
                            obj.Addh2dBs = obj.Addh2dBs(Poses);
                        % Разберёмся с логом
                            if ~isempty(obj.Addh2dBs)
                                LogStr = sprintf([' %0.', ...
                                    obj.strh2Precision, 'f'], ...
                                    obj.Addh2dBs);
                                LogStr = sprintf(['%s   Start of the ', ...
                                    'additional calculations [%s].\n'], ...
                                    datestr(now), LogStr(2:end));
                                for k = 1:2
                                    obj.Log{k}{end+1} = LogStr;
                                end
                            end
                    end

                % Переходим к очередному значению Addh2dBs
                    if isempty(obj.Addh2dBs)
                        obj.isStop = true;

                        % Лог
                            if ~isMainCalcJustFinished
                                LogStr = sprintf(['%s   The ', ...
                                    'additional calculations are ', ...
                                    'completed.\n'], datestr(now));
                                for k = 1:2
                                    obj.Log{k}{end+1} = LogStr;
                                end
                            end
                            LogStr = sprintf(['%s Calculations are ', ...
                                'completed.\n'], datestr(now));
                            for k = 1:2
                                obj.Log{k}{end+1} = LogStr;
                                obj.Log{k}{end+1} = newline;
                            end
                    else
                        obj.h2dB = obj.Addh2dBs(1);
                        obj.Addh2dBs = obj.Addh2dBs(2:end);
                    end
            end

        % Подготовка к расчёту новой точки - добавление нового элемента
        % в массивы и сброс генераторов случайных чисел в начальное
        % состояние
            if isPointFinished && ~obj.isStop
                obj.h2dBs       = [obj.h2dBs, obj.h2dB];
                obj.NumTrBits   = [obj.NumTrBits,   0];
                obj.NumTrFrames = [obj.NumTrFrames, 0];
                obj.NumErBits   = [obj.NumErBits,   0];
                obj.NumErFrames = [obj.NumErFrames, 0];
                obj.ResetRandStreams();
            end

        % Вывод лога на экран и сохранение лога в файл
            for k = 1:2
                obj.PrintLog(k, obj.isRealTimeLog(k));
                if obj.isRealTimeLog(k)
                    if isPointFinished && ~obj.isStop
                        obj.Log{k}{end+1} = '';
                    end
                else
                    obj.Log{k} = cell(0);
                end
            end
    end
    function Saves(obj, Objs, Params)
        % Можно просто сохранять все объекты и параметры:
        % save(obj.FullSaveFileName, 'Objs', 'obj', 'Params');
        % Однако в этом случае нужно будет обеспечивать наличие
        % описаний классов при загрузке конструкторов в поле видимости
        % MATLAB. Удобнее идти по другому пути - сохранять кривые
        % помехоустойчивости и все параметры. Более того, если в
        % параметрах оказываются какие-нибудь очень большие массивы или
        % структуры, то их лучше предварительно удалять.
            
            % Сохраним в Params все параметры BER. Это потребуется, чтобы
            % во время прорисовки отбрасывать часть кривых с недостаточной
            % статистикой
                Names = properties(obj);
                for k = 1:length(Names)
                    Params.BER.(Names{k}) = obj.(Names{k});
                end
        
            Res.isBER       = obj.isBER;
            
            Res.h2dBs       = obj.h2dBs;
            Res.NumErBits   = obj.NumErBits;
            Res.NumTrBits   = obj.NumTrBits;
            Res.NumErFrames = obj.NumErFrames;
            Res.NumTrFrames = obj.NumTrFrames;
            
            Res.PAPRVals           = obj.PAPRVals;
            Res.NumCaptPAPRSamples = obj.NumCaptPAPRSamples;
            Res.NumPAPRSamples     = obj.NumPAPRSamples;
            
            AlphaFreq = 1;
            if strcmp(Objs{1}.Sig.Type, 'SEFDM')
                if strcmp(Objs{1}.SEFDM.FormType, 'Insert') || ...
                        strcmp(Objs{1}.SEFDM.FormType, 'Oscill')
                    AlphaFreq = Objs{1}.SEFDM.AlphaFreq;
                end
            end
            AlphaTime = 1;
            if strcmp(Objs{1}.Sig.Type, 'SEFDM')
                if strcmp(Objs{1}.SEFDM.FormType, 'Trunc')
                    AlphaTime = Objs{1}.SEFDM.AlphaTime;
                end
            end
            CodeRate = 1;
            if ~Objs{1}.NrSch.isTransparent
                CodeRate = Objs{1}.NrSch.PdschCodeRate;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    L = Objs{1}.NrOFDM.L;
                case 'SEFDM'
                    L = Objs{1}.SEFDM.L;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    N = Objs{1}.NrOFDM.NFFT;
                case 'SEFDM'
                    N = Objs{1}.SEFDM.NFFT;
            end
            switch Objs{1}.Sig.Type
                case {'OFDM', 'OTFS'}
                    Ncps = Objs{1}.NrOFDM.CPLengths;
                case 'SEFDM'
                    Ncps = Objs{1}.SEFDM.CPLengths;
            end
            Res.SpectralEfficiency = CodeRate * ...
                Objs{1}.SchSource.PdschModNumBits / AlphaFreq * ...
                L * N / (L * N * AlphaTime + sum(Ncps));
            
            save(obj.FullSaveFileName, 'Res', 'Params');
    end
    function StartParallel(obj)
    %
    % Переход в режим параллельных вычислений (при необходимости)

        % Определим параметры запущенного pool, если он есть
            P = gcp('nocreate');

        % Если pool есть, то он должен быть подключенным и количество
        % worker должно совпадать с требуемым. Если pool отсутствует,
        % то количество требуемых worker должно быть равно 1.
            % Флаг соответствия запущенного pool нужным параметрам
                isOk = false;
            if ~isempty(P)
                if P.Connected
                    if isequal(P.NumWorkers, obj.NumWorkers)
                        isOk = true;
                    end
                end
            else
                if isequal(obj.NumWorkers, 1)
                    isOk = true;
                end
            end

        % Если имеющийся pool не соответствует заданным параметрам или
        % его нет, то нужно его создать
            if ~isOk
                % Удалим pool, если он есть
                    if ~isempty(P)
                        delete(P);
                    end

                if obj.NumWorkers > 1
                    % Попытаемся создать pool
                        P = parpool(obj.NumWorkers);

                    % Проверим, что удалось создать правильный pool
                        isOk = false;
                        if P.Connected
                            if isequal(P.NumWorkers, obj.NumWorkers)
                                isOk = true;
                            end
                        end

                    % Если не удалось, выводим ошибку
                        if ~isOk
                            DeleteObjects();
                            error(['Failed to start the pool with ', ...
                                'the specified parameters']);
                        end
                end
            end

    end
    function StopParallel(obj) %#ok<MANU>
    % Выход из параллельных вычислений (при необходимости)

        % Определим параметры запущенного pool, если он есть
            P = gcp('nocreate');

        % Если имеется pool, то его нужно удалить
            if ~isempty(P)
                delete(P);
            end
    end
    function ResetRandStreams(obj)
    % Функция сброса генераторов случайных чисел в начальное состояние
        if obj.NumWorkers > 1
            spmd
                Stream = RandStream.getGlobalStream;
                reset(Stream);
            end
        else
            Stream = RandStream.getGlobalStream;
            reset(Stream);
        end
    end
    function PrintLog(obj, LogNum, isClear)
    % Вывод на экран/запись в файл лога номер LogNum, где LogNum = 1
    % соответствует экрану, а LogNum = 2 - файлу. isClear - флаг
    % необходимости очистки экрана/файла.
        if isempty(obj.Log{LogNum})
            return
        end

        if LogNum == 1 % Вывод лога на экран
            if isClear
                clc;
            end

            for k = 1:length(obj.Log{1})
                fprintf('%s', obj.Log{1}{k});
            end
        elseif LogNum == 2 % Сохранение лога в файл
            if isClear
                fileID = fopen(obj.FullLogFileName, 'w');
            else
                fileID = fopen(obj.FullLogFileName, 'a');
            end

            if fileID < 0
                DeleteObjects();
                error('Failed to open file to save log!');
            end

            for k = 1:length(obj.Log{2})
                fprintf(fileID, '%s\r\n', obj.Log{2}{k}(1:end-1));
            end

            fclose(fileID);
        end
    end
    function Out = Round(obj, In)
    % Функция округления числа до заданного числа десятичных знаков
    % после запятой
        Out = round(10^obj.h2Precision*In) / 10^obj.h2Precision;
    end
end
end
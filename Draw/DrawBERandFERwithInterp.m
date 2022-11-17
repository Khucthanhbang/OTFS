function [FilesNames, LegendNames, Interph2dBs, InterpMsgs] = ...
    DrawBERandFERwithInterp(Input1, ProbVals, isDraw)
%
% Скрипт прорисовки кривых вероятности битовой и кадровой ошибок.
% Также скрипт позволяет определять значение отношения сигнал/шум, при
% котором достигается заданная вероятность ошибки.
%
% Входные переменные:
%   Input1 - необязательная переменная, управляющая выбором
%       файлов-результатов:
%       ) если Input1 = '' или [] или отсутствует (т.е. нет входных
%           переменных), то определяется, есть ли папка Results и, если она
%           есть, то выполняется прорисовка всех содержащихся в ней
%           файлов-результатов;
%       ) если Input1 = '_dir' открывается меню выбора папки, из которой
%           необходимо выполнить прорисовку всех содержащихся в ней
%           файлов-результатов;
%       ) если Input1 = '_files' открывается меню выбора файлов-
%           результатов, для которых необходимо выполнить прорисовку;
%       ) если Input1 - имя папки, то выполняется прорисовка всех
%           содержащихся в ней файлов-результатов
%       ) если Input1 - cell-массив имён файлов-результатов, то выполняется
%           их прорисовка.
%   ProbVals - необязательная переменная, массив из двух значений
%       вероятностей BER и FER, для которых нужно определить значение
%       h2db путём линейной интерполяции в осях (10*lg(h2), lg(Pr)). Если
%       этой переменной нет или она равна [], то интерполяция не делается.
%   isDraw - необязательная переменная, флаг, указывающий, нужно ли делать
%       прорисовку рисунков (удобно использовать, когда необходимо только
%       получить данные Interph2dBs и InterpMsgs). По умолчанию isDraw = 1.
%
% Выходные переменные:
%   FilesNames - cell-массив с полными именами файлов-результатов.
%   LegendNames - cell-массив с краткими (без пути) именами файлов-
%       результатов без расширения.
%   Interph2dBs - необязательная переменная, массив (2 х NumFiles) со
%       значениями h2db, полученными в результате интерполяции.
%   InterpMsgs - необязательная переменная, cell-массив (2 х NumFiles) с
%       сообщениями об ошибках интерполяции.

% Инициализация выходных переменных на случай раннего прекращения функции
    FilesNames  = cell(0);
    LegendNames = cell(0);
    Interph2dBs = zeros(3, 0);
    InterpMsgs  = cell(3, 0);

% Парсинг входных переменных, подготовка к работе функции    
    % Прежде всего, разберёмся, какой у нас вариант запуска функции
    % относительно первой переменной
        % Определим, является ли это вызовом без установки значения Input1
            isZeroAsumpt = 0;
            if nargin == 0
                isZeroAsumpt = 1;
            else
                if isempty(Input1)
                    isZeroAsumpt = 1;
                end
                if isstring(Input1)
                    if strcmp(Input1, '')
                        isZeroAsumpt = 1;
                    end
                end
            end

        % Если да, то подготовимся к этому варианту
            if isZeroAsumpt
                DirName = 'Results';
                if ~isfolder(DirName)
                    error('Отсутствует директория Results!')
                end
                isChoseDir = 0;
                isFindFilesInDir = 1;
                isChoseFiles = 0;
            end

        % Если нет, то рассмотрим другие варианты и приготовимся к ним
            if ~isZeroAsumpt % nargin > 0
                if iscell(Input1)
                    if sum(isfile(Input1)) ~= numel(Input1)
                        error(['Не все элементы cell-массива Input1 ', ...
                            'являются именами файлов!'])
                    end
                    isChoseDir = 0;
                    DirName = '';
                    isFindFilesInDir = 0;
                    isChoseFiles = 0;
                    FilesNames = Input1(:);
                elseif ischar(Input1)
                    if isfolder(Input1)
                        isChoseDir = 0;
                        DirName = Input1;
                        isFindFilesInDir = 1;
                        isChoseFiles = 0;
                    elseif isfile(Input1)
                        isChoseDir = 0;
                        [DirName, ~, ~] = fileparts(Input1);
                        isFindFilesInDir = 0;
                        isChoseFiles = 0;
                        FilesNames = {Input1(length(DirName)+2:end)};
                    elseif strcmp(Input1, '_dir')
                        isChoseDir = 1;
                        isFindFilesInDir = 1;
                        isChoseFiles = 0;
                    elseif strcmp(Input1, '_files')
                        isChoseDir = 0;
                        isFindFilesInDir = 0;
                        isChoseFiles = 1;
                    else
                        error('Не удалось распознать требуемое действие!')
                    end
                else
                    error('Не удалось распознать требуемое действие!')
                end
            end

    % Теперь выясним, нужно ли будет вычислять значения h2dB, при которых
    % достигается заданная вероятность
        isNeedInterp = 0;
        if nargin > 1
            if ~isempty(ProbVals)
                isNeedInterp = 1;
            end
        end
        
    % Определим значение переменной isDraw
        if nargin < 3
            isDraw = 1;
        end

% Определение FilesNames и LegendNames
    % При необходимости вызовем диалог выбора директории с результатами
        if isChoseDir
            DirName = uigetdir();
            if isempty(DirName)
                return
            end
        end

    % При необходимости в директории DirName найдём все *.mat файлы
        if isFindFilesInDir
            % Получим информацию о содержимом директории
                Listing = dir(DirName);

            % Инициализируем cell-массив для хранения имён файлов
                FilesNames = cell(0);

            % Цикл по всем файлам директории
                for k = 1:length(Listing)
                % Надо проверять, чтобы рассматриваемый элемент был
                % файлом и имел расширение mat
                    if ~Listing(k).isdir
                        FName = Listing(k).name;
                        if length(FName) > 4
                            if isequal(FName(end-3:end), '.mat')
                            % Добавим имя файла к списку
                                FilesNames{end+1} = FName; %#ok<AGROW>
                            end
                        end
                    end
                end

            % Если файлы не найдены
                if isempty(FilesNames)
                    error(['В директории %s не найдены файлы с ', ...
                        'результатами!'], DirName);
                end
        end

    % При необходимости вызовем диалог выбора файлов с результатами
        if isChoseFiles
            [FilesNames, DirName] = uigetfile('*.mat', ...
                'Select a File or Files', 'MultiSelect', 'on');
            if isequal(FilesNames, 0)
                return
            end
            if ~iscell(FilesNames)
                FilesNames = {FilesNames};
            end
        end

    % Проверим, чтобы в получившемся списке файлов были только *.mat файлы
    % Фактически, проблемы могут возникнуть только при выборе файлов через
    % isChoseFiles (если пользователь сбил фильтр) или при явном указании
    % файла(ов).
        if ~isFindFilesInDir
            Buf = FilesNames;
            FilesNames = cell(0);
            for k = 1:length(Buf)
                isOk = 0;
                if length(Buf{k}) > 4
                    if strcmp(Buf{k}(end-3:end), '.mat')
                        isOk = 1;
                    end
                end
                if isOk
                    FilesNames{end+1} = Buf{k}; %#ok<AGROW>
                end
            end

            if isempty(FilesNames)
                error('Среди выбранных файлов нет ни одного *.mat файла!');
            end
        end
        
    % Сформируем полные имена файлов и подписи для легенды, состоящие
    % только из имени файла без пути и расширения
        LegendNames = cell(size(FilesNames));
        for k = 1:length(FilesNames)
            LegendNames{k} = FilesNames{k}(1:end-4);
            FilesNames{k} = fullfile(DirName, FilesNames{k});
        end
        NumFiles = length(FilesNames);
        
% Прорисовка BER и FER и интерполяция при необходимости
    % Создадим полотна и оси
        if isDraw
            f  = cell(2, 1);
            ax = cell(2, 1);
            for k = 1:2
                f{k} = figure;
                    ax{k} = axes;
            end
        end

    % Определим имена рисунков
        CurvesNames = {'BER', 'FER'};
        
    % Подготовим переменные с результатами интерполяции
        if isNeedInterp
            Interph2dBs = zeros(2, NumFiles);
            InterpMsgs = cell(2, NumFiles);
        end
            
    % Цикл по всем уже известным файлам
        % Переменная для хранения кривых BER, FER
            Probs = cell(1, 2);
        for k = 1:NumFiles
            % Загрузка результатов
                load(FilesNames{k}, 'Res', 'Params');

            % Определим позиции, где достигнута заданная точность
                Poses = (Res.NumErBits >= ...
                    Params.BER.MinNumErBits) & (Res.NumErFrames ...
                    >= Params.BER.MinNumErFrames);

            % Определим вероятности ошибок
                Probs{1} = Res.NumErBits(Poses) ./ Res.NumTrBits(Poses);
                Probs{2} = Res.NumErFrames(Poses) ./ ...
                    Res.NumTrFrames(Poses);

            % Выделим значения ОСШ
                h2dBs = Res.h2dBs(Poses);

            % Прорисовка без затирания старых рисунков
                if isDraw
                    for n = 1:2
                        figure(f{n});
                        hold on;
                        plot(h2dBs, Probs{n}, 'LineWidth', 1, 'Marker', ...
                            '.', 'MarkerSize', 8);
                    end
                end

            % При необходимости определим значения h2dB, при которых
            % достигается заданная вероятность
                if isNeedInterp
                    for n = 1:2
                        [Interph2dBs(n, k), InterpMsgs{n, k}] = ...
                            BERLinInterp(ProbVals(n), h2dBs, ...
                            Probs{n});
                        if ~isempty(InterpMsgs{n, k})
                            fprintf('Результаты %s, расчёт %s:\n', ...
                                LegendNames{k}, CurvesNames{n});
                            disp(InterpMsgs{n, k});
                        end
                    end
                end
        end

    % Добавка сетки, подписей, легенды и референсных кривых
        if isDraw
            for k = 1:2
                figure(f{k});

                % Добавим сетку
                    grid on;

                % Сделаем традиционный масштаб по оси ординат
                    set(ax{k}, 'YScale', 'log');

                % Подпишем рисунок и ось абсцисс
                    title(CurvesNames{k});
                    xlabel('{\ith}^2 (dB)');

                % Прорисовка стандартных BER для QAM4 и QAM16 до
                % вероятности 1e-6
                    BufNames = LegendNames;
%                     if k == 1
%                         h2dB = 0:0.1:10.5;
%                         BER = berawgn(h2dB, 'qam', 4);
%                         plot(h2dB, BER);
% 
%                         h2dB = 0:0.1:14.4;
%                         BER = berawgn(h2dB, 'qam', 16);
%                         plot(h2dB, BER);
% 
%                         h2dB = 0:0.1:18.8;
%                         BER = berawgn(h2dB, 'qam', 64);
%                         plot(h2dB, BER);
%                         
%                         BufNames{end+1} = 'QPSK'; %#ok<AGROW>
%                         BufNames{end+1} = '16PSK'; %#ok<AGROW>
%                         BufNames{end+1} = '64QAM'; %#ok<AGROW>
%                     end
% 
                % Добавим легенду
                    legend(BufNames, 'Interpreter', 'none', ...
                        'AutoUpdate', 'off');
            end
        end

    % Прорисовка точек интерполяции
        if isDraw
            if isNeedInterp
                for k = 1:NumFiles
                    for n = 1:2
                        if isempty(InterpMsgs{n, k})
                            figure(f{n});
                            plot(Interph2dBs(n, k), ProbVals(n), ...
                                'LineWidth', 1, 'Marker', '.', ...
                                'MarkerSize', 15, 'Color', 'r');
                        end
                    end
                end
            end
        end

    % Вставка фигур в одно общее окно
        if isDraw
            for k = 1:2
                set(f{k}, 'WindowStyle', 'Docked');
            end
        end
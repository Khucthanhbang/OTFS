function Params = ReadSetup(NamePrefix)
%
% Функция выполняет поиск файлов, имя которых начинается с NamePrefix и
% имеет расширение 'm'. Файл должен содержать инициализацию параметров (без
% части 'Params.'). Файлы Setup должны быть написаны и будут обрабатываться
% по правилам m-языка. Разделителем разных наборов параметров является
% '% End of Params' (следовательно, например, всё, что написано в строке
% после '% End of Params' учитываться не будет, так как это комментарии).
% Конец файла по определению считается окончанием определения набора
% параметров, поэтому ставить '% End of Params' в конце файла не
% обязательно. Пустые наборы параметров отбрасываются. Параметры в разных
% файлах по определению считаются принадлежащими разным наборам. Если все
% файлы будут пустыми или файлов не будет вовсе, то будет выполнен один
% расчёт с пустым набором параметров, т.е. с параметрами по умолчанию.
% Подсказка: если требуется получить пустой набор параметров при условии,
% что в Setup есть не пустые наборы, то нужно сделать набор параметров, в
% котором указать одно из значений по умолчанию. Если NamePrefix ==
% RegressionSetup, то во все наборы параметров принудительно будет
% прописана добавка: Common.SaveDirName = 'TestRegressionResults', в
% противном случае во всех наборах параметров будет выполнена проверка
% того, что Common.SaveDirName не равна 'TestRegressionResults' и не равна
% 'ReferenceRegressionResults' (выбор регситра не важен), так как эти имена
% зарегистрированы для нужд регрессии.
%
% Выходные параметры:
%   Params - cell-массив с частичными наборами параметров, установленных
%       согласно файлу(ам) Setup.

    % Инициализация результата
        Params = cell(0);

    % Учитываемые имена полей структуры Params верхнего уровня
        global FieldNames
        SFieldNames = FieldNames;
        SFieldNames{end+1} = 'BER';
        SFieldNames{end+1} = 'Common';
   
    % Поиск файлов
        % Инициализация массива имён файлов
            FileNames = cell(0);
        % Определим содержимое рабочей директории
            Listing = dir;
        % Цикл по количеству элементов, содержащихся в директории
            for k = 1:length(Listing)
                % Рассматриваем только файлы
                if ~Listing(k).isdir
                    % Проверим, чтобы имя файла начиналось на NamePrefix и
                    % имело расширение 'm'
                    if length(Listing(k).name) >= length([NamePrefix, ...
                            '.m'])
                        if strcmp(Listing(k).name(1 : length( ...
                                NamePrefix)), NamePrefix) && strcmp( ...
                                Listing(k).name(end-1 : end), '.m')
                            FileNames{end+1} = Listing(k).name; %#ok<AGROW>
                        end
                    end
                end
            end

    % Обработка каждого найденного файла
        for k = 1:length(FileNames)
            % Сохраним текущее количество наборов параметров
                NumParams = length(Params);

            % Попробуем открыть файл с параметрами
                try
                    fid = fopen(FileNames{k});
                catch
                    error('Failed to open setup file %s!\n', FileNames{k});
                end
                
            % Инициализация очередного набора параметров
                BufParams = [];
                
            % Поочерёдное считывание строк из файла
                tline = fgetl(fid);
                isFindEndOfParams = false; % это присвоение необходимо на
                    % случай, если файл пустой
                while ischar(tline)
                    % Добавим 'BufParams.' перед именем полей верхнего
                    % уровня
                        for n = 1:length(SFieldNames)
                            OldStr = [SFieldNames{n}, '.'];
                            NewStr = ['BufParams.', OldStr];
                            tline = strrep(tline, OldStr, NewStr);
                        end

                    % Попробуем выполнить строку
                        try
                            eval(tline);
                        catch
                            error(['Failed to evaluate ''%s'' in ', ...
                                'file %s!\n'], tline, FileNames{k});
                        end

                    % Определим, есть ли в этой строке флаг окончания
                    % набора параметров
                        isFindEndOfParams = contains(tline, ...
                            '% End of Params');
                    
                    % Если был найден флаг окончания набора параметров и
                    % текущий набор параметров не пустой, то нужно добавить
                    % текущий набор параметров в качестве нового набора и
                    % инициализировать накопление нового набора параметров
                        if isFindEndOfParams
                            if ~isempty(BufParams)
                                Params{end+1} = BufParams; %#ok<AGROW>
                                BufParams = [];
                            end
                        end
                    
                    % Считываем очередную строку файла
                        tline = fgetl(fid);
                end

            % Если файл закончился, и текущий набор параметров не пустой,
            % то надо добавить его в качестве нового набора параметров
                if ~isFindEndOfParams
                    if ~isempty(BufParams)
                        Params{end+1} = BufParams; %#ok<AGROW>
                    end
                end

            % Закроем файл
                fclose(fid);

            % Вывод результата на экран
                fprintf(['%s %d parameter sets are parsed from ', ...
                    'file %s.\n'], datestr(now), length(Params) - ...
                    NumParams, FileNames{k});
                fprintf('\n');
        end
        
    % Если не удалось собрать ни один набор параметров, то создадим пустой
    % для выполнения расчётов с параметрами по умолчанию
        if isempty(Params)
            Params = cell(1);
            % Вывод результата на экран
                fprintf(['%s No parameters were found thus one ', ...
                    'calculation with default parameters will be ', ...
                    'performed.\n'], datestr(now));
                fprintf('\n');
        end
        
		
	% Добавим/проверим имя директории для сохранения результатов
        if strcmp(NamePrefix, 'RegressionSetup')
            % Принудительно устанавливаем имя директории для сохранения
            % результатов!
            for k = 1:length(Params)
                Params{k}.Common.SaveDirName = 'TestRegressionResults';
            end
        else
            % Если установлено имя директории для сохранения результатов
            % TestRegressionResults или ReferenceRegressionResults, то
            % выводим ошибку
            for k = 1:length(Params)
                if isfield(Params{k}, 'Common')
                if isfield(Params{k}.Common, 'SaveDirName')
                if strcmpi(Params{k}.Common.SaveDirName, ...
                        'TestRegressionResults') || ...
                        strcmpi(Params{k}.Common.SaveDirName, ...
                        'ReferenceRegressionResults')
                    error(['It is prohibited to name save directory ', ...
                        'as TestRegressionResults or ', ...
                        'ReferenceRegressionResults']);
                end
                end
                end
            end
        end

    % Добавим все внутренние директории текущей рабочей директории в path
        AddSubFolders2Path(cd);
end

function AddSubFolders2Path(CurPath)
    % Можно сделать так:
    %   addpath(genpath(CurPath));
    % но, например, в случае работы в папке GitHub это приведёт к появлению
    % подпапок '.git', что может привести к неожиданным последствиям!
    % Поэтому сделаем всё в ручную, используя рекурсию и считая, что имя
    % папки должно начинаться с буквы.
    
    % Определим содержимое текущей директории
        FolderInfo = dir(CurPath);

    % Пробежимся по всему содержимому, выделим директории
    for k = 1:length(FolderInfo)
        if FolderInfo(k).isdir == 1
            if isletter(FolderInfo(k).name(1))
                NewPath = [CurPath, '\', FolderInfo(k).name];
                path(NewPath, path);
                AddSubFolders2Path(NewPath);
            end
        end
    end
end

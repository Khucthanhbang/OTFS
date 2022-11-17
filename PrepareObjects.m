function Objs = PrepareObjects(Ruler, Params)
% 
% Функция инициализации объектов.

    global FieldNames
    
    % Инициализация cell-массива для хранения объектов главного цилка
        Objs = cell(Ruler.NumWorkers, 1);

    for k = 1:Ruler.NumWorkers
        % Цикл инициализации объектов главного цикла
            for n = 1:length(FieldNames)
                FH = str2func(['Class', FieldNames{n}]);
                Objs{k}.(FieldNames{n}) = FH(Params);
            end            
            Objs{k}.Stat = ClassStat(Ruler);

        % Кросспроверка параметров, установка параметров
            CrossCheckAndCalcParams(Objs{k});

        % Вычисление внутренних переменных (кроме Stat!)
            for n = 1:length(FieldNames)
                Objs{k}.(FieldNames{n}).CalcIntParams();
            end            
            for n = 1:length(FieldNames)
                Objs{k}.(FieldNames{n}).CalcIntParamsFromExtParams( ...
                    Objs{k});
            end            
    end
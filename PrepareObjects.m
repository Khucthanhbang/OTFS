function Objs = PrepareObjects(Ruler, Params)
% 
% ������� ������������� ��������.

    global FieldNames
    
    % ������������� cell-������� ��� �������� �������� �������� �����
        Objs = cell(Ruler.NumWorkers, 1);

    for k = 1:Ruler.NumWorkers
        % ���� ������������� �������� �������� �����
            for n = 1:length(FieldNames)
                FH = str2func(['Class', FieldNames{n}]);
                Objs{k}.(FieldNames{n}) = FH(Params);
            end            
            Objs{k}.Stat = ClassStat(Ruler);

        % ������������� ����������, ��������� ����������
            CrossCheckAndCalcParams(Objs{k});

        % ���������� ���������� ���������� (����� Stat!)
            for n = 1:length(FieldNames)
                Objs{k}.(FieldNames{n}).CalcIntParams();
            end            
            for n = 1:length(FieldNames)
                Objs{k}.(FieldNames{n}).CalcIntParamsFromExtParams( ...
                    Objs{k});
            end            
    end
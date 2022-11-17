function DeleteObjects()
%
% Удаление всех объектов, используемых в цикле обработки одного набора
% параметров

    global Ruler Objs FieldNames
    
    if ~isempty(Ruler)
        if ~isempty(Objs)
        for k = 1:Ruler.NumWorkers
            for n = 1:length(FieldNames)
                if ~isfield(Objs{k}, FieldNames(n))
                    Objs{k}.(FieldNames(n)).DeleteSubObjs();
                    delete(Objs{k}.(FieldNames(n)));
                end
            end

            delete(Objs{k}.Stat);
        end
        end
    
        delete(Ruler);
    end

end
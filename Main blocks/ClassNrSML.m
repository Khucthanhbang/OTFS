classdef ClassNrSML < handle
% Class reuses NR ToolBox function to perform Scrambling, Mapping and Layer
% mapping (SML)
%
properties % Constants
end
properties % Variable parameters of the current object (with default
        % values)
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
    % From SchSource
        SchDirection;
        CellID;
        NumLayers;
        ModType;
        UeRNTI;
        PdschModNumBits;
end
properties % Calculated parameters of the current object (without default
        % values)
end
methods
    function obj = ClassNrSML(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassNrSML.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'NrSML')
                NrSML = Params.NrSML;
            else
                NrSML = [];
            end
        % Here is no variable parameters in the current object!
    end
    function CalcIntParams(obj) %#ok<MANU>
    % Determining the values of calculated parameters that do not require
    % information about the values of parameters from other objects
    end
    function CalcIntParamsFromExtParams(obj, Objs)
    % Getting parameters from other objects and determining the values of
    % calculated parameters of the current object that do require
    % information about the values of parameters from other objects
        obj.SchDirection = Objs.SchSource.SchDirection;
        obj.CellID = Objs.SchSource.CellID;
        obj.NumLayers = Objs.SchSource.NumLayers;
        obj.ModType = Objs.SchSource.ModType;
        obj.UeRNTI = Objs.SchSource.UeRNTI;
        obj.PdschModNumBits = Objs.SchSource.PdschModNumBits;
    end
    function DeleteSubObjs(obj) %#ok<MANU>
    % Removing of internal (sub) objects
        % subobjects are absent
    end
    function OutData = StepTx(obj, InData)
    % Function performs scrambling, mapping and layer mapping operations
    % using function from the NR Toolbox
        if strcmp(obj.SchDirection, 'DL')
            OutData = nrPDSCH(InData, obj.ModType, obj.NumLayers, ...
                obj.CellID, obj.UeRNTI);
        elseif strcmp(obj.SchDirection, 'UL')
            error('UL is not supported in this version');
            % OutData = nrPUSCH();
        end
    end
    function OutData = StepRx(obj, InData, VarVals)
    % Function performs descrambling, demapping and layer demapping
    % operations using function from the NR Toolbox
        if (sum(isinf(InData)) + sum(isnan(InData)) + ...
                sum(isinf(VarVals)) + sum(isnan(VarVals))) > 0
            error('Inf/Nan at demapper input!');
        end
        if strcmp(obj.SchDirection, 'DL')
            % Get llr values
                Variance = 1;
                [OutData, ~] = nrPDSCHDecode(InData, obj.ModType, ...
                    obj.CellID, obj.UeRNTI, Variance);
            % nrPDSCHDecode can't work with different variance values,
            % instead it uses one common value. Thus we use Variance = 1 as
            % parameter and then scale output llr values. Note that it is
            % true only for approximate llr values. In this case 1/Var is
            % the multiplyer coefficient for llr value. Why? In 2d Gaussian
            % distribution we have the following exponent argument:
            %   -((x-ax)^2/Varx + (y-ay)^2/Vary)/2 and Varx = Vary,
            % so Var = 2*Varx = 2*Vary and we can write
            %   -((x-ax)^2 + (y-ay)^2)/Var
            % (1/Var it is above mentioned multiplyer)
            
            % Scaling llr values
                Buf = reshape(OutData{1}, obj.PdschModNumBits, []).';
                Buf = Buf .* repmat(1./VarVals, 1, obj.PdschModNumBits);
                OutData{1} = reshape(Buf.', [], 1);
        elseif strcmp(obj.SchDirection, 'UL')
            error('UL is not supported in this version');
            % OutData = nrPUSCHDecode();
        end
    end
end
end
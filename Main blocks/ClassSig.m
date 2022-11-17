classdef ClassSig < handle
% The class allows to form and receive a signal of one frame
%
properties % Constants
end
properties % Variable parameters of the current object (with default
        % values)
    % Signal type: 'OFDM' || 'FBMC' || 'PR-SEFDM' || 'G-OFDM' || 'SEFDM'
        Type = 'OTFS';
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
end
properties % Calculated parameters of the current object (without default
        % values)
    % object of current class implementing signal modulation and detection
        CurSig;
        % Sub object CurSig should have methods:
        %   OutData = StepTx(obj, InData);
        %   [OutData, VarVals] = StepRx(obj, InData, InstChan);
        %       (StepRx should include equalization procedure)
        % Also it should include following parameters:
        %    DataPartFirstSample;
        %    DataPartLastSample;
        %    NumAddSamplesInDataPart;
        %    FirstAndLastSamplesInSymbol;
        %    SigSamplesNums2GetFreqResp;
end
methods
    function obj = ClassSig(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassSig.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'Sig')
                Sig = Params.Sig;
            else
                Sig = [];
            end
        % Type
            if isfield(Sig, 'Type')
                obj.Type = Sig.Type;
            end
            obj.Type = ValidateString(obj.Type, {'OFDM', 'SEFDM','FBMC',...
                'PR-SEFDM', 'G-OFDM', 'OTFS'}, funcName, 'Type');
    end
    function CalcIntParams(obj) %#ok<MANU>
    % Determining the values of calculated parameters that do not require
    % information about the values of parameters from other objects
    end
    function CalcIntParamsFromExtParams(obj, Objs)
    % Getting parameters from other objects and determining the values of
    % calculated parameters of the current object that do require
    % information about the values of parameters from other objects
        switch obj.Type
            case 'OFDM'
                obj.CurSig = Objs.NrOFDM;
            case 'SEFDM'
                obj.CurSig = Objs.SEFDM;
            case 'FBMC'
                error('Not ready yet!')
            case 'PR-SEFDM'
                error('Not ready yet!')
            case 'G-OFDM'
                error('Not ready yet!')
            case 'OTFS'
                obj.CurSig = Objs.NrOTFS;
        end
    end
    function DeleteSubObjs(obj) %#ok<MANU>
    % Removing of internal (sub) objects
        % CurSig shouldn't be removed here because it is not actually
        % internal subobject
    end    
    function OutData = StepTx(obj, InData)
        OutData = obj.CurSig.StepTx(InData);
    end
    function [OutData, VarVals] = StepRx(obj, InData, InstChan)
        [OutData, VarVals] = obj.CurSig.StepRx(InData, InstChan);
    end
end
end
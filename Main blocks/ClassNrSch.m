classdef ClassNrSch < handle
% Class reuses NR ToolBox function to perform CRC, LDPC Encoding, RM and
% code block concatenation in Tx and Rx directions for PDSCH channel
%
properties % Constants
    % LDPC decoding algorithm: 
    % 'Belief propagation' (default) | 'Layered belief propagation' | ...
    % 'Normalized min-sum' | 'Offset min-sum'
        LDPCDecodingAlgorithm = 'Belief propagation'; % default value in
            % nrDLSCHDecoder object
    % Scaling factor for normalized min-sum decoding, specified as a real
    % scalar in the range (0, 1].
        ScalingFactor = 0.75; % default value in nrDLSCHDecoder object
    % Offset for offset min-sum decoding, specified as a nonnegative finite
    % real scalar.
        Offset = 0.5; % default value in nrDLSCHDecoder object
    % Redundancy Version. Possible values: {0 - default, 1, 2, 3}
        RedVer = 0;
    % Multiple HARQ processes switch. Possible values: {false - default,
    % true}
        IsMultiHARQ = false;
end
properties % Variable parameters of the current object (with default
        % values)
    % Flag whether coding is needed or not in this object's Step function:
        % 0 = coding is needed || 1 = coding is not needed
        isTransparent = 0; % influence on ClassBERRuler.h2dBInit, .h2dBMaxStep
    % Maximum LDPC decoding iterations, specified as a positive integer.
    % Since early termination is enabled, decoding stops once parity-checks
    % are satisfied. In this case, fewer iterations take place than the 
    % maximum specified by this argument.
        MaxLDPCIterCount = 12; 
            % influence on ClassBERRuler.h2dBInit
    % Do we need to normalize LDPC iterations according to SIC
        IsNormLDPCiter = 1; 
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
    % From SchSource
        SchDirection;
        PdschCodeRate;
        PdschModNumBits;
        NumLayers;
        OutLength;
        TbSize;  
        ModType;
end
properties % Calculated parameters of the current object (without default
        % values)
    % DL/UL Encoder/Decoder objects
        SchEncoder;
        SchDecoder;
    % The number of bits to be used in calculating Pb in Channel
        NumBits4Pb;
end
methods
    function obj = ClassNrSch(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassNrSch.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'NrSch')
                NrSch = Params.NrSch;
            else
                NrSch = [];
            end
        % isTransparent
            if isfield(NrSch, 'isTransparent')
                obj.isTransparent = NrSch.isTransparent;
            end
            ValidateAttributes(obj.isTransparent, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'isTransparent');
            if isfield(NrSch, 'IsNormLDPCiter')
                obj.IsNormLDPCiter = NrSch.IsNormLDPCiter;
            end
            ValidateAttributes(obj.IsNormLDPCiter, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'IsNormLDPCiter');
            
        if obj.IsNormLDPCiter
        if isfield(Params, 'SEFDM')
            if isfield(Params.SEFDM, 'isSIC')
            if isfield(Params.SEFDM, 'NumSICiter')
                obj.MaxLDPCIterCount = obj.MaxLDPCIterCount / ...
                    (Params.SEFDM.NumSICiter + 1);
            else
                obj.MaxLDPCIterCount = obj.MaxLDPCIterCount / 2;
            end
            end
        end
        end
    end
    function CalcIntParams(obj) %#ok<MANU>
    % Determining the values of calculated parameters that do not require
    % information about the values of parameters from other objects
    end
    function CalcIntParamsFromExtParams(obj, Objs)
    % Getting parameters from other objects and determining the values of
    % calculated parameters of the current object that do require
    % information about the values of parameters from other objects
    
        % Get parameters from other objects
            obj.SchDirection = Objs.SchSource.SchDirection;
            obj.PdschCodeRate = Objs.SchSource.PdschCodeRate;
            obj.PdschModNumBits = Objs.SchSource.PdschModNumBits;
            obj.NumLayers = Objs.SchSource.NumLayers;
            obj.OutLength = Objs.SchSource.NumReTotal * ...
                Objs.SchSource.PdschModNumBits;
            obj.TbSize = Objs.SchSource.TbSize;
            obj.ModType = Objs.SchSource.ModType;
    
        % Prepare Encoder and Decoder
            if strcmp(obj.SchDirection, 'DL')
                % Creation of NR Encoder and Decoder objects from NR
                % Toolbox
                    obj.SchEncoder = nrDLSCH();
                    obj.SchDecoder = nrDLSCHDecoderEdited(); % Decoder
                        % object is editted: HARQ is disabled (section is
                        % commented) to be able calculate BER
            elseif strcmp(obj.SchDirection, 'UL')
                error('UL is not supported in this version');
                % obj.SchEncoder = nrULSCH();
                % obj.SchDecoder = nrULSCHDecoder();
            end

        % Object parameters assignment based on input values
            obj.SchEncoder.MultipleHARQProcesses = obj.IsMultiHARQ;
            obj.SchDecoder.MultipleHARQProcesses = obj.IsMultiHARQ;
            obj.SchEncoder.TargetCodeRate = obj.PdschCodeRate;
            obj.SchDecoder.TargetCodeRate = obj.PdschCodeRate;
            obj.SchDecoder.MaximumLDPCIterationCount = ...
                obj.MaxLDPCIterCount;
            obj.SchDecoder.TransportBlockLength = obj.TbSize;
            obj.SchDecoder.LDPCDecodingAlgorithm = ...
                obj.LDPCDecodingAlgorithm;
            if strcmp(obj.LDPCDecodingAlgorithm, 'Normalized min-sum')
                obj.SchDecoder.ScalingFactor = obj.ScalingFactor;
            end
            if strcmp(obj.LDPCDecodingAlgorithm, 'Offset min-sum')
                obj.SchDecoder.Offset = obj.Offset;
            end

        % NumBits4Pb
            if obj.isTransparent    
                obj.NumBits4Pb = obj.OutLength;
            else
                obj.NumBits4Pb = obj.TbSize;
            end
    end
    function DeleteSubObjs(obj)
    % Removing of internal (sub) objects
        delete(obj.SchEncoder);
        delete(obj.SchDecoder);
    end
    function OutData = StepTx(obj, InData)
        if obj.isTransparent
            % If no coding is needed then this class is transparent and
            % it only adds useless bits after data bits
            tmpBits = randi(2, (obj.OutLength - length(InData)), 1) - 1;
            OutData = [InData; tmpBits];
        else
            % If coding is enabled then LDPC coding is applied to data bits
            % using NR Encoder object with specified parameters
            setTransportBlock(obj.SchEncoder, InData);
            OutData = obj.SchEncoder(obj.ModType, obj.NumLayers, ...
                obj.OutLength, obj.RedVer);
        end
    end
    function [OutData, BlkErr] = StepRx(obj, InData)
    % Currently BlkErr is not used in Main!
        if (sum(isinf(InData{1})) + sum(isnan(InData{1}))) > 0
            error('Inf/Nan at decoder input!');
        end
        if obj.isTransparent
            % If no coding is needed then this class is transparent
            % Input data obtained as LLRs so this function makes hard
            % decision and selects only data bits
            OutData = InData{1}(1:obj.TbSize);
            OutData(OutData > 0) = 0;
            OutData(OutData < 0) = 1;
            BlkErr = [];
        else
            % If coding is enabled then LDPC decoding is performed
            % using NR Decoder object with specified parameters
            [OutData, BlkErr] = obj.SchDecoder(InData{1}, obj.ModType, ...
                obj.NumLayers, obj.RedVer);
        end
    end
end
end
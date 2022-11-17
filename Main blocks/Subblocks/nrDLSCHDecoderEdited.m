classdef nrDLSCHDecoderEdited < matlab.System
% This is the edited class nrDLSCHDecoder from NR ToolBox
% Editing was done on lines 529 to 534 (commented)
    
%nrDLSCHDecoder Downlink Shared Channel (DL-SCH) Decoder
%   DLSCHDEC = nrDLSCHDecoder creates a Downlink Shared Channel Decoder
%   System object, DLSCHDEC. This object takes PDSCH output and processes
%   it through the components of the downlink shared channel (DL-SCH)
%   decoder (rate recovery, LDPC decoding, desegmentation, and CRC
%   decoding). It decodes signals that were encoded according to 3GPP TR
%   38.212:
%   * Section 7.2 Downlink shared channel and paging channel
%
%   DLSCHDEC = nrDLSCHDecoder(Name,Value) creates a DL-SCH decoder object,
%   DLSCHDEC, with the specified property Name set to the specified Value.
%   You can specify additional name-value pair arguments in any order as
%   (Name1,Value1,...,NameN,ValueN).
%
%   Step method syntaxes
%
%   TRBLKOUT = step(DLSCHDEC,RXSOFTBITS,MODULATION,NLAYERS,RV), and
%   TRBLKOUT = step(DLSCHDEC,RXSOFTBITS,MODULATION,NLAYERS,RV,HARQID)
%   both apply the DL-SCH decoding chain to the RXSOFTBITS input.
%   RXSOFTBITS is a cell array or column vector of received log-likelihood
%   ratio (LLR) values corresponding to the received codeword(s). When a
%   cell array, it can have at most two elements, with each element a
%   column vector. MODULATION is a one of {'QPSK','16QAM','64QAM','256QAM'}
%   character arrays or strings specifying the modulation scheme. NLAYERS
%   is a scalar between 1 and 8 specifying the number of transmission
%   layers. For NLAYERS>4, a two-codeword transmission is assumed.
%   MODULATION can be a two-element cell array to specify the value for
%   each codeword for a two-codeword transmission. RV is an integer value
%   between 0 and 3 specifying which redundancy version is used with this
%   transmission. For two codewords, RV must be a two-element vector.
%   HARQID is an integer scalar between 0 and 15, specifying the ID of the
%   HARQ process used for the transport block(s). HARQID input is enabled
%   when MultipleHARQProcesses property is true, else there is only one
%   HARQ process in use.
%   The output TRBLKOUT is a cell array of at most two elements or a column
%   vector of length TransportBlockLength, a public property of
%   nrDLSCHDecoder, representing the decoded bits per transport block.
%
%   The object uses soft buffer state retention to combine the different
%   redundancy version received codewords for an individual HARQ process.
%   When multiple processes are enabled, independent buffers per process
%   are maintained. For multi-codeword transmissions, independent buffers
%   per codeword are maintained.
%
%   [TRBLKOUT,BLKERR] = step(DLSCHDEC,...) also returns an error flag
%   BLKERR to indicate if the transport block(s) was decoded in error or
%   not (true indicates an error). BLKERR is a logical row vector of length
%   2 for two-codeword processing.
%
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj,x) and y = obj(x) are
%   equivalent.
%
%   nrDLSCHDecoder methods:
%
%   step            - Decode PDSCH output to get the current transport
%                     block(s) (see above)
%   release         - Allow property value and input characteristics changes
%   clone           - Create a DL-SCH decoder object with same property values
%   isLocked        - Locked status (logical)
%   <a href="matlab:help nrDLSCHDecoder/reset">reset</a>           - Reset buffers for all HARQ processes
%   resetSoftBuffer - Reset buffer for specified HARQ process
%
%   nrDLSCHDecoder properties:
%
%   MultipleHARQProcesses     - Enable multiple HARQ processes
%   TargetCodeRate            - Target code rate
%   TransportBlockLength      - Length of decoded transport block(s) (in bits)
%   LimitedBufferSize         - Limited buffer size (Nref) for rate
%                               recovery
%   LDPCDecodingAlgorithm     - LDPC decoding algorithm
%   ScalingFactor             - Scaling factor for normalized min-sum LDPC 
%                               decoding
%   Offset                    - Offset for offset min-sum LDPC decoding
%   MaximumLDPCIterationCount - Maximum number of LDPC decoding iterations
%
%   Example 1:
%   % Use a DL-SCH Encoder and Decoder system object back to back.
%
%   targetCodeRate = 526/1024;
%   modulation = 'QPSK';
%   nlayers = 2;
%   trBlkLen = 5120;
%   outCWLen = 10240;
%   rv = 0;
%
%   % Construct and configure encoder system object
%   enc = nrDLSCH;
%   enc.TargetCodeRate = targetCodeRate;
%
%   % Construct and configure decoder system object
%   dec = nrDLSCHDecoder;
%   dec.TargetCodeRate = targetCodeRate;
%   dec.TransportBlockLength = trBlkLen;
%
%   % Construct random data and send it through encoder and decoder, back
%   % to back.
%   trBlk = randi([0 1],trBlkLen,1);
%   setTransportBlock(enc,trBlk);
%   codedTrBlock = enc(modulation,nlayers,outCWLen,rv);
%   rxSoftBits = 1.0 - 2.0*double(codedTrBlock);
%   [decbits,blkerr] = dec(rxSoftBits,modulation,nlayers,rv);
%
%   % Check that the decoder output matches the original data
%   isequal(decbits,trBlk)
%
%   Example 2:
%   % Use DL-SCH Encoder and Decoder system objects with different
%   % transport block length processing
%
%   encDL = nrDLSCH('MultipleHARQProcesses',true);
%   cwID = 0;
%   harqID = 1;
%   modSch = 'QPSK';
%   nlayers = 1;
%   rv = 0;
%
%   trBlkLen1 = 5120;
%   trBlk1 = randi([0 1],trBlkLen1,1,'int8');
%   setTransportBlock(encDL,trBlk1,cwID,harqID);
%   outCWLen1 = 10240;
%   codedTrBlock1 = step(encDL,modSch,nlayers,outCWLen1,rv,harqID);
%
%   decDL = nrDLSCHDecoder('MultipleHARQProcesses',true);
%   decDL.TransportBlockLength = trBlkLen1;
%
%   rxBits1 = awgn(1-2*double(codedTrBlock1),5);
%   [decBits1,blkErr1] = step(decDL,rxBits1,modSch,nlayers,rv,harqID);
%
%   % Switch to a different transport block length for same HARQ process
%   trBlkLen2 = 4400;
%   trBlk2 = randi([0 1],trBlkLen2,1,'int8');
%   setTransportBlock(encDL,trBlk2,cwID,harqID);
%   outCWLen2 = 8800;
%   codedTrBlock2 = step(encDL,modSch,nlayers,outCWLen2,rv,harqID);
%
%   rxBits2 = awgn(1-2*double(codedTrBlock2),8);
%   decDL.TransportBlockLength = trBlkLen2;
%   if blkErr1
%       % Reset decoder if there was an error for first transport block
%       resetSoftBuffer(decDL,cwID,harqID);
%   end
%   [decBits2,blkErr2] = step(decDL,rxBits2,modSch,nlayers,rv,harqID);
%   [blkErr1 blkErr2]
%
%   See also nrDLSCH, nrDLSCHInfo, nrPDSCHDecode.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    % Public, non-tunable logical property
    properties (Nontunable, Logical)
        %MultipleHARQProcesses Enable multiple HARQ processes
        %   Enable multiple HARQ processes when set to true. A maximum of
        %   16 processes can be enabled. When set to false, a single
        %   process is used. In both cases, for each process, the rate
        %   recovered input is buffered and combined with previous
        %   receptions of that process, before passing on for LDPC
        %   decoding. The default value of this property is false.
        MultipleHARQProcesses = false;
    end

    % Public, tunable properties
    properties
        %TargetCodeRate Target Code Rate
        %   Specify target code rate as a numeric scalar or vector of
        %   length two, each value between 0 and 1.0. The default value of
        %   this property is 526/1024.
        TargetCodeRate = 526 / 1024;
        %TransportBlockLength Size of transport block output
        %   Specify the transport block size (in bits) to be output from
        %   decoder, as a scalar or vector of length two, positive
        %   integer. The default value of this property is 5120.
        TransportBlockLength = 5120;
    end

    properties (Nontunable)
        %LimitedBufferSize Limited buffer size for rate recovery
        %   Specify the size of the internal buffer used for rate recovery
        %   as a scalar, positive integer. The default value of this
        %   property is 25344 that corresponds to the maximum codeword
        %   length.
        LimitedBufferSize = 25344;
        %LDPCDecodingAlgorithm LDPC decoding algorithm
        %   Specify the LDPC decoding algorithm as one of 'Belief propagation', 
        %   'Layered belief propagation', 'Normalized min-sum', or
        %   'Offset min-sum'. The default value of this property is
        %   'Belief propagation'.
        LDPCDecodingAlgorithm = 'Belief propagation';
    end

    % Public, nontunable properties
    properties (Nontunable)
        %ScalingFactor Scaling factor for normalized min-sum decoding
        %   Specify the scaling factor as a scalar real value greater than
        %   0 and less than or equal to 1. The default value of this
        %   property is 0.75. This property only applies when
        %   LDPCDecodingAlgorithm is set to 'Normalized min-sum'.
        ScalingFactor = 0.75;
        %Offset Offset for offset min-sum decoding
        %   Specify the offset as a scalar real value greater than
        %   or equal to 0. The default value of this property is 0.5. This
        %   property only applies when LDPCDecodingAlgorithm is set
        %   to 'Offset min-sum'.
        Offset = 0.5;
    end

    properties (Nontunable)
        %MaximumLDPCIterationCount Maximum LDPC decoding iterations
        %   Specify the maximum number of LDPC decoding iterations as a
        %   scalar positive integer. The default value of this property is
        %   12.
        MaximumLDPCIterationCount = 12;
    end

    % Private state property
    properties(Access = protected)
        % Maximum HARQ processes = 16
        pCWSoftBuffer = {{0,0}; {0,0}; {0,0}; {0,0}; {0,0}; {0,0}; ...
                         {0,0}; {0,0}; {0,0}; {0,0}; {0,0}; {0,0}; ...
                         {0,0}; {0,0}; {0,0}; {0,0}};
    end

    % Private properties
    properties (Access=private)
        % Copies of public properties, scalar expanded, if necessary.
        pTargetCodeRate;
        pTransportBlockLength;
    end

    % Supported values for LDPCDecodingAlgorithm
    properties (Constant, Hidden)
        LDPCDecodingAlgorithmSet = matlab.system.StringSet({ ...
            'Belief propagation','Layered belief propagation', ...
            'Normalized min-sum','Offset min-sum'});
    end
    
    methods
        % Constructor
        function obj = nrDLSCHDecoder(varargin)
            % Set property values from any name-value pairs input to the
            % constructor
            setProperties(obj,nargin,varargin{:});
        end

        function resetSoftBuffer(obj,cwID,varargin)
        %resetSoftBuffer Reset soft buffer per codeword for HARQ process
        %
        %   resetSoftBuffer(DLSCHDEC,CWID) and
        %   resetSoftBuffer(DLSCHDEC,CWID,HARQID) resets the internal soft
        %   buffer for specified codeword CWID (either of 0 or 1) and HARQ
        %   process HARQID. HARQID defaults to a value of 0 when not
        %   specified. When MultipleHARQProcesses property is set to true,
        %   HARQID must be an integer in [0, 15].

            narginchk(2,3);
            fcnName = [class(obj) '/resetSoftBuffer'];
            if nargin>2
                harqID = varargin{1};
                nr5g.internal.validateParameters('HARQID',harqID,fcnName);
            else
                harqID = 0;
            end

            validateattributes(cwID,{'numeric'}, ...
                {'integer','scalar','>=',0,'<=',1},fcnName,'CWID');

            obj.pCWSoftBuffer{harqID+1}{cwID+1} = [];
        end

        function set.TargetCodeRate(obj,value)
            % real scalar, or vector of length 2, 0<r<1
            propName = 'TargetCodeRate';
            validateattributes(length(value(:)), {'numeric'}, ...
                {'scalar','>',0,'<',3}, ...
                [class(obj) '.' propName], 'Length of TargetCodeRate');

            validateattributes(value, {'numeric'}, ...
                {'real','<',1,'>',0}, ...
                [class(obj) '.' propName], propName);

            obj.TargetCodeRate = value;
        end

        function set.TransportBlockLength(obj,value)
            % real scalar, or vector of length 2, integer > 0
            propName = 'TransportBlockLength';
            validateattributes(length(value(:)), {'numeric'}, ...
                {'scalar','>',0,'<',3}, ...
                [class(obj) '.' propName], 'Length of TransportBlockLength');
            validateattributes(value, {'numeric'}, ...
                {'integer','>',0}, ...
                [class(obj) '.' propName], propName);

            obj.TransportBlockLength = value;
        end

        function set.LimitedBufferSize(obj,value)
            % scalar, integer > 0
            propName = 'LimitedBufferSize';
            validateattributes(value, {'numeric'}, ...
                {'scalar','integer','>',0}, ...
                [class(obj) '.' propName], propName);

            obj.LimitedBufferSize = value;
        end
        
        function set.ScalingFactor(obj,value)
            % scalar, 0<x<=1
            propName = 'ScalingFactor';
            validateattributes(value, {'numeric'}, ...
                {'scalar','real','>',0,'<=',1}, ...
                [class(obj) '.' propName], propName);

            obj.ScalingFactor = value;
        end

        function set.Offset(obj,value)
            % scalar, >= 0
            propName = 'Offset';
            validateattributes(value, {'numeric'}, ...
                {'scalar','real','finite','>=',0}, ...
                [class(obj) '.' propName], propName);

            obj.Offset = value;
        end
        
        function set.MaximumLDPCIterationCount(obj,value)
            % scalar, integer > 0
            propName = 'MaximumLDPCIterationCount';
            validateattributes(value, {'numeric'}, ...
                {'scalar','integer','>',0}, ...
                [class(obj) '.' propName], propName);

            obj.MaximumLDPCIterationCount = value;
        end

    end

    methods(Access = protected)

        function num = getNumInputsImpl(obj)
            % Number of Inputs based on property for varargin in step
            num = 4+double(obj.MultipleHARQProcesses);
        end

        function setupImpl(obj)
            setPrivateProperties(obj);
        end

        function [rxBits,blkCRCErr] = stepImpl(obj,rxSoftBits,modulation, ...
                nlayers,rv,varargin)
        % Supported syntaxes:
        %   [rxBits,blkCRCErr] = step(obj,rxSoftBits,modulation,nlayers,rv)
        %   [rxBits,blkCRCErr] = step(obj,rxSoftBits,modulation,nlayers,rv,harqID)

            narginchk(5,6)
            fcnName = [class(obj) '/step'];

            % Validate inputs
            validateattributes(nlayers, {'numeric'}, ...
                {'scalar','integer','<=',8,'>=',1},fcnName,'NLAYERS');
            if nlayers>4  % Key check
                is2CW = true;
                nl1 = floor(nlayers/2);
                nl2 = ceil(nlayers/2);
            else
                is2CW = false;
                nl1 = nlayers;
            end

            modlist = {'QPSK','16QAM','64QAM','256QAM'};
            if iscell(modulation)
                modLen = length(modulation);
                validateattributes(modLen,{'numeric'}, ...
                    {'scalar','>',0,'<',3},fcnName, ...
                    'Length of MODULATION specified as a cell');

                modSch = cell(1,modLen);
                for idx = 1:modLen
                    modSch{idx} = validatestring(modulation{idx},modlist, ...
                        fcnName,'MODULATION');
                end
            else
                modSch = validatestring(modulation,modlist,fcnName,'MODULATION');
            end
            % Scalar expand, if necessary
            if iscell(modSch)
                if is2CW && length(modSch)==1
                    modScheme = {modSch{1},modSch{1}};
                else
                    modScheme = modSch;
                end
            else
                if is2CW
                    modScheme = {modSch,modSch};
                else
                    modScheme = {modSch};
                end
            end

            % vector RV value
            coder.internal.errorIf( is2CW && length(rv)~=2, ...
                'nr5g:nrDLSCH:InvalidRVLength');
            if is2CW
                % vector RV value
                validateattributes(rv,{'numeric'}, ...
                    {'integer','>=',0,'<=',3},fcnName,'RV')
            else
                % Check RV input is a scalar
                nr5g.internal.validateParameters('RV',rv,fcnName);
            end

            if nargin == 5 % step(obj,rxSoftBits,modulation,nlayers,rv)
                harqID = 0;
            else    % step(obj,rxSoftBits,modulation,nlayers,rv,harqID)
                harqID = varargin{1};
                nr5g.internal.validateParameters('HARQID',harqID,fcnName);
            end

            % Allows both cell and column as input. Cross-checks with
            % is2CW and handles empties as inputs
            if iscell(rxSoftBits)
                if length(rxSoftBits)==2
                    coder.internal.errorIf(~is2CW,'nr5g:nrDLSCH:InvalidSCWInput');

                    rxSoftBits1 = rxSoftBits{1};
                    rxSoftBits2 = rxSoftBits{2};

                    if isempty(rxSoftBits1) && isempty(rxSoftBits2)
                        rxBits1 = zeros(0,1,'int8');
                        rxBits2 = zeros(0,1,'int8');
                        rxBits = {rxBits1, rxBits2};
                        blkCRCErr = false(1,2);  % no error
                    else
                        validateattributes(rxSoftBits{1},{'double','single'}, ...
                            {'real','column'},fcnName,'Codeword 1');
                        validateattributes(rxSoftBits{2},{'double','single'}, ...
                            {'real','column'},fcnName,'Codeword 2');

                        % Process first codeword
                        [rxBits1,blkCRCErr1] = dlschDecode(obj,rxSoftBits1, ...
                            modScheme{1},nl1,rv(1),harqID,1);
                        % Process second codeword
                        [rxBits2,blkCRCErr2] = dlschDecode(obj,rxSoftBits2, ...
                            modScheme{2},nl2,rv(2),harqID,2);

                        rxBits = {rxBits1,rxBits2};
                        blkCRCErr = [blkCRCErr1,blkCRCErr2];
                    end

                elseif length(rxSoftBits)==1
                    coder.internal.errorIf(is2CW,'nr5g:nrDLSCH:InvalidMCWInput');

                    rxSoftBits1 = rxSoftBits{1};
                    if isempty(rxSoftBits1)
                        rxBits = zeros(size(rxSoftBits1),'int8');
                        blkCRCErr = false;  % no error
                    else
                        validateattributes(rxSoftBits1,{'double','single'}, ...
                            {'real','column'},fcnName,'Codeword 1');

                        % Process first codeword
                        [rxBits,blkCRCErr] = dlschDecode(obj,rxSoftBits1, ...
                            modScheme{1},nl1,rv(1),harqID,1);
                    end
                    % output is a column vector, not a cell
                else
                    coder.internal.errorIf(1,'nr5g:nrDLSCH:InvalidRxInputCellLength');
                end
            else
                coder.internal.errorIf(is2CW,'nr5g:nrDLSCH:InvalidMCWInput');

                if isempty(rxSoftBits)
                    rxBits = zeros(size(rxSoftBits),'int8');
                    blkCRCErr = false;  % no error
                else
                    validateattributes(rxSoftBits,{'double','single'}, ...
                        {'real','column'},fcnName,'Codeword 1');

                    % Process first codeword
                    [rxBits,blkCRCErr] = dlschDecode(obj,rxSoftBits, ...
                        modScheme{1},nl1,rv(1),harqID,1);
                end
            end

        end

        function [rxBits,blkCRCErr] = dlschDecode(obj,rxSoftBits, ...
                modScheme,nlayers,rv,harqID,cwIdx)
            % Decode DLSCH per codeword

            targetCodeRate = obj.pTargetCodeRate(cwIdx);
            trBlkLen = obj.pTransportBlockLength(cwIdx);
            info = nrDLSCHInfo(trBlkLen,targetCodeRate);

            % Rate recovery
            ncb = info.C;
            raterecovered = nrRateRecoverLDPC(rxSoftBits,trBlkLen, ...
                targetCodeRate,rv,modScheme,nlayers,ncb, ...
                obj.LimitedBufferSize);

            % Combining
            if isequal(size(obj.pCWSoftBuffer{harqID+1}{cwIdx}),[info.N,ncb])
                raterecoveredD = double(raterecovered) + obj.pCWSoftBuffer{harqID+1}{cwIdx};
            else
                raterecoveredD = double(raterecovered);
            end
            raterecoveredD = double(raterecovered);
            % LDPC decoding: set to early terminate, within max iterations
            decoded = nrLDPCDecode(raterecoveredD,info.BGN, ...
                obj.MaximumLDPCIterationCount,'Algorithm',obj.LDPCDecodingAlgorithm, ...
                'ScalingFactor',obj.ScalingFactor,'Offset',obj.Offset);

            % Code block desegmentation and code block CRC decoding
            desegmented = nrCodeBlockDesegmentLDPC(decoded,info.BGN,trBlkLen+info.L);

            % Transport block CRC decoding
            [rxBits,blkErr] = nrCRCDecode(desegmented,info.CRC);

            % Logic to reset in case no more RVs are available is not here.
            % Calling code would reset this object in that case.
            errflg = (blkErr ~= 0); % errored
%             if errflg
%                 obj.pCWSoftBuffer{harqID+1}{cwIdx} = raterecoveredD;
%             else
%                 % Flush soft buffer on CRC pass
%                 obj.pCWSoftBuffer{harqID+1}{cwIdx} = [];
%             end
            blkCRCErr = errflg;

        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            for cwIdx = 1:2
                info = nrDLSCHInfo(obj.pTransportBlockLength(cwIdx), ...
                    obj.pTargetCodeRate(cwIdx));
                obj.pCWSoftBuffer{1}{cwIdx} = zeros(info.N,info.C);
                if obj.MultipleHARQProcesses
                    for harqIdx = 2:16
                        obj.pCWSoftBuffer{harqIdx}{cwIdx} = zeros(info.N,info.C);
                    end
                end
            end
        end

        function processTunedPropertiesImpl(obj)
            % Perform calculations if tunable properties change while
            % system is running
            setPrivateProperties(obj);
        end

        function flag = isInactivePropertyImpl(obj,prop)
            flag = false;
            switch prop
                case 'ScalingFactor'
                    if ~strcmp(obj.LDPCDecodingAlgorithm,'Normalized min-sum')
                        flag = true;
                    end
                case 'Offset'
                    if ~strcmp(obj.LDPCDecodingAlgorithm,'Offset min-sum')
                        flag = true;
                    end
            end
        end

        function setPrivateProperties(obj)
            % scalar expand properties, if needed.
            if isscalar(obj.TargetCodeRate)
                obj.pTargetCodeRate = obj.TargetCodeRate.*ones(1,2);
            else
                obj.pTargetCodeRate = obj.TargetCodeRate;
            end

            if isscalar(obj.TransportBlockLength)
                obj.pTransportBlockLength = obj.TransportBlockLength.*ones(1,2);
            else
                obj.pTransportBlockLength = obj.TransportBlockLength;
            end
        end

        function s = saveObjectImpl(obj)
            s = saveObjectImpl@matlab.System(obj);
            if isLocked(obj)
                s.pCWSoftBuffer         = obj.pCWSoftBuffer;
                s.pTargetCodeRate       = obj.pTargetCodeRate;
                s.pTransportBlockLength = obj.pTransportBlockLength;
            end
        end

        function loadObjectImpl(obj,s,wasLocked)
            if wasLocked
                obj.pCWSoftBuffer         = s.pCWSoftBuffer;
                obj.pTargetCodeRate       = s.pTargetCodeRate;
                obj.pTransportBlockLength = s.pTransportBlockLength;
            end
            % Call the base class method
            loadObjectImpl@matlab.System(obj,s);
        end

    end

end
classdef ClassNrOFDM < handle
% Class reuses NR ToolBox function to perform OFDM signal generation
%
properties % Constants
end
properties % Variable parameters of the current object (with default
        % values)
    % Set OFDM Mode: 'Auto' || 'Manual'
        %  'Auto'   - to use the OFDM block from 5G Toolbox;
        %   Manual' - to use manually written  OFDM block 
        NrOFDMMode = 'Manual'; 
    % Equalizer type: 'ZF' || 'MMSE'
        EqType = 'ZF';
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
	% From SchSource
        CellCarrier; % object
        NrSchConfig; % object
        NrSchIndices;
        NrDmrsIndices;
        NrDmrsSymbols;
end
properties % Calculated parameters of the current object (without default
        % values)
    % OFDM configuration parameters
        % NR structure with parameters needed for OFDM generation
            CellOFDMInfo;
        % NFFT
            NFFT;
        % Number of samples for Cyclic prefixes
            CPLengths;
        % NR resource grids for transmission and reception
            NrTxGrid;
            NrRxGrid;  
        % The number of subcarriers
            K;
        % The number of OFDM-Symbols
            L;
        % The first used subcarrier number
            FirstSC;
    % Parameters needed for estimation energy per data bit from signal in
    % Channel
        % The numbers of the first and the last samples of the data part in
        % signal. Be careful! There can be pilot tones in some sig symbols 
        % of data part, that will affect the calculation 
            DataPartFirstSample;
            DataPartLastSample;
        % The total number of "additional" samples in the data part in
        % signal, here means for example cyclic prefix, zero postfix etc.
            NumAddSamplesInDataPart;
	% Parameters needed for calculation the PAPR
        FirstAndLastSamplesInSymbol; % it should be N x 2 array, where N - 
            % is the number of Sig-symbols used in PAPR calculation and
            % the first and second column are used for the first and the
            % last sample numbers respectievely
    % The numbers of samples for which it is needed to calculate the
    % frequency response in Channel, e.g. it can be first samples of each
    % Sig symbol
        SigSamplesNums2GetFreqResp;
end
methods
    function obj = ClassNrOFDM(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassNrOFDM.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'NrOFDM')
                NrOFDM = Params.NrOFDM;
            else
                NrOFDM = [];
            end
            
        % NrOFDMMode
            if isfield(NrOFDM, 'NrOFDMMode')
                obj.NrOFDMMode = NrOFDM.NrOFDMMode;
            end
            obj.NrOFDMMode = ValidateString(obj.NrOFDMMode, {'Auto', ...
                'Manual'}, funcName, 'NrOFDMMode');
        % EqType
            if isfield(NrOFDM, 'EqType')
                obj.EqType = NrOFDM.EqType;
            end
            obj.EqType = ValidateString(obj.EqType, {'ZF', 'MMSE'}, ...
                funcName, 'EqType');
    end
    function CalcIntParams(obj) %#ok<MANU>
    % Determining the values of calculated parameters that do not require
    % information about the values of parameters from other objects
    end
    function CalcIntParamsFromExtParams(obj, Objs)
    % Getting parameters from other objects and determining the values of
    % calculated parameters of the current object that do require
    % information about the values of parameters from other objects
        %  obj.CPLengths = 288*ones(1, L);
        % obj.CPLengths = [320 288*ones(1,6) 320 288*ones(1,6)];
        
        % Getting parameters from other objects
            obj.CellCarrier = Objs.SchSource.CellCarrier;
            obj.NrSchConfig = Objs.SchSource.NrSchConfig;
            obj.NrSchIndices = Objs.SchSource.NrSchIndices;
            obj.NrDmrsIndices = Objs.SchSource.NrDmrsIndices;
            obj.NrDmrsSymbols = Objs.SchSource.NrDmrsSymbols;
            
            StartSymbNum = Objs.SchSource.StartSymbNum; % 1
            NumPdschSymbPerSlot = Objs.SchSource.NumPdschSymbPerSlot; % 13
        % Determining the values of calculated parameters of the current
        % object 
            obj.CellOFDMInfo = nrOFDMInfo(obj.CellCarrier);
            obj.NFFT = obj.CellOFDMInfo.Nfft;
            obj.CPLengths = obj.CellOFDMInfo.CyclicPrefixLengths;
            obj.NrTxGrid = nrResourceGrid(obj.CellCarrier, ...
                obj.NrSchConfig.NumLayers);
            obj.NrRxGrid = obj.NrTxGrid;
            obj.NrTxGrid(obj.NrDmrsIndices) = obj.NrDmrsSymbols; 
            obj.K = size(obj.NrTxGrid, 1);
            obj.L = size(obj.NrTxGrid, 2);
            obj.FirstSC = obj.NFFT/2 - obj.K/2 + 1;
            
        % DataPartFirstSample etc
            LastSymbNum = StartSymbNum + NumPdschSymbPerSlot -1;

            obj.DataPartFirstSample = sum(obj.CPLengths(1 : ...
                StartSymbNum)) + obj.NFFT * StartSymbNum + 1;
            obj.DataPartLastSample = sum(obj.CPLengths(1 : ...
                LastSymbNum + 1)) + obj.NFFT * (LastSymbNum + 1);
            obj.NumAddSamplesInDataPart = sum(obj.CPLengths( ...
                StartSymbNum + 1 : LastSymbNum + 1));
            
        % FirstAndLastSamplesInSymbol
            obj.FirstAndLastSamplesInSymbol = zeros( ...
                NumPdschSymbPerSlot, 2);
            for k = 1:NumPdschSymbPerSlot
                NumSymsBefore = StartSymbNum + k - 1;
                obj.FirstAndLastSamplesInSymbol(k, 1) = sum( ...
                    obj.CPLengths(1 : NumSymsBefore) ) + obj.NFFT * ...
                    NumSymsBefore + 1;
                obj.FirstAndLastSamplesInSymbol(k, 2) = ...
                    obj.FirstAndLastSamplesInSymbol(k, 1) - 1 + ...
                    obj.CPLengths(NumSymsBefore + 1) + obj.NFFT;
            end

        % SigSamplesNums2GetFreqResp - we will use the first sample of each
        % OFDM-symbol
            obj.SigSamplesNums2GetFreqResp = zeros(1, obj.L);
            Shift = 0;
            for k = 1:obj.L
                Shift = Shift + obj.CPLengths(k);
                obj.SigSamplesNums2GetFreqResp(k) = Shift + 1;
                Shift = Shift + obj.NFFT;
            end
    end
    function DeleteSubObjs(obj)
    % Removing of internal (sub) objects
        delete(obj.CellCarrier);
        delete(obj.NrSchConfig);
    end
    function OutData = StepTx(obj, InData)
    % OFDM modulation
        % Put InData on NrTxGrid
            obj.NrTxGrid(obj.NrSchIndices) = InData;
        switch obj.NrOFDMMode
            case 'Auto' % NR OFDM Modulation
                OutData = nrOFDMModulate(obj.CellCarrier, obj.NrTxGrid);
            case 'Manual' % Manual OFDM Modulate
                PostIFFT = OFDMmodulation(obj); % here we don't need pass
                    % NrTxGrid as parameter because it's our own function!
                % Compose signal
                SymLen = obj.NFFT;
                SigSize = SymLen * obj.L + sum(obj.CPLengths);
                Sig = zeros(SigSize, 1);
                Shift = 0;
                for k = 1 : obj.L
                    CPL = obj.CPLengths(k);
                    % Prepare OFDM-Symbol and its CP
                        SigSymbol = PostIFFT(:, k);
                        SigCP = SigSymbol(end - CPL + 1 : end);
                    % Insert CP
                        Sig(Shift + (1:CPL)) = SigCP;
                        Shift = Shift + CPL;
                    % Insert OFDM-Symbol
                        Sig(Shift + (1:SymLen)) = SigSymbol;
                        Shift = Shift + SymLen;

                end
            % Ouptput
                OutData = Sig;
        end
    end
    function [OutData, VarVals] = StepRx(obj, InData, InstChan)
    % OFDM demodulation
        switch obj.NrOFDMMode
            case 'Auto' % NR OFDM demodulation
                obj.NrRxGrid = nrOFDMDemodulate(obj.CellCarrier, InData);
            case 'Manual' % Manual OFDM demodulation
                % Remove cyclic prefixes
                PostCPGrid = zeros(obj.NFFT, obj.L); 
                Shift = 0; 
                for k = 1 : obj.L
                    Shift = Shift + obj.CPLengths(k); 
                    SigSymbol = InData(Shift + (1 : obj.NFFT));
                    PostCPGrid(:, k) = SigSymbol;
                    Shift = Shift + obj.NFFT; 
                end
                OFDMdemodulation(obj, PostCPGrid); % here we don't need return
                    % NrRxGrid because it's our own function!
        end

        % Equalizing
            [EqGrid, EqVarVals] = Equalizer(obj, InstChan);
        
        % Get results from data subcarriers
            OutData = EqGrid(obj.NrSchIndices);
            VarVals = EqVarVals(obj.NrSchIndices);
    end
    function [EqGrid, EqVarVals] = Equalizer(obj, InstChan)
        % Channel estimation
            H = InstChan.FreqResp;
        % Variance estimation for each OFDM Symbol
            VarVals = zeros(size(H)) + InstChan.Var;
        % Get only used subcarriers
            GridH = H(obj.FirstSC + (0 : obj.K - 1), :);
            GridVarVals = VarVals(obj.FirstSC + (0 : obj.K - 1), :);
            
        % Equalizing
            if strcmp(obj.EqType, 'ZF')
                Eq = 1 ./ GridH;
            elseif strcmp(obj.EqType, 'MMSE')
                Eq = conj(GridH) ./ (GridH.*conj(GridH) + GridVarVals);
            end
            
            EqGrid = obj.NrRxGrid .* Eq;
            EqVarVals = GridVarVals .* (Eq.*conj(Eq));            
    end
    function FreqResp = GetFreqResp(obj, SigTx, SigRx, ChanType)
    % Calculation channel frequency response with transmitted and received
    % signals aligned in time
        FreqResp = ones(obj.NFFT, obj.L);
        if strcmp(ChanType, 'AWGN')
            % Nothing to do - transfer coefficient is always equal to 1
        elseif strcmp(ChanType, 'Fading')
            % Getting spectrums of transmitted and received signal and
            % then calculate channel transfer characteristics
                Shift = 0;
                for k = 1 : obj.L
                    Shift = Shift + obj.CPLengths(k);
                    SigSymbTx = SigTx(Shift + (1:obj.NFFT));
                    SigSymbRx = SigRx(Shift + (1:obj.NFFT));
                    Shift = Shift + obj.NFFT;
    
                    SpectrumTx = fftshift(fft(SigSymbTx));
                    SpectrumTx(SpectrumTx == 0) = eps;
                    SpectrumRx = fftshift(fft(SigSymbRx));
    
                    FreqResp(:, k) = SpectrumRx ./ SpectrumTx;
                end
        end
        % % Drawing frequency responses
        % Buf = FreqResp(obj.FirstSC + (0 : obj.K - 1), :);
        % for k = 1:size(FreqResp, 2)
        %     figure;
        %         subplot(2, 1, 1); plot(abs(FreqResp(:,k)));
        %         subplot(2, 1, 2); plot(unwrap(angle(FreqResp(:,k)))/pi);
        %     figure;
        %         subplot(2, 1, 1); plot(abs(Buf(:,k)));
        %         subplot(2, 1, 2); plot(unwrap(angle(Buf(:,k)))/pi);
        % end
    end
end
end
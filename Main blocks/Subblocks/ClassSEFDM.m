classdef ClassSEFDM < handle
    % Class of SEFDM signal generation and reception
    %
    % Vulnerabilities:
    %   - ZP shold be less than Trunc/Insert part;
    
    properties % Constants
        % Alpha precision - power of 10
        AlphaFreqPrec = 0.1;
    end
    properties % Variable parameters of the current object (with default
        % values)
        % Frequency compression factor
        AlphaFreq = 1;
        % Time compression factor
        AlphaTime = 0.9;
        % Equalizer type: 'ZF' || 'MMSE'
        EqType = 'ZF';
        % SEFDM making type: Oscill / Trunc / Insert
        FormType = 'Trunc';
        % Is successive interference cancellation
        isSIC = 0; % influence on ClassSch.MaxLDPCIterCount 
        % Number of SIC iterations
        NumSICiter = 1; % influence on ClassSch.MaxLDPCIterCount 
        % Do we need to recalc var for demap according to interference
        isRecalcVar = 1;
        % Do we need to recalc var only on first iter and then return to init
        % value
        IsOnlyFirstVarRecalc = 0;
        % Do we need to recalc var in SIC every iteration
        isSICvarRecalc = 0;
        % 2 neighbours approach - for alpha 0.5 < alpha < 1.0
        Beta = 0.9; % 0 ... 1
        isNeigCorr = 0;
        
        % Unsupported for Oscill
        CPtype = 'OFDM'; % OFDM|NOFDM - from end of OFDM|NOFDM
        SymbAdd = 'CP'; % CP - prefix |ZP - postfix
    end
    properties % Variable parameters or calculated parameters of other
        % objects (without default values)
        % From SchSource
        CellCarrier; % object
        NrSchConfig; % object
        NrSchIndices;
        NrDmrsIndices;
        NrDmrsSymbols;
        
        % For SIC
        % (De)Encoder - object
        NrSch;
        % (De)Mapper - object
        NrSML;
    end
    properties % Calculated parameters of the current object (without default
        % values)
        % OFDM configuration parameters
        % NR structure with parameters needed for OFDM generation
        CellOFDMInfo;
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
        % SEFDM configuration parameters
        % Number of samples per symbol
        NumSampPerSymb;
        % Exponents for oscillator for 'Oscill' type [tones x samples]
        Exponents;
        % Number of truncated and non-truncated samples for formation SEFDM
        % symbol by 'Trunc' method
        NumTruncSamples;
        % Number of inserted zeros for 'Insert' type
        NumInsZer;
        % Frequency interpolation ratio for AlphaPrec
        FreqInterp4AlphaPrec;
        % Correlation matrix minus I
        Gamma;
        % Additional matrix to var recalc
        AddVarGrid;
        
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
        function obj = ClassSEFDM(Params)
            
            % String with the name of the function in which an error occurred
            % while validating the parameter value
            funcName = 'ClassSEFDM.constructor';
            % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'SEFDM')
                PsSEFDM = Params.SEFDM;
            else
                PsSEFDM = [];
            end
            
            if isfield(PsSEFDM, 'AlphaFreq')
                obj.AlphaFreq = PsSEFDM.AlphaFreq;
            end
            ValidateAttributes(obj.AlphaFreq, {'double'}, {'scalar', '>', 0, ...
                '<=', 1, 'finite'}, funcName, 'AlphaFreq');
            if isfield(PsSEFDM, 'AlphaTime')
                obj.AlphaTime = PsSEFDM.AlphaTime;
            end
            ValidateAttributes(obj.AlphaTime, {'double'}, {'scalar', '>', 0, ...
                '<=', 1, 'finite'}, funcName, 'AlphaTime');
            if isfield(PsSEFDM, 'EqType')
                obj.EqType = PsSEFDM.EqType;
            end
            obj.EqType = ValidateString(obj.EqType, {'ZF', 'MMSE'}, ...
                funcName, 'EqType');
            if isfield(PsSEFDM, 'FormType')
                obj.FormType = PsSEFDM.FormType;
            end
            obj.FormType = ValidateString(obj.FormType, {'Oscill', 'Trunc', ...
                'Insert'}, funcName, 'FormType');
            if isfield(PsSEFDM, 'isSIC')
                obj.isSIC = PsSEFDM.isSIC;
            end
            ValidateAttributes(obj.isSIC, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'isSIC');
            if isfield(PsSEFDM, 'NumSICiter')
                obj.NumSICiter = PsSEFDM.NumSICiter;
            end
            ValidateAttributes(obj.NumSICiter, {'double'}, {'scalar', '>', 0, ...
                '<=', 10, 'finite'}, funcName, 'NumSICiter');
            if isfield(PsSEFDM, 'isRecalcVar')
                obj.isRecalcVar = PsSEFDM.isRecalcVar;
            end
            ValidateAttributes(obj.isRecalcVar, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'isRecalcVar');
            if isfield(PsSEFDM, 'IsOnlyFirstVarRecalc')
                obj.IsOnlyFirstVarRecalc = PsSEFDM.IsOnlyFirstVarRecalc;
            end
            ValidateAttributes(obj.IsOnlyFirstVarRecalc, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'IsOnlyFirstVarRecalc');
            if isfield(PsSEFDM, 'isSICvarRecalc')
                obj.isSICvarRecalc = PsSEFDM.isSICvarRecalc;
            end
            ValidateAttributes(obj.isSICvarRecalc, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'isSICvarRecalc');
            if isfield(PsSEFDM, 'Beta')
                obj.Beta = PsSEFDM.Beta;
            end
            ValidateAttributes(obj.Beta, {'double'}, {'scalar', '>=', 0, ...
                '<=', 1, 'finite'}, funcName, 'Beta');
            if isfield(PsSEFDM, 'isNeigCorr')
                obj.isNeigCorr = PsSEFDM.isNeigCorr;
            end
            ValidateAttributes(obj.isNeigCorr, {'double', 'logical'},...
                {'scalar', 'binary'}, funcName, 'isNeigCorr');
            if isfield(PsSEFDM, 'CPtype')
                obj.CPtype = PsSEFDM.CPtype;
            end
            ValidateString(obj.CPtype, {'OFDM', 'NOFDM'}, funcName, 'CPtype');
            if isfield(PsSEFDM, 'SymbAdd')
                obj.SymbAdd = PsSEFDM.SymbAdd;
            end
            ValidateString(obj.SymbAdd, {'CP', 'ZP'}, funcName, 'SymbAdd');
            
            if ~((obj.AlphaFreq == 1) || (obj.AlphaTime == 1))
                error('Either AlphaFreq or AlphaTime should be 1!');
            end
            
        end
        function CalcIntParams(obj) %#ok<MANU>
        end
        function CalcIntParamsFromExtParams(obj, Objs)
            
            % Getting parameters from other objects
            obj.CellCarrier = Objs.SchSource.CellCarrier;
            obj.NrSchConfig = Objs.SchSource.NrSchConfig;
            obj.NrSchIndices = Objs.SchSource.NrSchIndices;
            obj.NrDmrsIndices = Objs.SchSource.NrDmrsIndices;
            obj.NrDmrsSymbols = Objs.SchSource.NrDmrsSymbols;
            
            if obj.isSIC
                obj.NrSch = Objs.NrSch;
                obj.NrSML = Objs.NrSML;
            end
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
            
            switch obj.FormType
                case 'Oscill'
                    obj.Exponents = zeros(obj.NFFT); % [f x t]
                    for n = 1 : obj.NFFT
                        obj.Exponents(:, n) = exp(1j*2*pi * obj.AlphaFreq * ...
                            (-obj.NFFT / 2 : obj.NFFT / 2 - 1) / ...
                            obj.NFFT * (n - 1));
                    end
                case 'Trunc'
                    obj.NumTruncSamples = round(obj.NFFT * (1 - obj.AlphaTime));
                case 'Insert'
                    obj.NumInsZer = round(obj.NFFT * (1 - obj.AlphaFreq) / ...
                        obj.AlphaFreq);
            end
            obj.FreqInterp4AlphaPrec = 1 / obj.AlphaFreqPrec;
            
            StartSymbNum = Objs.SchSource.StartSymbNum; % 1
            NumPdschSymbPerSlot = Objs.SchSource.NumPdschSymbPerSlot; % 13
            % DataPartFirstSample etc
            LastSymbNum = StartSymbNum + NumPdschSymbPerSlot -1;
            
            if strcmp(obj.FormType, 'Oscill') || strcmp(obj.FormType, 'Insert')
                obj.NumSampPerSymb = obj.NFFT;
            elseif strcmp(obj.FormType, 'Trunc')
                obj.NumSampPerSymb = obj.NFFT - obj.NumTruncSamples;
            end
            
            % As either AlphaFreq or AlphaTime should be 1, then result:
            Alpha = obj.AlphaFreq * obj.AlphaTime;
            % Form ref matrix for correlation matrix (Lambda) calculation
            RefMat4Lambda = cumsum(ones(obj.NFFT));
            RefMat4Lambda = RefMat4Lambda - RefMat4Lambda.';
            % Calc Lambda - from [Hedaia]
            Lambda = exp(1i* pi * Alpha * RefMat4Lambda) .* ...
                exp(-1i* pi * Alpha * RefMat4Lambda / obj.NFFT).*...
                sinc(Alpha * RefMat4Lambda) ./ ...
                sinc(Alpha * RefMat4Lambda / obj.NFFT);
            
            obj.Gamma = Lambda - diag(ones(1, obj.NFFT));
            
            obj.AddVarGrid = [zeros(obj.FirstSC - 1, obj.L); ...
                ones(obj.K, obj.L); ...
                zeros(obj.NFFT - (obj.FirstSC + obj.K - 1), obj.L)];
            obj.AddVarGrid = (obj.AddVarGrid.' * abs(obj.Gamma).^2).';
            obj.AddVarGrid = obj.AddVarGrid(obj.FirstSC + (0 : obj.K - 1), :);
            
            obj.DataPartFirstSample = sum(obj.CPLengths(1 : ...
                StartSymbNum)) + obj.NumSampPerSymb * StartSymbNum + 1;
            obj.DataPartLastSample = sum(obj.CPLengths(1 : ...
                LastSymbNum + 1)) + obj.NumSampPerSymb * (LastSymbNum + 1);
            
            obj.NumAddSamplesInDataPart = sum(obj.CPLengths( ...
                StartSymbNum + 1 : LastSymbNum + 1));
            
            % FirstAndLastSamplesInSymbol
            obj.FirstAndLastSamplesInSymbol = zeros( ...
                NumPdschSymbPerSlot, 2);
            for k = 1:NumPdschSymbPerSlot
                NumSymsBefore = StartSymbNum + k - 1;
                obj.FirstAndLastSamplesInSymbol(k, 1) = sum( ...
                    obj.CPLengths(1 : NumSymsBefore) ) + obj.NumSampPerSymb * ...
                    NumSymsBefore + 1;
                obj.FirstAndLastSamplesInSymbol(k, 2) = ...
                    obj.FirstAndLastSamplesInSymbol(k, 1) - 1 + ...
                    obj.CPLengths(NumSymsBefore + 1) + obj.NumSampPerSymb;
            end
            
            % SigSamplesNums2GetFreqResp - we will use the first sample of each
            % OFDM-symbol
            obj.SigSamplesNums2GetFreqResp = zeros(1, obj.L);
            Shift = 0;
            for k = 1:obj.L
                Shift = Shift + obj.CPLengths(k);
                obj.SigSamplesNums2GetFreqResp(k) = Shift + 1;
                Shift = Shift + obj.NumSampPerSymb;
            end
        end
        function DeleteSubObjs(obj)
            % Removing of internal (sub) objects
            delete(obj.CellCarrier);
            delete(obj.NrSchConfig);
            delete(obj.NrSch);
            delete(obj.NrSML);
        end
        function OutData = StepTx(obj, InData)
            % Put InData on NrTxGrid
            obj.NrTxGrid(obj.NrSchIndices) = InData;
            
            switch obj.FormType
                case 'Oscill'
                    % Make full grid
                    FullGrid = [ ...
                        zeros(obj.FirstSC - 1, obj.L); ...
                        obj.NrTxGrid; ...
                        zeros(obj.NFFT - (obj.FirstSC + obj.K - 1), obj.L)];
                    
                    PostMod = obj.SEFDMoscillators(FullGrid, 'Tx');
                    
                    % Compose signal
                    Sig = zeros(obj.NFFT * obj.L + sum(obj.CPLengths), 1);
                    Shift = 0;
                    for k = 1 : obj.L
                        CPL = obj.CPLengths(k);
                        % Prepare OFDM-Symbol and its CP
                        SigSymbol = PostMod(:, k);
                        SigCP = SigSymbol(end - CPL + 1 : end);
                        % Insert CP
                        Sig(Shift + (1:CPL)) = SigCP;
                        Shift = Shift + CPL;
                        % Insert OFDM-Symbol
                        Sig(Shift + (1:obj.NFFT)) = SigSymbol;
                        Shift = Shift + obj.NFFT;
                    end
                case 'Trunc'
                    OFDMsymbs = OFDMmodulation(obj);
                case 'Insert'
                    OFDMsymbs = OFDMmodulation(obj, true);
            end
            Sig = zeros(obj.NumSampPerSymb * obj.L + sum(obj.CPLengths), 1);
            
            Shift = 0;
            for k = 1 : obj.L
                SymbAddLen = obj.CPLengths(k);
                Add = zeros(SymbAddLen, 1);
                if strcmp(obj.SymbAdd, 'CP')
                    if strcmp(obj.CPtype, 'OFDM')
                        CPpos = size(OFDMsymbs, 1) - SymbAddLen + 1;
                    elseif strcmp(obj.CPtype, 'NOFDM')
                        CPpos = obj.NumSampPerSymb - SymbAddLen + 1;
                    end
                    Add = OFDMsymbs(CPpos + (0 : SymbAddLen-1), k);
                end
                
                Symb = OFDMsymbs(1 : obj.NumSampPerSymb, k);
                if strcmp(obj.SymbAdd, 'CP')
                    Symb = [Add; Symb]; %#ok<AGROW>
                elseif strcmp(obj.SymbAdd, 'ZP')
                    Symb = [Symb; Add]; %#ok<AGROW>
                end
                
                Sig(Shift + (1 : length(Symb))) = Symb;
                Shift = Shift + length(Symb);
            end
            % Output
            OutData = Sig;
        end
        function [OutData, VarVals] = StepRx(obj, InData, InstChan)
            Shift = 0;
            if strcmp(obj.FormType, 'Trunc')
                Nfft = obj.NFFT;
            elseif strcmp(obj.FormType, 'Insert')
                Nfft = obj.NFFT + obj.NumInsZer;
            end
            DemIn = zeros(Nfft, obj.L);
            for k = 1 : obj.L
                if strcmp(obj.SymbAdd, 'CP')
                    Shift = Shift + obj.CPLengths(k);
                    if strcmp(obj.FormType, 'Trunc')
                        NpadZer = obj.NumTruncSamples;
                    elseif strcmp(obj.FormType, 'Insert')
                        NpadZer = obj.NumInsZer;
                    end
                    SymbLen = obj.NumSampPerSymb;
                elseif strcmp(obj.SymbAdd, 'ZP')
                    if strcmp(obj.FormType, 'Trunc')
                        NpadZer = obj.NumTruncSamples - obj.CPLengths(k);
                    elseif strcmp(obj.FormType, 'Insert')
                        NpadZer = obj.NumInsZer - obj.CPLengths(k);
                    end
                    SymbLen = obj.NumSampPerSymb + obj.CPLengths(k);
                end
                
                DemIn(:, k) = [InData(Shift + (1 : SymbLen)); zeros(NpadZer, 1)];
                Shift = Shift + SymbLen;
            end
            
            switch obj.FormType
                case 'Oscill'
                    % Remove cyclic prefixes
                    PostCPGrid = zeros(obj.NFFT, obj.L);
                    Shift = 0;
                    for k = 1 : obj.L
                        Shift = Shift + obj.CPLengths(k);
                        SigSymbol = InData(Shift + (1 : obj.NFFT));
                        PostCPGrid(:, k) = SigSymbol;
                        Shift = Shift + obj.NFFT;
                    end
                    
                    FullGrid = obj.SEFDMoscillators(PostCPGrid, 'Rx');
                    
                    % Get only used subcarriers
                    obj.NrRxGrid = FullGrid(obj.FirstSC + (0 : obj.K - 1), :);
                case 'Trunc'
                    OFDMdemodulation(obj, DemIn);
                case 'Insert'
                    OFDMdemodulation(obj, DemIn, true);
            end
            
            % Equalizing
            if strcmp(obj.FormType, 'Oscill') || strcmp(obj.FormType, 'Insert')
                H = InstChan.FreqResp;
                % Make new freq net of freq response of channel
                for k = 1 : obj.L
                    TimeResp = ifft(ifftshift(H(:, k)));
                    TimeResp = [TimeResp; zeros(9 * obj.NFFT, 1)]; %#ok<AGROW>
                    FreqResp = fftshift(fft(TimeResp));
                    if strcmp(obj.FormType, 'Oscill')
                        LeftBorderIdx = obj.FreqInterp4AlphaPrec/2 * obj.NFFT - ...
                            obj.AlphaFreq * obj.FreqInterp4AlphaPrec * ...
                            obj.NFFT / 2 + 1;
                        RightBorderIdx = obj.FreqInterp4AlphaPrec/2 * obj.NFFT + ...
                            obj.AlphaFreq * obj.FreqInterp4AlphaPrec * obj.NFFT / 2;
                    elseif strcmp(obj.FormType, 'Insert')
                        LeftBorderIdx = 1;
                        RightBorderIdx = obj.AlphaFreq * obj.FreqInterp4AlphaPrec * ...
                            obj.NFFT;
                    end
                    Indexes = LeftBorderIdx : obj.AlphaFreq * obj.FreqInterp4AlphaPrec ...
                        : RightBorderIdx;
                    InstChan.FreqResp(:, k) = FreqResp(Indexes);
                end
            end
            [EqGrid, EqVarVals] = Equalizer(obj, InstChan);
            
            % Get results from data subcarriers
            EqOutData = EqGrid(obj.NrSchIndices);
            if obj.isRecalcVar
                EqVarVals = EqVarVals + obj.AddVarGrid;
            end
            VarVals = EqVarVals(obj.NrSchIndices);
            
            if obj.isNeigCorr
                ModEqVarVals = EqVarVals;
                ReEqVarVals = real(EqVarVals);
                ImEqVarVals = imag(EqVarVals);
                for Isym = 1 : size(EqVarVals, 2)
                    for Isamp = 2 : size(EqVarVals, 1)-1
                        ModEqVarVals(Isamp, Isym) = sqrt(ReEqVarVals(Isamp-1, Isym) * ...
                            ReEqVarVals(Isamp+1, Isym)) / obj.Gamma(1, 2) * ...
                            obj.Beta + ReEqVarVals(Isamp, Isym) * (1 - obj.Beta) + ...
                            ...
                            1i * (sqrt(ImEqVarVals(Isamp-1, Isym) * ...
                            ImEqVarVals(Isamp+1, Isym)) / obj.Gamma(1, 2) * ...
                            obj.Beta + ImEqVarVals(Isamp, Isym) * (1 - obj.Beta));
                    end
                end
            end
            
            if obj.isSIC
                for k = 1 : obj.NumSICiter
                    DemapOutData = obj.NrSML.StepRx(EqOutData, VarVals);
                    [DecodOutData, ~] = obj.NrSch.StepRx(DemapOutData);
                    
                    CodedOutData = obj.NrSch.StepTx(DecodOutData);
                    MapData = obj.NrSML.StepTx(CodedOutData);
                    
                    obj.NrTxGrid(obj.NrSchIndices) = MapData;
                    FullGrid = [zeros(obj.FirstSC - 1, obj.L); ...
                        obj.NrTxGrid; ...
                        zeros(obj.NFFT - (obj.FirstSC + obj.K - 1), obj.L)];
                    InterfData = (FullGrid.' * obj.Gamma).';
                    obj.NrRxGrid = InterfData(obj.FirstSC + (0 : obj.K - 1), :);
                    EqOutData = EqOutData - obj.NrRxGrid(obj.NrSchIndices);
                    
                    if obj.isSICvarRecalc
                        EqVarVals = EqVarVals + obj.AddVarGrid;
                    end
                    
                    if obj.isRecalcVar && obj.IsOnlyFirstVarRecalc && k == 1
                        EqVarVals = EqVarVals - obj.AddVarGrid;
                        VarVals = EqVarVals(obj.NrSchIndices);
                    end
                end
            end
            
            OutData = EqOutData;
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
        function OutData = SEFDMoscillators(obj, InData, Type)
            % Function performs location data on different SEFDM subcarriers.
            % Input:
            %   - Type: Tx / Rx;
            % Output:
            %   - OutData [NFFT x L].
            
            OutData = zeros(size(InData));
            UsedMults = obj.Exponents;
            
            if strcmp(Type, 'Tx')
                UsedMults = UsedMults / obj.NFFT;
            elseif strcmp(Type, 'Rx')
                UsedMults = UsedMults';
            else
                error('Wrong type for SEFDMoscillator!\n');
            end
            
            for k = 1 : obj.L
                OutData(:, k) = (InData(:, k).' * UsedMults).';
            end
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
        end
    end
end

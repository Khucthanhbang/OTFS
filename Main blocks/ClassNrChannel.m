classdef ClassNrChannel < handle
% Class performs simulation of processing signal through the fading channel
%
properties % Constants
end
properties % Variable parameters of the current object (with default
        % values)
    % Channel type: AWGN | Fading
        Type = 'Fading'; % influence on ClassBERRuler.h2dBMaxStep
    % Fading type: '' | 'EPA' | 'EVA' | 'ETU' | 'MBSFN'
    % Only taken into account when Type == 'Fading'
        FadingType = 'EVA';
    % Maximum Doppler shift for all rays
        MaxDopShift = 300;
    % The number samples to repeat before and after the signal as cyclic
    % prefix and postfix
        NumSamples2ExpandSig = 500;
    % Do we need to take into account the cyclic prefix, zero postfix etc.
    % while calculating SNR. Thus if true then SNR required is higher.
        isAccountForAddsInDataPart = 1;
    % It is supposed that the frequency response estimation is noisy. As
    % example it can be obtained with ZF technique: Srx = Mu*Stx + Noise ->
    % MuEst = Srx / Stx = Mu + Noise / Stx. Var of MuEst can be decreased
    % by integration, smoothing etc. Thus estimation is converted to
    % MuEst = Mu + K * Noise / Stx. Normally K <= 1. For simplicity we dont
    % care about the amplitude of  1 / Stx thus assuming it is equal to 1.
    % FreqRespNoiseAttenuation is the K in dB. If K = 0 (FreqRespNoise-
    % Attenuation = -inf) then we have true estimation (not noisy).
        FreqRespNoiseAttenuation = -inf;
end
properties % Variable parameters or calculated parameters of other
        % objects (without default values)
    % From SchSource
        NFFT;
    % From NrSch
        NumBits4Pb;
    % From Sig
        DataPartFirstSample;
        DataPartLastSample;
        NumAddSamplesInDataPart;
        SigSamplesNums2GetFreqResp;
end
properties % Calculated parameters of the current object (without default
        % values)
    % Data constelaltion points
        Const;
    % Mean power per modulation symbol
        Ps;
    % Mean power per data bit 
        Pb;
    % Sample rate, Hz
        Fs;
    % SubObject implementing fading channel
        hChan;
    % Path delays for all rays, seconds
        PathDelays;
    % Average path gains, dB
        AveragePathGains;
end
methods
    function obj = ClassNrChannel(Params)
    % Constructor. For all variable parameters of the current object, one
    % need to check for the presence of a user defined value in Setup. If
    % it is present then it should replace the default value. Each variable
    % parameters value of the current object should be checked for
    % validity. It is also wise to cross-check parameters.

        % String with the name of the function in which an error occurred
        % while validating the parameter value
            funcName = 'ClassNrChannel.constructor';

        % To shorten the code, select the required field(s) from Params
            if isfield(Params, 'NrChannel')
                NrChannel = Params.NrChannel;
            else
                NrChannel = [];
            end
        % Type
            if isfield(NrChannel, 'Type')
                obj.Type = NrChannel.Type;
            end
            obj.Type = ValidateString(obj.Type, {'AWGN', ...
                'Fading'}, funcName, 'Type');
        % FadingType
            if isfield(NrChannel, 'FadingType')
                obj.FadingType = NrChannel.FadingType;
            end
            obj.FadingType = ValidateString(obj.FadingType, {'', ...
                'EPA', 'EVA', 'ETU', 'MBSFN'}, funcName, 'FadingType');
        % MaxDopShift
            if isfield(NrChannel, 'MaxDopShift')
                obj.MaxDopShift = NrChannel.MaxDopShift;
            end
            ValidateAttributes(obj.MaxDopShift, {'double'}, ...
                {'scalar', '>=', 0, 'finite'}, funcName, 'MaxDopShift');
        % NumSamples2ExpandSig
            if isfield(NrChannel, 'NumSamples2ExpandSig')
                obj.NumSamples2ExpandSig = NrChannel.NumSamples2ExpandSig;
            end
            ValidateAttributes(obj.NumSamples2ExpandSig, {'double'}, ...
                {'scalar', '>=', 0, 'finite'}, funcName, ...
                'NumSamples2ExpandSig');
        % isAccountForAddsInDataPart
            if isfield(NrChannel, 'isAccountForAddsInDataPart')
                obj.isAccountForAddsInDataPart = ...
                    NrChannel.isAccountForAddsInDataPart;
            end
            ValidateAttributes(obj.isAccountForAddsInDataPart, ...
                {'double', 'logical'}, {'scalar', 'binary'}, funcName, ...
                'isAccountForAddsInDataPart');
        % FreqRespNoiseAttenuation
            if isfield(NrChannel, 'FreqRespNoiseAttenuation')
                obj.FreqRespNoiseAttenuation = ...
                    NrChannel.FreqRespNoiseAttenuation;
            end
            ValidateAttributes(obj.FreqRespNoiseAttenuation, {'double'},...
                {'scalar'}, funcName, 'FreqRespNoiseAttenuation');
    end
    function CalcIntParams(obj)
    % Determining the values of calculated variables that do not require
    % information about the values of parameters from other objects
    
        % Setting multipath profile parameters
            switch obj.FadingType
                case '' % Single-ray channel
                    obj.PathDelays = 0;
                    obj.AveragePathGains = 0;
                case 'EPA' % Extended Pedestrian A model
                    obj.PathDelays = [0, 30, 70, 90, 110, 190, 410] * ...
                        (10^-9);
                    obj.AveragePathGains = [0.0, -1.0, -2.0, -3.0, ...
                        -8.0, -17.2, -20.8];
                case 'EVA' % Extended Vehicular A model
                    obj.PathDelays = [0, 30, 150, 310, 370, 710, 1090, ...
                        1730, 2510] * (10^-9);
                    obj.AveragePathGains = [0.0, -1.5, -1.4, -3.6, ...
                        -0.6, -9.1, -7.0, -12.0, -16.9];
                case 'ETU' % Extended Typical Urban model
                    obj.PathDelays = [0, 50, 120, 200, 230, 500, 1600, ...
                        2300, 5000] * (10^-9);
                    obj.AveragePathGains = [-1.0, -1.0, -1.0, 0.0, 0.0, ...
                        0.0, -3.0, -5.0, -7.0];
                case 'MBSFN'
                    obj.PathDelays = [0, 30, 150, 310, 370, 1090, ...
                        12490, 12520, 12640, 12800, 12860, 13580, ...
                        27490, 27520, 27640, 27800, 27860, 28580] * ...
                        (10^-9);
                    obj.AveragePathGains = [0.0, -1.5, -1.4, -3.6, ...
                        -0.6, -7.0, -10.0, -11.5, -11.4, -13.6, -10.6, ...
                        -17.0, -20.0, -21.5, -21.4, -23.6, -20.6, -27.0];
            end
    end
    function CalcIntParamsFromExtParams(obj, Objs)
    % Determining the values of calculated variables that do require
    % information about the values of variables from other objects
        
        % Get/calculate parameters from other objects
            % SchSource
                CellOFDMInfo = nrOFDMInfo(Objs.SchSource.CellCarrier);
                obj.NFFT = CellOFDMInfo.Nfft;
                NumBitsPerModSymb = Objs.SchSource.PdschModNumBits;
                CellSCS = Objs.SchSource.CellSCS;
            % Let's define signal constellation points
            % Modulation order
                M = 2^NumBitsPerModSymb;
            % Bits to modulate
                TempBits = de2bi(0 : M-1, NumBitsPerModSymb).';
            % From nrSymbolModulate
                % Generate symbol order vector
                    symbolOrdVector = nr5g.internal. ...
                        generateSymbolOrderVector(NumBitsPerModSymb);
                % Modulate the bits
                    obj.Const = comm.internal.qam.modulate(TempBits(:), ...
                        M, 'custom', symbolOrdVector, 1, 1, []);
            % end From nrSymbolModulate
            % Ps - mean power per modulation symbol
                obj.Ps = mean((abs(obj.Const)).^2);
                obj.Ps = obj.Ps / obj.NFFT; % due to transmission from freq to
                % time domain with ifft
            % Pb - mean power per data bit
            % Mean power per modulation bit
                obj.Pb = obj.Ps / NumBitsPerModSymb;
            % Take into account the code rate -> data bit
                if Objs.NrSch.isTransparent == 0
                    obj.Pb = obj.Pb / Objs.SchSource.PdschCodeRate;
                end
            % NrSch
                obj.NumBits4Pb = Objs.NrSch.NumBits4Pb;
            % Sig
                obj.DataPartFirstSample = ...
                    Objs.Sig.CurSig.DataPartFirstSample;
                obj.DataPartLastSample = ...
                    Objs.Sig.CurSig.DataPartLastSample;
                obj.NumAddSamplesInDataPart = ...
                    Objs.Sig.CurSig.NumAddSamplesInDataPart;
                obj.SigSamplesNums2GetFreqResp = ...
                    Objs.Sig.CurSig.SigSamplesNums2GetFreqResp;
                
        % Fs - sample rate
            obj.Fs = obj.NFFT * CellSCS;
        % Preparing SubObject implementing fading channel
            if strcmp(obj.Type, 'Fading')
                obj.hChan = comm.RayleighChannel( ...
                    'SampleRate', obj.Fs, ...
                    'PathDelays', obj.PathDelays, ...
                    'AveragePathGains', obj.AveragePathGains, ...
                    'NormalizePathGains', 1, ...
                    'MaximumDopplerShift', obj.MaxDopShift, ...
                    'DopplerSpectrum', doppler('Jakes'), ...
                    'RandomStream', 'Global stream', ...
                    'PathGainsOutputPort', 1 ...
                );
            end
    end
    function DeleteSubObjs(obj)
    % Removing of internal (sub) objects
        if isobject(obj.hChan)
            delete(obj.hChan);
        end
    end
    function [OutData, InstChan] = Step(obj, Objs, InData, h2dB )
    % Function implements passing signal through the fading channel
        % Reset the channel to improve statistic
            if strcmp(obj.Type, 'Fading')
                reset(obj.hChan);
            end

%         % Calculating the energy of signal by dt, i.e. cumulative power of
%         % signal
%             CumSigPower = sum(InData(obj.DataPartFirstSample : ...
%                 obj.DataPartLastSample) .* conj(InData( ...
%                 obj.DataPartFirstSample : obj.DataPartLastSample)));
%         % Taking into account cyclic prefix, zero postfix etc.
%             if ~obj.isAccountForAddsInDataPart
%                 CumSigPower = CumSigPower * (obj.DataPartLastSample - ...
%                 obj.DataPartFirstSample - obj.NumAddSamplesInDataPart) /...
%                 (obj.DataPartLastSample - ...
%                 obj.DataPartFirstSample);
%             end
        % Calculating mean power per data bit - Pb
%             Pb = CumSigPower / obj.NumBits4Pb;
            
        % Expanding signal by cyclic repetition
            Len = length(InData);
            ExpInData = [ ...
                InData(end - obj.NumSamples2ExpandSig + 1 : end);
                InData;
                InData(1 : obj.NumSamples2ExpandSig)];
        % Passing signal through the channel
            if strcmp(obj.Type, 'AWGN')
                SigRx = ExpInData;
                PathGains = ones(length(SigRx), 1);
            else
                [SigRx, PathGains] = step(obj.hChan, ExpInData);
            end
            
        % Define the channel delay
            if strcmp(obj.Type, 'AWGN')
                ChanDelay = 0;
                ChanFilterCoeffs = 1;
            else
                hChanInfo = info(obj.hChan);
                ChanDelay = hChanInfo.ChannelFilterDelay;
                ChanFilterCoeffs = hChanInfo.ChannelFilterCoefficients.';
                % ChanFilterCoeffs - is a (M x Np) array, where Np is a
                % number of paths. Each column contains FIR filter response
                % to provide fractional delayed input signal for the path.
                % By default the first path is aligned with the signal
                % samples thus the first column contain ChanDelay zeros at
                % the begining, then one and again zeros till the end
            end
        % Drop the channel delay
            SigRx = SigRx(ChanDelay + 1 : end);
        % Undo expand signal
            SigRx = SigRx(obj.NumSamples2ExpandSig + (1 : Len));
        switch Objs.Sig.Type 
            case 'OFDM'
                % Getting channel transfer characteristics for each Signal Symbol
                % Memory allocation
                    FreqResp = zeros(obj.NFFT, length( ...
                        obj.SigSamplesNums2GetFreqResp));
                    Resp = zeros(obj.NFFT, 1);
                % Define M and check for exceeding the NFFT value
                    M = size(ChanFilterCoeffs, 1);
                    if M > obj.NFFT
                        M = obj.NFFT;
                        ChanFilterCoeffs = ChanFilterCoeffs(1 : M, :);
                    end
                % Iterate by each Sig symbol
                for k = 1:length(obj.SigSamplesNums2GetFreqResp)
                    % Define the start and the end signal samples numbers to
                    % perform fractional delaying of 1 (delta pulse) in each
                    % path
                        Pos1 = obj.SigSamplesNums2GetFreqResp(k) + ...
                            obj.NumSamples2ExpandSig;
                        Pos2 = Pos1 + M -1;
                    % Calculation the response of channel to the delta pulse
                    % placed to the Pos1
                        Resp(1 : M) = sum(PathGains(Pos1 : Pos2, :) .* ...
                            ChanFilterCoeffs, 2);
                        Resp = circshift(Resp, -ChanDelay, 1);
                    % Getting frequency response
                        FreqResp(:, k) = fftshift(fft(Resp));
                        Resp = zeros(obj.NFFT, 1);
                end
            case 'OTFS'
                % Frequency Response
                FreqResp = ...
                    Objs.Sig.CurSig.GetFreqRespForOTFS(SigRx, obj.Type);
        end

        % Use the code below to compare in debug mode the frequency
        % response estimation from FreqResp with the one obtaiend as
        % division of the signal after Channel by the signal before
        % channel. It works for OFDM. For this purpose one needs to add
        % objSig as the fourth parameter for the current function and
        % Objs.Sig as the additionl parameter for the Objs.NrChannel.Step
        % in the LoopFun of Main right after the 'if Ruler.isBER'
            % % Getting channel transfer characteristics for each Signal
            % % Symbol
            %     FreqResp1 = objSig.CurSig.GetFreqResp(InData, SigRx, ... 
            %         obj.Type);
            % 
            % close all;
            % for k = 1:14
            %     figure;
            %         subplot(2, 1, 1);
            %             plot(abs(FreqResp1(:,k)), 'b');
            %             hold on;
            %             plot(abs(FreqResp(:,k)), 'r');
            %             ylim([0, 1]);
            %         subplot(2, 1, 2);
            %             plot(angle(FreqResp1(:,k))/pi, 'b');
            %             hold on;
            %             plot(angle(FreqResp(:,k))/pi, 'r');
            % end            
            
        % Prepare the AWGN
            Var = obj.Pb * 10^(-h2dB/10);
            Noise = randn(length(SigRx), 2) * sqrt(Var/2) * [1; 1j];

        % Add noise to the Signal
            OutData = SigRx + Noise;
            
        % Prepare InstChan
            InstChan.Var = Var * obj.NFFT; % Don't forget to multiply Var
                % by obj.NFFT since this value will be used in freq domain!
            InstChan.FreqResp = FreqResp;
            
            % Imitation of noising the channel estimation
                if obj.FreqRespNoiseAttenuation ~= -inf
                    EstNoise = sqrt(InstChan.Var/2) * ...
                        (randn(size(FreqResp)) + 1j*randn(size(FreqResp)));
                    Buf = 10^(obj.FreqRespNoiseAttenuation/10);
                    InstChan.FreqResp = InstChan.FreqResp + Buf*EstNoise;
                end
    end
end
end
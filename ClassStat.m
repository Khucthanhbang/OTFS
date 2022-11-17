classdef ClassStat < handle
% Inner model object. Here is no parameters to be changed by user!

    properties (SetAccess = private)
        % Parameters for accumulating statictic about BER
            NumTrBits;   % the number of transmitted bits
            NumTrFrames; % the number of transmitted frames
            NumErBits;   % the number of erroneous bits
            NumErFrames; % the number of erroneous frames
        % Parameters for accumulating statictic about PAPR
            NumCaptPAPRSamples; % the number of signal samples captured
                % for each PAPR value
            NumPAPRSamples; % the number of observed signal samples
            NumPAPRFrames;  % the number of observed frames
            NumPAPRBits;    % the number of observed bits
        % Parameters from Ruler
            isBER;
            PAPRType;
            PAPRVals;
    end
    methods
        function obj = ClassStat(Ruler) % Constructor
            % Copying parameters from Ruler
                obj.isBER    = Ruler.isBER;
                obj.PAPRType = Ruler.PAPRType;
                obj.PAPRVals = Ruler.PAPRVals;
            % Initialization of parameters for BER statistic
                obj.NumTrBits   = 0;
                obj.NumTrFrames = 0;
                obj.NumErBits   = 0;
                obj.NumErFrames = 0;
            % Initialization of parameters for PAPR statistic
                obj.NumCaptPAPRSamples = zeros(size(obj.PAPRVals));
                obj.NumPAPRSamples = 0;
                obj.NumPAPRFrames  = 0;
                obj.NumPAPRBits    = 0;
        end
        function Step(obj, Frame, Sig)
            % Updating statistic
                if obj.isBER
                    obj.NumTrBits   = obj.NumTrBits   + ...
                        length(Frame.TxData);
                    obj.NumTrFrames = obj.NumTrFrames + 1;
                    Buf = sum(Frame.TxData ~= Frame.RxData);
                    obj.NumErBits   = obj.NumErBits   + Buf;
                    obj.NumErFrames = obj.NumErFrames + sign(Buf);
                else
                    FirstAndLastSamplesInSymbol = ...
                        Sig.CurSig.FirstAndLastSamplesInSymbol;
                    % Get instant power values
                        Ps = Frame.TxSignal .* conj(Frame.TxSignal);
                    % Iterate by the each Sig-symbol
                    for n = 1:size(FirstAndLastSamplesInSymbol, 1)
                        % Pick out current needed Sig-symbol
                            BufPs = Ps( ...
                                FirstAndLastSamplesInSymbol(n, 1) : ...
                                FirstAndLastSamplesInSymbol(n, 2));
                        % Normalization and dB conversion
                            BufPs = 10 * log10(BufPs / mean(BufPs));
                        % For PAPRType == 2 we should left only one value
                            if obj.PAPRType == 2
                                BufPs = max(BufPs);
                            end
                        % Updating statistic itself
                            if obj.PAPRType == 1
                                for k = 1:length(obj.PAPRVals)
                                    obj.NumCaptPAPRSamples(k) = ...
                                        obj.NumCaptPAPRSamples(k) + ...
                                        sum(BufPs > obj.PAPRVals(k));
                                end
                            else
                                Poses = BufPs > obj.PAPRVals;
                                obj.NumCaptPAPRSamples(Poses) = ...
                                    obj.NumCaptPAPRSamples(Poses) + 1;
                            end
                            obj.NumPAPRSamples = obj.NumPAPRSamples + ...
                                length(BufPs);
                    end
                    obj.NumPAPRFrames  = obj.NumPAPRFrames + 1;
                    obj.NumPAPRBits    = obj.NumPAPRBits + ...
                        length(Frame.TxData);
                end
        end
        function Reset(obj)
            obj.NumTrBits   = 0;
            obj.NumTrFrames = 0;
            obj.NumErBits   = 0;
            obj.NumErFrames = 0;
            
            obj.NumCaptPAPRSamples = zeros(size(obj.PAPRVals));
            obj.NumPAPRSamples = 0;
            obj.NumPAPRFrames  = 0;
            obj.NumPAPRBits    = 0;
        end            
    end
end
function DrawSpectrum(Sig, FreqFact, Method, IsNormMaxPSD)
% This function performs drawing of spectrum using different methods,
% represented in: https://www.mathworks.com/help/signal/ref/spectrum.html
%
% Method: Periodogram | Welch

    if nargin < 1
        error ('Map Sig!');
    end
    if nargin < 2
        FreqFact = 1;
    end
    if nargin < 3
        Method = 'Welch';
    end
    if nargin < 4
        IsNormMaxPSD = false;
    end
    
    switch Method
        case 'Periodogram'
            [PSD, f] = periodogram(Sig, [], [], [], 'centered');
        case 'Welch'
            [PSD, f] = pwelch(Sig, [], [], [], [], 'centered');
    end

    if IsNormMaxPSD
        PSD = PSD / max(PSD);
    end
    
    figure('WindowStyle', 'docked');
    plot(f*FreqFact, 10*log10(PSD));
end


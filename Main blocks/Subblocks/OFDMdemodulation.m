function OFDMdemodulation(obj, InData, isInsZer)
% Manual OFDM De-Modulation
%
% isInsZer - is zeros insertion for 'Insert' SEFDM shaping type

    if nargin == 2
        isInsZer = false;
    end

    % FFT
        PostFFTGrid = fft(InData, [], 1); 
    % FFT shift
        FullGrid = fftshift(PostFFTGrid, 1);
        if isInsZer
            FullGrid(end-obj.NumInsZer+1 : end, :) = [];
        end
    % Get only used subcarriers
        obj.NrRxGrid = FullGrid(obj.FirstSC + (0 : obj.K - 1), :);
end


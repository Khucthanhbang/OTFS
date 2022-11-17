function OutData = OFDMmodulation(obj, isInsZer)
% Manual OFDM Modulation
%
% isInsZer - is zeros insertion for 'Insert' SEFDM shaping type

    if nargin == 1
        isInsZer = false;
    end

    % Make full grid
        FullGrid = [ ...
            zeros(obj.FirstSC - 1, obj.L); ...
            obj.NrTxGrid; ...
            zeros(obj.NFFT - (obj.FirstSC + obj.K - 1), obj.L)];
    if isInsZer
        FullGrid = [FullGrid; zeros(obj.NumInsZer, obj.L)];
    end
    % IFFT shift 
        ShiftedFullGrid = ifftshift(FullGrid, 1);
    % IFFT
        OutData = ifft(ShiftedFullGrid, [], 1);
end


function [out, info] = fecEncode(bits, type)
%FECENCODE Forward error correction encoder.
bits = bits(:);
info = struct('type', type, 'nIn', numel(bits), 'g', [], 'K', 0);
switch type
    case 'None'
        out = bits;
    case 'Hamming (7,4)'
        pad = mod(-numel(bits), 4);
        out = hammingEncode([bits; zeros(pad, 1)]);
    otherwise
        [info.g, info.K] = convSpec(type);
        out = convEncode(bits, info.g, info.K);
end
end

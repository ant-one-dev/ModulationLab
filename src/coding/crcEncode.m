function [out, info] = crcEncode(bits, type, frameLen)
%CRCENCODE Split BITS in frames of FRAMELEN bits and append a CRC to each.
[poly, r] = crcPoly(type);
info = struct('type', type, 'r', r, 'poly', poly, 'frameLen', frameLen, ...
    'nInfo', numel(bits), 'nFrames', 0, 'pad', 0);
bits = bits(:);
if r == 0
    out = bits;
    return
end
pad = mod(-numel(bits), frameLen);
F = reshape([bits; zeros(pad, 1)], frameLen, []);
out = reshape([F; crcCompute(F, poly)], [], 1);
info.nFrames = size(F, 2);
info.pad = pad;
end

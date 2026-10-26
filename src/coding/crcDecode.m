function [out, fail] = crcDecode(bits, info)
%CRCDECODE Check and remove the CRC of every frame.
%   fail(i) is true when the CRC of frame i does not match.
bits = bits(:);
if info.r == 0
    out = bits;
    fail = false(0, 1);
    return
end
F = reshape(bits, info.frameLen + info.r, []);
data = F(1:info.frameLen, :);
fail = any(crcCompute(data, info.poly) ~= F(info.frameLen+1:end, :), 1).';
out = data(:);
out = out(1:info.nInfo);
end

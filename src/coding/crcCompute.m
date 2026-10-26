function rem = crcCompute(F, poly)
%CRCCOMPUTE CRC remainder of every column of the bit matrix F.
%   Shift-register implementation (initial value 0, no reflection), vectorised
%   over the frames. Returns an r-by-nFrames matrix.
nF = size(F, 2);
r = numel(poly);
p = logical(poly(:).');
reg = false(nF, r);
for i = 1:size(F, 1)
    fb = xor(reg(:, 1), F(i, :).' > 0);   % MSB out XOR incoming bit
    reg = [reg(:, 2:end), false(nF, 1)];  % shift left
    reg(fb, :) = xor(reg(fb, :), p);      % subtract the generator
end
rem = double(reg.');
end

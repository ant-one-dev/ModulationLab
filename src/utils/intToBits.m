function bits = intToBits(v, k)
%INTTOBITS Convert integers to k-bit words (MSB first), concatenated in a column.
v = double(v(:));
B = rem(floor(v ./ 2.^(k-1:-1:0)), 2);   % one row per integer
bits = reshape(B.', [], 1);
end

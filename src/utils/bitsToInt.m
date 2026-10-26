function v = bitsToInt(bits, k)
%BITSTOINT Group bits by k (MSB first) and convert each group to an integer.
%   v = BITSTOINT(bits, k) returns a column vector of integers in [0, 2^k-1].
v = reshape(double(bits(:)), k, []).' * (2.^(k-1:-1:0)).';
end

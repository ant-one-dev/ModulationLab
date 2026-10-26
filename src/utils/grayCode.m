function g = grayCode(n)
%GRAYCODE Binary-reflected Gray code of the non-negative integers n.
g = bitxor(n, bitshift(n, -1));
end

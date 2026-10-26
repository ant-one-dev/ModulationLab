function px = bitsToImage(bits, sz)
%BITSTOIMAGE Inverse of IMAGETOBITS for an image of size SZ (e.g. [64 64 3]).
n = prod(sz);
v = reshape(bits(1:n*8), 8, []).' * (2.^(7:-1:0)).';
px = uint8(reshape(v, sz));
end

function out = hammingEncode(bits)
%HAMMINGENCODE Systematic Hamming (7,4) code: [d1 d2 d3 d4 p1 p2 p3].
P = hammingParity();
D = reshape(bits(:), 4, []).';
C = [D, mod(D * P, 2)];
out = reshape(C.', [], 1);
end

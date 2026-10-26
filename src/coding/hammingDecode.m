function out = hammingDecode(bits)
%HAMMINGDECODE Syndrome decoding of the Hamming (7,4) code (corrects 1 error).
P = hammingParity();
H = [P.', eye(3)];                       % parity-check matrix (3x7)
R = reshape(bits(:), 7, []).';
syn = mod(R * H.', 2) * [4; 2; 1];       % syndrome as an integer
pos = zeros(8, 1);
pos(H.' * [4; 2; 1] + 1) = 1:7;          % syndrome -> position of the error
p = pos(syn + 1);
e = find(p > 0);
idx = sub2ind(size(R), e, p(e));
R(idx) = 1 - R(idx);
out = reshape(R(:, 1:4).', [], 1);
end

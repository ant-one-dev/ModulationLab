function out = convEncode(bits, g, K)
%CONVENCODE Rate-1/2 convolutional encoder, terminated with K-1 zero bits.
u = [bits(:); zeros(K-1, 1)];
n = numel(u);
o1 = mod(conv(u, g(1, :).'), 2);
o2 = mod(conv(u, g(2, :).'), 2);
out = reshape([o1(1:n), o2(1:n)].', [], 1);
end

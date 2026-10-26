function ber = unionBoundBER(name, g)
%UNIONBOUNDBER Union bound on the BER of any labelled constellation.
%   BER <= 1/(M k) * sum_i sum_j d_H(i,j) * Q(|s_i - s_j| / sqrt(2 N0))
[pts, labels] = getConstellation(name);
[M, k] = size(labels);
D = abs(pts - pts.');
H = labels * (1 - labels).' + (1 - labels) * labels.';   % Hamming distances
ber = zeros(size(g));
for i = 1:numel(g)
    N0 = 1 / (k * g(i));                                 % Es = 1
    ber(i) = sum(sum(H .* qfun(D / sqrt(2*N0)))) / (M * k);
end
end

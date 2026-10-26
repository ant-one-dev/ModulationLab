function out = viterbiDecode(bits, g, K)
%VITERBIDECODE Hard-decision Viterbi decoder for a terminated rate-1/2 code.
%   State = last K-1 input bits, most recent one as MSB.
nS = 2^(K-1);
half = 2^(K-2);

% Output (as integer 0..3) for every (previous state, input bit)
outIdx = zeros(nS, 2);
for p = 0:nS-1
    for u = 0:1
        reg = [u, bitget(p, K-1:-1:1)];
        o = mod(g * reg.', 2);
        outIdx(p+1, u+1) = 2*o(1) + o(2);
    end
end

% Each next state ns has two predecessors p0 / p1, both with input u = MSB(ns)
ns = (0:nS-1).';
uIn = floor(ns / half);
p0 = 2 * mod(ns, half);
p1 = p0 + 1;
o0 = outIdx(sub2ind([nS 2], p0+1, uIn+1));
o1 = outIdx(sub2ind([nS 2], p1+1, uIn+1));

R = reshape(bits(:), 2, []).';
T = size(R, 1);
rInt = 2*R(:, 1) + R(:, 2);
BM = [0 1 1 2; 1 0 2 1; 1 2 0 1; 2 1 1 0];   % Hamming distance table

pm = inf(nS, 1);
pm(1) = 0;                                    % encoder starts in state 0
dec = false(T, nS);
for t = 1:T
    bm = BM(rInt(t)+1, :).';
    m0 = pm(p0+1) + bm(o0+1);
    m1 = pm(p1+1) + bm(o1+1);
    c = m1 < m0;
    pm = m0;
    pm(c) = m1(c);
    pm = pm - min(pm);
    dec(t, :) = c.';
end

% Traceback from state 0 (code is terminated)
s = 0;
u = zeros(T, 1);
for t = T:-1:1
    u(t) = floor(s / half);
    s = 2*mod(s, half) + dec(t, s+1);
end
out = u(1:T-(K-1));
end

function [bw, fl, fh] = occupiedBandwidth(P, f, oneSided)
%OCCUPIEDBANDWIDTH Bandwidth containing 99 % of the power.
%   For real baseband signals (oneSided = true) the one-sided bandwidth is
%   returned, otherwise the full two-sided (RF) bandwidth.
P = P(:); f = f(:);
if oneSided
    pos = f >= 0;
    c = cumsum(P(pos)) / sum(P(pos));
    fp = f(pos);
    fh = fp(find(c >= 0.99, 1));
    fl = -fh;
    bw = fh;
else
    c = cumsum(P) / sum(P);
    fl = f(find(c >= 0.005, 1));
    fh = f(find(c >= 0.995, 1));
    bw = fh - fl;
end
end

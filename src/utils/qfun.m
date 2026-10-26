function y = qfun(x)
%QFUN Gaussian tail function Q(x) = P(N(0,1) > x).
y = 0.5 * erfc(x / sqrt(2));
end

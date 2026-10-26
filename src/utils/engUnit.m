function [scale, prefix] = engUnit(x)
%ENGUNIT Engineering prefix for the magnitude of x.
%   x / scale lies in [1, 1000) and prefix is 'p', 'n', 'µ', 'm', '', 'k',
%   'M' or 'G'. Example: [s, p] = engUnit(2.5e-4) gives s = 1e-6, p = 'µ'.
prefixes = {'p', 'n', 'µ', 'm', '', 'k', 'M', 'G'};
if x == 0 || ~isfinite(x)
    e = 0;
else
    e = min(max(floor(log10(abs(x)) / 3) * 3, -12), 9);
end
scale = 10^e;
prefix = prefixes{e/3 + 5};
end

function s = fmtEng(x, unit)
%FMTENG Format a value with an engineering prefix, e.g. fmtEng(9600, 'Hz') -> '9.6 kHz'.
[scale, prefix] = engUnit(x);
s = sprintf('%.3g %s%s', x / scale, prefix, unit);
end

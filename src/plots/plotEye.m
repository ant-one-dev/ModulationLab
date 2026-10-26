function plotEye(ax, res, nTraces)
%PLOTEYE Eye diagram over two symbol periods, centred on the sampling instant.
if nargin < 3, nTraces = 150; end
c = commsColors();
d = res.demod;
s = real(d.eyeSig(:));
P = d.eyePeriod;
cen = round(d.eyeCenters(:));
cen = cen(cen - P >= 1 & cen + P <= numel(s));
skip = min(8, max(0, numel(cen) - nTraces));       % skip filter start-up
cen = cen(skip+1 : min(numel(cen), skip + nTraces));
off = (-P:P).';
Y = s(cen.' + off);
Ts = P / res.mod.samplesPerBit / res.cfg.Rb;    % symbol period in seconds
[sc, pre] = engUnit(Ts);
X = repmat(off / P * Ts / sc, 1, size(Y, 2));
X(end+1, :) = NaN;
Y(end+1, :) = NaN;

cla(ax);
legend(ax, 'off');
plot(ax, X(:), Y(:), 'Color', [c.rx 0.3], 'LineWidth', 0.8);
xline(ax, 0, '--', 'Color', c.tx, 'LineWidth', 1.2);
grid(ax, 'on');
box(ax, 'on');
ax.XLim = [-1 1] * Ts / sc;
q = sort(Y(~isnan(Y)));                        % robust limits (ignore outliers)
if ~isempty(q)
    lo = q(max(1, round(0.003*numel(q))));
    hi = q(max(1, round(0.997*numel(q))));
    pad = 0.1 * max(hi - lo, eps);
    ax.YLim = [lo - pad, hi + pad];
end
xlabel(ax, sprintf('Time (%ss)   -   T_s = %s', pre, fmtEng(Ts, 's')));
ylabel(ax, d.eyeLabel);
title(ax, sprintf('Eye diagram  -  %s', res.scheme.name));
end

function plotConstellation(ax, res, showLabels)
%PLOTCONSTELLATION Constellation (linear schemes), decision variable
%   histogram (line codes) or I/Q trajectory (FSK).
if nargin < 3, showLabels = false; end
c = commsColors();
sch = res.scheme;
cla(ax);
legend(ax, 'off');
axis(ax, 'normal');
ax.XLimMode = 'auto'; ax.YLimMode = 'auto';
ax.DataAspectRatioMode = 'auto';
hold(ax, 'on');
switch sch.kind
    case 'linear'
        rs = res.demod.rxSym;
        n = min(numel(rs), 3000);
        scatter(ax, real(rs(1:n)), imag(rs(1:n)), 9, c.rx, 'filled', ...
            'MarkerFaceAlpha', 0.35, 'MarkerEdgeColor', 'none');
        pts = res.mod.pts;
        scatter(ax, real(pts), imag(pts), 55, c.tx, 'filled', ...
            'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 0.8);
        if showLabels
            lbl = cellstr(char(res.mod.labels + '0'));
            text(ax, real(pts), imag(pts) + 0.09*max(abs(pts)), lbl, ...
                'HorizontalAlignment', 'center', 'FontSize', 8, 'FontWeight', 'bold');
        end
        lim = 1.45 * max(abs(pts));
        axis(ax, [-lim lim -lim lim]);
        ax.DataAspectRatio = [1 1 1];
        xlabel(ax, 'In-phase (I)');
        ylabel(ax, 'Quadrature (Q)');
        title(ax, sprintf('Constellation  -  %s', sch.name));
    case 'line'
        z = res.demod.z;
        histogram(ax, z, 80, 'Normalization', 'pdf', 'FaceColor', c.rx, ...
            'EdgeColor', 'none', 'FaceAlpha', 0.7);
        for v = res.demod.levels
            xline(ax, v, '-', 'Color', c.tx, 'LineWidth', 2);
        end
        for v = res.demod.thresholds
            xline(ax, v, '--', 'Threshold', 'Color', c.grid, 'LineWidth', 1.2, ...
                'LabelVerticalAlignment', 'top');
        end
        xlabel(ax, 'Decision variable z');
        ylabel(ax, 'Probability density');
        title(ax, sprintf('Decision variable  -  %s', sch.name));
    otherwise   % fsk
        n = min(numel(res.rx), 40 * res.mod.sps);
        r = res.demod.rxFilt;                      % after the receive low-pass
        plot(ax, real(r(1:n)), imag(r(1:n)), 'Color', [c.rx 0.45]);
        plot(ax, real(res.tx(1:n)), imag(res.tx(1:n)), 'Color', c.tx, 'LineWidth', 2);
        lim = 2;
        axis(ax, [-lim lim -lim lim]);
        ax.DataAspectRatio = [1 1 1];
        xlabel(ax, 'In-phase (I)');
        ylabel(ax, 'Quadrature (Q)');
        title(ax, sprintf('I/Q trajectory (constant envelope)  -  %s', sch.name));
end
hold(ax, 'off');
grid(ax, 'on');
box(ax, 'on');
end

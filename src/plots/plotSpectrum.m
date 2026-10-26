function bw = plotSpectrum(ax, res)
%PLOTSPECTRUM Normalised PSD of the transmitted signal, with the 99 % band.
%   The frequency axis is in Hz, from the channel bit rate res.cfg.Rb.
%   Returns the 99 % occupied bandwidth in units of R_b.
c = commsColors();
isLine = strcmp(res.scheme.kind, 'line');
[P, f] = welchPSD(res.tx, 1024);
f = f * res.mod.samplesPerBit;
[bw, fl, fh] = occupiedBandwidth(P, f, isLine);
Pdb = 10*log10(P / max(P) + 1e-12);

fmax = min([4, max(f), max(1, 2*bw)]);          % zoom on the occupied band
Rb = res.cfg.Rb;
[sc, pre] = engUnit(fmax * Rb);
u = Rb / sc;                                     % (f / R_b) -> displayed unit

cla(ax);
legend(ax, 'off');
hold(ax, 'on');
patch(ax, [fl fh fh fl]*u, [-70 -70 5 5], c.tx, 'FaceAlpha', 0.10, 'EdgeColor', 'none');
plot(ax, f*u, Pdb, 'Color', c.tx, 'LineWidth', 1.3);
hold(ax, 'off');
grid(ax, 'on');
box(ax, 'on');
ax.XLim = [-fmax fmax]*u;
ax.YLim = [-60 5];
xlabel(ax, sprintf('Frequency (%sHz)   -   R_b = %s', pre, fmtEng(Rb, 'bit/s')));
ylabel(ax, 'Normalised PSD (dB)');
if isLine
    title(ax, sprintf('Power spectral density  -  B_{99%%} = %s (one-sided)', fmtEng(bw*Rb, 'Hz')));
else
    title(ax, sprintf('Power spectral density  -  B_{99%%} = %s', fmtEng(bw*Rb, 'Hz')));
end
end

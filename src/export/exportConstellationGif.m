function exportConstellationGif(file, cfg, bits, seed, EbN0list, progressFcn)
%EXPORTCONSTELLATIONGIF Animated GIF: constellation + eye diagram while the
%   Eb/N0 goes through EBN0LIST. The same noise realisation is reused for
%   every frame, so only the noise level changes.
if nargin < 5 || isempty(EbN0list), EbN0list = [20:-1:0, 1:20]; end
if nargin < 6, progressFcn = []; end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 470]);
cleanup = onCleanup(@() close(fig));
try
    theme(fig, 'light');          % R2025a+: do not inherit a dark desktop theme
catch
end
tl = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
ax1 = nexttile(tl);
ax2 = nexttile(tl);

frames = {};
for i = 1:numel(EbN0list)
    if ~isempty(progressFcn) && ~progressFcn(i, numel(EbN0list)), break; end
    cfg.EbN0dB = EbN0list(i);
    rng(seed, 'twister');
    res = runChain(cfg, bits);
    plotConstellation(ax1, res, false);
    plotEye(ax2, res);
    title(tl, sprintf('%s   |   E_b/N_0 = %d dB   |   BER = %.2e', ...
        res.scheme.name, round(cfg.EbN0dB), res.ber), 'FontWeight', 'bold');
    drawnow;
    frames{i} = print(fig, '-RGBImage', '-r90'); %#ok<AGROW>
end
writeGif(file, frames, 0.18);
end

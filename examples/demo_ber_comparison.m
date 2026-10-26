function demo_ber_comparison(outFile)
%DEMO_BER_COMPARISON Use the ModulationLab engine without the GUI.
%   Simulated vs theoretical BER of several modulations, plus the gain of
%   the K=7 convolutional code on QPSK (4-PSK).
%
%   demo_ber_comparison                       -> opens a figure
%   demo_ber_comparison('docs/ber_curves.png') -> also saves it
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root, 'src')));
rng(1);

eb = 0:1:16;
schemes = {'2-PSK', '8-PSK', '16-QAM', '16-APSK', '64-QAM', '4-ASK'};
col = lines(numel(schemes) + 1);
nBits = 1e5;

fig = figure('Name', 'BER comparison', 'Position', [100 100 900 560], ...
    'Visible', matlab.lang.OnOffSwitchState(nargin == 0));
ax = axes(fig);
hold(ax, 'on');
for i = 1:numel(schemes)
    cfg = defaultConfig(struct('scheme', schemes{i}));
    ber = simulateBER(cfg, eb, nBits);
    ber(ber == 0) = NaN;
    semilogy(ax, eb, ber, 'o-', 'Color', col(i, :), 'MarkerFaceColor', col(i, :), ...
        'MarkerSize', 4, 'LineWidth', 1.4, 'DisplayName', schemes{i});
    ef = linspace(eb(1), eb(end), 200);
    semilogy(ax, ef, theoreticalBER(schemes{i}, ef), ':', 'Color', col(i, :), ...
        'LineWidth', 1.2, 'HandleVisibility', 'off');
    fprintf('%s done\n', schemes{i});
end

cfg = defaultConfig(struct('scheme', '4-PSK', 'fec', 'Conv. K=7 (171,133) + Viterbi'));
ber = simulateBER(cfg, eb, nBits);
ber(ber == 0) = NaN;
semilogy(ax, eb, ber, 's-', 'Color', col(end, :), 'MarkerFaceColor', col(end, :), ...
    'MarkerSize', 5, 'LineWidth', 2.2, 'DisplayName', 'QPSK + conv. K=7 (Viterbi)');

ax.YScale = 'log';
grid(ax, 'on'); ax.YMinorGrid = 'on'; box(ax, 'on');
ylim(ax, [1e-5 1]);
xlim(ax, [eb(1) eb(end)]);
xlabel(ax, 'E_b/N_0 per information bit (dB)');
ylabel(ax, 'Bit error rate');
title(ax, 'Simulated (markers) vs theory (dotted), AWGN channel');
legend(ax, 'Location', 'southwest');

if nargin > 0
    exportgraphics(fig, outFile, 'Resolution', 130);
    close(fig);
    fprintf('saved %s\n', outFile);
end
end

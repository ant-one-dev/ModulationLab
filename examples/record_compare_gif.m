function T = record_compare_gif(outFile, schemes, codes, ebList, n)
%RECORD_COMPARE_GIF Grid GIF: the Mona Lisa received with several
%   modulations (rows) and channel codes (columns), under the same Eb/N0.
%   One frame per Eb/N0 value. Also returns / prints a table of the
%   percentage of wrong pixels for every combination.
%
%   record_compare_gif                       -> docs/compare_demo.gif
%   T = record_compare_gif(file, {'4-PSK','16-QAM'}, {'None','Hamming (7,4)'}, 12:-2:0, 64)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root, 'src')));
if nargin < 1 || isempty(outFile), outFile = fullfile(root, 'docs', 'compare_demo.gif'); end
if nargin < 2 || isempty(schemes), schemes = {'4-ASK', '4-FSK', '4-PSK', '16-QAM', '64-QAM'}; end
if nargin < 3 || isempty(codes)
    codes = {'None', 'Hamming (7,4)', 'Conv. K=3 (7,5) + Viterbi', 'Conv. K=7 (171,133) + Viterbi'};
end
if nargin < 4 || isempty(ebList), ebList = 16:-1:2; end
if nargin < 5 || isempty(n), n = 64; end

px = prepareImage(loadDefaultImage(), n);
bits = imageToBits(px);
nR = numel(schemes); nC = numel(codes);
colNames = regexprep(codes, {' \+ Viterbi', 'Conv\. ', '^None$'}, {'', 'Conv ', 'Uncoded'});

fig = figure('Visible', 'off', 'Color', [0.11 0.11 0.12], 'Position', [50 50 190*nC + 90, 190*nR + 90]);
cleanup = onCleanup(@() close(fig));
try theme(fig, 'dark'); catch, end
tl = tiledlayout(fig, nR, nC, 'TileSpacing', 'tight', 'Padding', 'compact');
fg = [0.92 0.92 0.92];
wrongPct = zeros(numel(ebList), nR, nC);
frames = cell(1, numel(ebList));

for i = 1:numel(ebList)
    for r = 1:nR
        for c = 1:nC
            cfg = defaultConfig(struct('scheme', schemes{r}, 'EbN0dB', ebList(i), 'fec', codes{c}));
            rng(1, 'twister');                         % same noise pattern every frame
            res = runChain(cfg, bits);
            rx = bitsToImage(res.rxBits, size(px));
            w = 100 * mean(any(rx ~= px, 3), 'all');
            wrongPct(i, r, c) = w;

            ax = nexttile(tl, (r-1)*nC + c);
            cla(ax);
            image(ax, rx);
            axis(ax, 'image');
            ax.XTick = []; ax.YTick = [];
            ax.XColor = 'none'; ax.YColor = 'none';
            if w == 0
                lbl = 'perfect';
            elseif w < 0.1
                lbl = '< 0.1 % wrong px';
            else
                lbl = sprintf('%.1f %% wrong px', w);
            end
            title(ax, lbl, 'Color', fg, 'FontWeight', 'normal', 'FontSize', 9);
            if c == 1
                ylabel(ax, schemes{r}, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 11, 'Visible', 'on');
            end
            if r == nR
                xlabel(ax, colNames{c}, 'Color', fg, 'FontWeight', 'bold', 'FontSize', 10, 'Visible', 'on');
            end
        end
    end
    title(tl, sprintf('Same noise, different modulation & coding   |   E_b/N_0 = %g dB', ebList(i)), ...
        'Color', fg, 'FontWeight', 'bold', 'FontSize', 13);
    drawnow;
    frames{i} = print(fig, '-RGBImage', '-r96');
    fprintf('frame %2d/%d  Eb/N0 = %g dB\n', i, numel(ebList), ebList(i));
end
writeGif(outFile, frames, 0.5, 1.6);
info = dir(outFile);
fprintf('%s: %.2f MB\n', outFile, info.bytes / 2^20);

% table: wrong pixels (%) for every combination
T = struct('EbN0dB', num2cell(ebList(:)));
fprintf('\nWrong pixels (%%) for a %dx%d image\n', n, n);
fprintf('%-8s %-8s', 'Eb/N0', 'scheme');
fprintf(' %14s', colNames{:});
fprintf('\n');
for i = 1:numel(ebList)
    for r = 1:nR
        fprintf('%-8g %-8s', ebList(i), schemes{r});
        fprintf(' %14.2f', squeeze(wrongPct(i, r, :)));
        fprintf('\n');
    end
end
for i = 1:numel(ebList)
    T(i).wrongPct = squeeze(wrongPct(i, :, :));
end
end

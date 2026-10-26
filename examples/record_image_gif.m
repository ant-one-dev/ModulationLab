function record_image_gif(outFile, scheme, ebList, sizes)
%RECORD_IMAGE_GIF Animated GIF of the received Mona Lisa as the noise grows.
%   Top row: received image for each resolution. Bottom row: wrong pixels
%   highlighted in salmon. One frame per Eb/N0 value; the same noise realisation is reused, so
%   only the noise level changes from frame to frame.
%
%   record_image_gif                                   -> docs/image_demo.gif
%   record_image_gif(file, '16-QAM', 16:-1:2, [32 64 128])
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root, 'src')));
if nargin < 1 || isempty(outFile), outFile = fullfile(root, 'docs', 'image_demo.gif'); end
if nargin < 2 || isempty(scheme),  scheme = '4-PSK'; end
if nargin < 3 || isempty(ebList),  ebList = 12:-1:0; end
if nargin < 4 || isempty(sizes),   sizes = [32 64 128]; end

img = loadDefaultImage();
nS = numel(sizes);
px = cell(1, nS); bits = cell(1, nS);
for j = 1:nS
    px{j} = prepareImage(img, sizes(j));
    bits{j} = imageToBits(px{j});
end

fig = figure('Visible', 'off', 'Color', [0.11 0.11 0.12], 'Position', [100 100 300*nS 640]);
cleanup = onCleanup(@() close(fig));
try theme(fig, 'dark'); catch, end
frames = cell(1, numel(ebList));
tl = tiledlayout(fig, 2, nS, 'TileSpacing', 'compact', 'Padding', 'compact');
fg = [0.92 0.92 0.92];

for i = 1:numel(ebList)
    cfg = defaultConfig(struct('scheme', scheme, 'EbN0dB', ebList(i)));
    berTot = 0; nTot = 0;
    for j = 1:nS
        rng(1, 'twister');                       % same noise pattern every frame
        res = runChain(cfg, bits{j});
        berTot = berTot + res.nErr; nTot = nTot + res.nInfo;
        rx = bitsToImage(res.rxBits, size(px{j}));
        wrong = any(rx ~= px{j}, 3);
        mse = mean((double(px{j}(:)) - double(rx(:))).^2);
        if mse == 0, q = 'perfect'; else, q = sprintf('PSNR %.0f dB', 10*log10(255^2/mse)); end

        ax = nexttile(tl, j); cla(ax);
        image(ax, rx); axis(ax, 'image', 'off');
        title(ax, sprintf('%d x %d px  (%d bits)', sizes(j), sizes(j), res.nInfo), 'Color', fg);

        % wrong pixels in salmon over a dimmed copy of the original
        base = uint8(0.3 * double(mean(px{j}, 3)));
        map = repmat(base, 1, 1, 3);
        r = map(:, :, 1); g = map(:, :, 2); b = map(:, :, 3);
        r(wrong) = 230; g(wrong) = 140; b(wrong) = 110;   % soft salmon
        ax = nexttile(tl, nS + j); cla(ax);
        image(ax, cat(3, r, g, b)); axis(ax, 'image', 'off');
        title(ax, sprintf('%d wrong px (%.0f %%), %s', nnz(wrong), 100*nnz(wrong)/numel(wrong), q), ...
            'Color', fg, 'FontWeight', 'normal');
    end
    if berTot == 0, berTxt = '0 error'; else, berTxt = sprintf('%.1e', berTot / nTot); end
    title(tl, sprintf('%s   |   E_b/N_0 = %g dB   |   BER = %s', scheme, ebList(i), berTxt), ...
        'Color', fg, 'FontWeight', 'bold', 'FontSize', 14);
    drawnow;

    frames{i} = print(fig, '-RGBImage', '-r96');
    fprintf('frame %2d/%d  Eb/N0 = %g dB\n', i, numel(ebList), ebList(i));
end

writeGif(outFile, frames, 0.5, 1.6);
info = dir(outFile);
fprintf('%s: %.2f MB\n', outFile, info.bytes / 2^20);
end

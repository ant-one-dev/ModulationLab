function writeGif(file, frames, delay, holdDelay)
%WRITEGIF Write RGB frames to an animated GIF with one shared palette.
%   MATLAB reuses the palette of the first frame for the following ones, so
%   the palette is built from the first, middle and last frames together.
%   holdDelay (optional) is used for the first and last frames.
if nargin < 4, holdDelay = delay; end
n = numel(frames);
if n == 0, return; end                   % export cancelled before the first frame
pick = unique([1, ceil(n/2), n]);
[~, cmap] = rgb2ind(cat(1, frames{pick}), 255, 'nodither');
for i = 1:n
    A = rgb2ind(frames{i}, cmap, 'nodither');
    d = delay;
    if i == 1 || i == n, d = holdDelay; end
    if i == 1
        imwrite(A, cmap, file, 'gif', 'LoopCount', Inf, 'DelayTime', d);
    else
        imwrite(A, cmap, file, 'gif', 'WriteMode', 'append', 'DelayTime', d);
    end
end
end

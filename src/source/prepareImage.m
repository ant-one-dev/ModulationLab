function px = prepareImage(img, n)
%PREPAREIMAGE Colour (RGB), centre-cropped, n-by-n-by-3 uint8 version of an image.
%   Grayscale images are replicated on the 3 channels.
if size(img, 3) == 1
    img = repmat(img, 1, 1, 3);
end
img = img(:, :, 1:3);
if isinteger(img) && ~isa(img, 'uint8')          % e.g. 16-bit PNG
    img = uint8(255 * double(img) / double(intmax(class(img))));
elseif ~isinteger(img)                             % double / logical in [0, 1]
    img = uint8(255 * double(img));
end
[H, W, ~] = size(img);
s = min(H, W);
r0 = floor((H - s)/2); c0 = floor((W - s)/2);
img = img(r0 + (1:s), c0 + (1:s), :);
idx = round(linspace(1, s, n));              % nearest-neighbour resize
px = img(idx, idx, :);
end

function img = loadDefaultImage()
%LOADDEFAULTIMAGE Reference image: Mona Lisa (Leonardo da Vinci, public domain).
%   Source: Wikimedia Commons, "Mona Lisa, by Leonardo da Vinci, from C2RMF
%   retouched.jpg". Falls back to a synthetic colour pattern if missing.
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
f = fullfile(root, 'assets', 'mona_lisa.png');
if isfile(f)
    img = imread(f);
    return
end
[X, Y] = meshgrid(linspace(-1, 1, 256));
img = uint8(255 * cat(3, 0.5 + 0.5*sin(6*X), 0.5 + 0.5*cos(6*Y), (X.^2 + Y.^2) < 0.4));
end

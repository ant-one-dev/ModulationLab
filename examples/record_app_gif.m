function record_app_gif(outFile, scheme, ebList, width)
%RECORD_APP_GIF Animated GIF of the whole ModulationLab window while Eb/N0
%   goes down: constellation, eye diagram and image degrade together.
%
%   record_app_gif                          -> docs/app_demo.gif, 16-QAM
%   record_app_gif(file, '8-PSK', 20:-1:0, 960)
%
%   Keep the result under 5 MB for LinkedIn: reduce WIDTH or the number of
%   Eb/N0 steps if needed.
root = fileparts(fileparts(mfilename('fullpath')));
if nargin < 1 || isempty(outFile), outFile = fullfile(root, 'docs', 'app_demo.gif'); end
if nargin < 2 || isempty(scheme),  scheme = '16-QAM'; end
if nargin < 3 || isempty(ebList),  ebList = 18:-1:1; end
if nargin < 4 || isempty(width),   width = 960; end

addpath(root);
app = ModulationLab;
cleanup = onCleanup(@() delete(app));
fig = app.UIFigure;
drawnow; pause(1);

% select the scheme through the GUI controls
sch = getScheme(scheme);
dd = findall(fig, 'Type', 'uidropdown');
pick = @(item) dd(arrayfun(@(d) any(strcmp(d.Items, item)), dd));
fam = pick('Phase (PSK)');
fam.Value = sch.family;
fam.ValueChangedFcn(fam, []);
dd = findall(fig, 'Type', 'uidropdown');
pick = @(item) dd(arrayfun(@(d) any(strcmp(d.Items, item)), dd));
template = regexprep(scheme, '^\d+-(ASK|PSK)$', 'M-$1');
s = pick(template);
s.Value = template;
s.ValueChangedFcn(s, []);
if ~strcmp(template, scheme)
    o = pick(num2str(sch.M));
    o = o(~arrayfun(@(d) any(strcmp(d.Items, template)), o));
    o.Value = sch.M;
    o.ValueChangedFcn(o, []);
end
ebEdit = findall(fig, 'Type', 'uinumericeditfield');
ebEdit = ebEdit(arrayfun(@(e) e.Limits(1) == -10 && e.Limits(2) == 40, ebEdit));

% fill the BER panel once (simulated vs theory) so it is not empty
b = findall(fig, 'Type', 'uibutton', 'Text', 'Run BER');
b.ButtonPushedFcn(b, []);

% 1) capture every frame to disk (keeps memory low)
frameDir = tempname;
mkdir(frameDir);
for i = 1:numel(ebList)
    ebEdit.Value = ebList(i);
    ebEdit.ValueChangedFcn(ebEdit, []);
    drawnow; pause(0.3);
    exportapp(fig, fullfile(frameDir, sprintf('f%03d.png', i)));
    fprintf('frame %2d/%d  Eb/N0 = %g dB\n', i, numel(ebList), ebList(i));
end
clear cleanup                                     % closes the app

% 2) assemble the GIF
frames = cell(1, numel(ebList));
for i = 1:numel(ebList)
    f = fullfile(frameDir, sprintf('f%03d.png', i));
    frames{i} = shrink(imread(f), width);
    delete(f);
end
writeGif(outFile, frames, 0.35, 1.5);   % pause on the clean and worst frames
rmdir(frameDir);
info = dir(outFile);
fprintf('%s: %.2f MB\n', outFile, info.bytes / 2^20);
end

function out = shrink(img, width)
% Area-averaging resize (no Image Processing Toolbox needed).
[H, W, C] = size(img);
height = round(H * width / W);
x = linspace(1, W, width);
y = linspace(1, H, height).';
out = zeros(height, width, C, 'uint8');
f = W / width;                                     % pre-smooth to avoid aliasing
k = max(1, round(f));
for c = 1:C
    ch = conv2(double(img(:, :, c)), ones(k) / k^2, 'same');
    out(:, :, c) = uint8(interp2(ch, x, y, 'linear'));
end
end

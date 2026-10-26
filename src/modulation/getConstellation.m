function [pts, labels] = getConstellation(name)
%GETCONSTELLATION Ideal constellation (unit average energy) and bit labels.
%   pts(i) is the symbol sent for the integer i-1, whose bits (MSB first) are
%   labels(i,:).
ask = regexp(name, '^(\d+)-ASK$', 'tokens', 'once');
psk = regexp(name, '^(\d+)-PSK$', 'tokens', 'once');
if ~isempty(ask)                               % unipolar M-ASK: 0, 1, ..., M-1
    M = str2double(ask{1});
    i = (0:M-1).';
    pts = zeros(M, 1);
    pts(grayCode(i) + 1) = i;
elseif ~isempty(psk)                           % M-PSK on the unit circle
    M = str2double(psk{1});
    off = pi/4 * (M == 4);                     % classic QPSK at 45 deg
    i = (0:M-1).';
    pts = zeros(M, 1);
    pts(grayCode(i) + 1) = exp(1j * (2*pi*i/M + off));
    pts(abs(imag(pts)) < 1e-12) = real(pts(abs(imag(pts)) < 1e-12));
else
switch name
    case 'OOK'
        pts = [0; 1];
    case 'BASK'
        pts = [1; 3];
    case {'16-QAM', '64-QAM'}
        M = sscanf(name, '%d');
        m = sqrt(M);
        lev = -(m-1):2:(m-1);
        [I, Q] = meshgrid(0:m-1, 0:m-1);
        lab = grayCode(I(:)) * m + grayCode(Q(:));    % I bits, then Q bits
        pts = zeros(M, 1);
        pts(lab + 1) = lev(I(:) + 1) + 1j * lev(Q(:) + 1);
    case '16-APSK'
        % ring: {radius, nPoints, first angle (deg), folded angles, labels}
        rings = {1,    4,  45, 45,         3
                 2.85, 12, 15, [15 45 75], [2 0 1]};
        pts = buildAPSK(rings, 2);
    case '32-APSK'
        rings = {1,    4,  45,    45,                        2
                 2.84, 12, 15,    [15 45 75],                [0 1 3]
                 5.27, 16, 11.25, [11.25 33.75 56.25 78.75], [4 5 7 6]};
        pts = buildAPSK(rings, 3);
    otherwise
        error('ModulationLab:const', 'No constellation for "%s".', name);
end
end
pts = pts / sqrt(mean(abs(pts).^2));
M = numel(pts);
k = log2(M);
labels = reshape(intToBits(0:M-1, k), k, []).';
end

function pts = buildAPSK(rings, nIntra)
% Quasi-Gray labelling: the 2 MSBs give the quadrant (like QPSK), the other
% bits depend on the position inside the quadrant, mirrored from one quadrant
% to the next so that neighbours across an axis differ by a single bit.
M = 4 * 2^nIntra;
pts = zeros(M, 1);
for r = 1:size(rings, 1)
    [rad, n, a0, folded, lab] = rings{r, :};
    for a = a0 + (0:n-1) * 360/n
        z = rad * exp(1j * a * pi/180);
        q = 2*(real(z) < 0) + (imag(z) < 0);
        af = atan2(abs(imag(z)), abs(real(z))) * 180/pi;
        [~, ii] = min(abs(folded - af));
        pts(q * 2^nIntra + lab(ii) + 1) = z;
    end
end
end

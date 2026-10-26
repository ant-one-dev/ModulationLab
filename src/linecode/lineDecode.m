function [bits, z, levels, thr] = lineDecode(rx, name, sps, N)
%LINEDECODE Integrate-and-dump receiver for the line codes.
%   z is the decision variable (mean of the matched portion of each symbol),
%   levels are its noiseless values and thr the decision thresholds.
h = sps/2;
rx = real(rx(:));
if strcmp(name, '2B1Q')
    X = reshape(rx(1:N*sps), 2*sps, N/2);
    z = mean(X, 1).';
    levels = [-3 -1 1 3];
    thr = [-2 0 2];
    b1 = z > 0;             % sign bit
    b2 = abs(z) < 2;        % inner level -> 1
    bits = double(reshape([b1 b2].', [], 1));
    return
end
X = reshape(rx(1:N*sps), sps, N);
switch name
    case 'Unipolar NRZ'
        z = mean(X, 1).';                  levels = [0 1];  thr = 0.5;
    case 'Polar NRZ'
        z = mean(X, 1).';                  levels = [-1 1]; thr = 0;
    case 'Unipolar RZ'
        z = mean(X(1:h, :), 1).';          levels = [0 1];  thr = 0.5;
    case 'Polar RZ'
        z = mean(X(1:h, :), 1).';          levels = [-1 1]; thr = 0;
    case 'Manchester'
        z = (mean(X(h+1:end, :), 1) - mean(X(1:h, :), 1)).' / 2;
        levels = [-1 1]; thr = 0;
    case 'AMI (bipolar)'
        z = mean(X, 1).';                  levels = [-1 0 1]; thr = [-0.5 0.5];
    otherwise
        error('ModulationLab:line', 'Unknown line code "%s".', name);
end
if strcmp(name, 'AMI (bipolar)')
    bits = double(abs(z) > 0.5);
else
    bits = double(z > thr);
end
end

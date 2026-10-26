function y = lowpassFIR(x, cutoff, sps)
%LOWPASSFIR Zero-delay windowed-sinc low-pass filter (receiver front-end).
%   cutoff is in units of the symbol rate (e.g. 0.75 -> 0.75 R_s).
fc = cutoff / sps;                        % cycles per sample
n = (-2*sps : 2*sps).';
h = 2*fc * sinc0(2*fc*n) .* (0.54 + 0.46*cos(pi*n / (2*sps)));   % Hamming window
h = h / sum(h);
y = conv(x(:), h);
D = (numel(h) - 1) / 2;
y = y(D+1 : D+numel(x));
end

function s = sinc0(x)
s = ones(size(x));
i = x ~= 0;
s(i) = sin(pi*x(i)) ./ (pi*x(i));
end

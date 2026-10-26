function [P, f] = welchPSD(x, nfft)
%WELCHPSD Two-sided power spectral density (Welch, Hann window, 50 % overlap).
%   f is in cycles per sample, from -0.5 to 0.5.
x = x(:);
nfft = min(nfft, 2^floor(log2(numel(x))));
w = 0.5 - 0.5*cos(2*pi*(0:nfft-1).' / nfft);
hop = nfft/2;
nSeg = min(floor((numel(x) - nfft)/hop) + 1, 400);
idx = (1:nfft).' + (0:nSeg-1) * hop;
X = fft(x(idx) .* w, nfft);
P = fftshift(mean(abs(X).^2, 2) / sum(w.^2));
f = (-nfft/2 : nfft/2-1).' / nfft;
end

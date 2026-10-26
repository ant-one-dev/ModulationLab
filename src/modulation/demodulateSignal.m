function [bits, d] = demodulateSignal(rx, m, sch)
%DEMODULATESIGNAL Optimal (or classic) receiver for every scheme.
%   d holds the decision samples and the signal used for the eye diagram.
sps = m.sps;
k = sch.k;
Ns = m.nSym;
rx = rx(:);
d = struct();
switch m.kind
    case 'line'
        [bits, d.z, d.levels, d.thresholds] = lineDecode(rx, sch.name, sps, Ns*k);
        P = m.symPeriod;
        d.eyeSig = movmean(rx, max(1, round(sps/2)));   % half-bit matched filter
        d.eyeCenters = (0:Ns-1).' * P + P/2 + 0.5;
        d.eyePeriod = P;
        d.eyeLabel = 'Amplitude (after RX low-pass)';
    case 'linear'
        y = conv(rx, m.pulse);                 % matched filter (integrate over the symbol)
        L = numel(m.pulse);
        idx = L + (0:Ns-1).' * sps;            % optimal sampling instants
        rs = y(idx);
        bits = intToBits(nearestPoint(rs, m.pts) - 1, k);
        d.rxSym = rs;
        d.eyeSig = real(y);
        d.eyeCenters = idx;
        d.eyePeriod = sps;
        d.eyeLabel = 'I amplitude (after matched filter)';
    case 'fsk'
        % Non-coherent receiver: energy of each tone over the symbol
        R = reshape(rx(1:Ns*sps), sps, Ns);
        E = exp(-1j * 2*pi * (0:sps-1).' * m.freqs / sps);
        [~, ii] = max(abs(R.' * E), [], 2);
        bits = intToBits(ii - 1, k);
        rxf = lowpassFIR(rx, max(abs(m.freqs)) + 0.75, sps);
        disc = [0; angle(rxf(2:end) .* conj(rxf(1:end-1)))] * sps / (2*pi);
        d.eyeSig = movmean(disc, max(1, round(sps/4)));
        d.rxFilt = rxf;
        d.eyeCenters = (0:Ns-1).' * sps + sps/2 + 1;
        d.eyePeriod = sps;
        d.eyeLabel = 'Instantaneous frequency (x R_s)';
end
bits = double(bits(:));
end

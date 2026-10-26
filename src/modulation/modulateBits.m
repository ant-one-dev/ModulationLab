function [tx, m] = modulateBits(bits, sch, cfg)
%MODULATEBITS Map channel bits to a sampled waveform.
%   Line codes give a real baseband signal; every other scheme gives the
%   complex envelope of the passband signal.
%   m holds everything the receiver and the plots need.
sps = cfg.sps;
k = sch.k;
bits = double(bits(:));
m = struct('kind', sch.kind, 'sps', sps, 'nSym', numel(bits)/k, ...
    'dispDelay', 0, 'samplesPerBit', sps/k, 'symPeriod', sps);
switch sch.kind
    case 'line'
        tx = lineEncode(bits, sch.name, sps);
        m.samplesPerBit = sps;            % line codes: sps samples per bit
        m.symPeriod = sps * k;
    case 'linear'
        [pts, labels] = getConstellation(sch.name);
        sym = pts(bitsToInt(bits, k) + 1);
        p = ones(sps, 1) / sqrt(sps);     % rectangular pulse, unit energy
        up = zeros(numel(sym) * sps, 1);
        up(1:sps:end) = sym;
        tx = complex(conv(up, p));
        m.pts = pts;
        m.labels = labels;
        m.txSym = sym;
        m.pulse = p;
        m.dispDelay = (numel(p) - 1)/2 - sps/2;
    case 'fsk'
        M = sch.M;
        m.freqs = (0:M-1) - (M-1)/2;      % tone spacing = symbol rate (h = 1)
        f = m.freqs(bitsToInt(bits, k) + 1);
        inc = 2*pi * repelem(f(:), sps) / sps;
        tx = exp(1j * [0; cumsum(inc(1:end-1))]);   % continuous phase
    otherwise
        error('ModulationLab:kind', 'Unknown scheme kind "%s".', sch.kind);
end
end

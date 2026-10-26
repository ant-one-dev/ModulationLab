function plotTimeSignals(axBits, axSig, res)
%PLOTTIMESIGNALS Channel bits (top) and TX / RX waveforms (bottom).
%   Passband schemes are shown on a carrier at 3 cycles per symbol.
%   For readability the displayed RX noise is limited to the signal band.
%   The time axis is in seconds, from the bit rate res.cfg.Rb.
c = commsColors();
sch = res.scheme;
k = sch.k;
m = res.mod;

if strcmp(sch.kind, 'line')
    nBits = 16;
else
    nBits = k * ceil(max(12, 4*k) / k);
end
nBits = min(nBits, numel(res.chBits));
b = res.chBits(1:nBits);
Rb = res.cfg.Rb;
[sc, pre] = engUnit(nBits / Rb);
u = 1 / (Rb * sc);                 % bit periods -> displayed time unit

% ---------------- bits
cla(axBits); hold(axBits, 'on');
stairs(axBits, (0:nBits)*u, [b; b(end)], 'Color', c.bits, 'LineWidth', 1.6);
text(axBits, ((1:nBits) - 0.5)*u, 1.32*ones(1, nBits), cellstr(num2str(b)), ...
    'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', c.bits);
if k > 1
    xline(axBits, (k:k:nBits-1)*u, ':', 'Color', c.grid);
end
hold(axBits, 'off');
axBits.XLim = [0 nBits]*u;
axBits.YLim = [-0.25 1.7];
axBits.YTick = [0 1];
axBits.XTickLabel = {};
ylabel(axBits, 'Bit');
box(axBits, 'on');
title(axBits, sprintf('Channel bits (after coding)  -  %d bit(s) / symbol', k));

% ---------------- waveform
spb = m.samplesPerBit;
t = ((0:numel(res.tx)-1).' - m.dispDelay) / spb;      % in bit periods
sel = t >= 0 & t <= nBits;
ts = t(sel);
nd = movmean(res.noise, max(1, round(m.sps/2)));
txs = res.tx(sel);
rxs = txs + nd(sel);

cla(axSig); hold(axSig, 'on');
if strcmp(sch.kind, 'line')
    hRx = plot(axSig, ts*u, real(rxs), 'Color', [c.rx 0.6], 'LineWidth', 0.8);
    hTx = plot(axSig, ts*u, real(txs), 'Color', c.tx, 'LineWidth', 1.8);
    ttl = sprintf('%s line code', sch.name);
else
    tt = linspace(ts(1), ts(end), 8*numel(ts)).';
    ip = @(v) interp1(ts, real(v), tt, 'pchip') + 1j*interp1(ts, imag(v), tt, 'pchip');
    xt = ip(txs);
    xr = ip(rxs);
    car = exp(1j * 2*pi * (3/k) * tt);                 % 3 carrier cycles / symbol
    hRx = plot(axSig, tt*u, sqrt(2)*real(xr .* car), 'Color', [c.rx 0.6], 'LineWidth', 0.8);
    hTx = plot(axSig, tt*u, sqrt(2)*real(xt .* car), 'Color', c.tx, 'LineWidth', 1.3);
    if strcmp(sch.kind, 'linear') && isempty(regexp(sch.name, '^\d+-PSK$', 'once'))
        plot(axSig, tt*u,  sqrt(2)*abs(xt), '--', 'Color', [c.tx 0.7], 'LineWidth', 1);
        plot(axSig, tt*u, -sqrt(2)*abs(xt), '--', 'Color', [c.tx 0.7], 'LineWidth', 1);
    end
    ttl = sprintf('%s modulated carrier  (f_c = %s, display only)', sch.name, fmtEng(3*Rb/k, 'Hz'));
end
if k > 1
    xline(axSig, (k:k:nBits-1)*u, ':', 'Color', c.grid);
end
hold(axSig, 'off');
grid(axSig, 'on');
axSig.XLim = [0 nBits]*u;
xlabel(axSig, sprintf('Time (%ss)   -   T_b = 1/R_b = %s', pre, fmtEng(1/Rb, 's')));
ylabel(axSig, 'Amplitude');
title(axSig, ttl);
legend(axSig, [hTx hRx], {'TX', 'RX (noisy)'}, 'Location', 'northeast', 'AutoUpdate', 'off');
end

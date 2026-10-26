function res = runChain(cfg, infoBits)
%RUNCHAIN Simulate the complete transmission chain once.
%
%   res = RUNCHAIN(cfg, infoBits)
%
%   bits -> CRC -> FEC -> modulation / line code -> AWGN -> demodulation
%        -> FEC decoding -> CRC check
%
%   Eb/N0 is defined per INFORMATION bit: the energy spent on CRC, parity
%   bits and code tails is counted, so coding gains are shown honestly.
cfg = defaultConfig(cfg);
sch = getScheme(cfg.scheme);
infoBits = double(infoBits(:) ~= 0);
nInfo = numel(infoBits);

% ---- transmitter
[crcBits, crcInfo] = crcEncode(infoBits, cfg.crc, cfg.crcFrameLen);
[fecBits, fecInfo] = fecEncode(crcBits, cfg.fec);
chBits = [fecBits; zeros(mod(-numel(fecBits), sch.k), 1)];
[tx, m] = modulateBits(chBits, sch, cfg);

% ---- AWGN channel
EbN0 = 10^(cfg.EbN0dB / 10);
N0 = sum(abs(tx).^2) / (nInfo * EbN0);
if ~cfg.noise
    noise = zeros(size(tx));
elseif strcmp(sch.kind, 'line')
    noise = sqrt(N0/2) * randn(size(tx));
else
    noise = sqrt(N0/2) * (randn(size(tx)) + 1j * randn(size(tx)));
end
rx = tx + noise;

% ---- receiver
[rxCh, d] = demodulateSignal(rx, m, sch);
rxFec = rxCh(1:numel(fecBits));
rxCrc = fecDecode(rxFec, fecInfo);
[rxInfo, crcFail] = crcDecode(rxCrc, crcInfo);

% ---- statistics
res.cfg = cfg;
res.scheme = sch;
res.infoBits = infoBits;
res.rxBits = rxInfo;
res.chBits = chBits;
res.nInfo = nInfo;
res.nCh = numel(chBits);
res.codeRate = nInfo / numel(chBits);
res.nErr = sum(rxInfo ~= infoBits);
res.ber = res.nErr / nInfo;
res.rawErr = sum(rxFec ~= fecBits);
res.rawBER = res.rawErr / numel(fecBits);
res.crcFrames = crcInfo.nFrames;
res.crcFail = sum(crcFail);
res.crcUndetected = 0;
if crcInfo.nFrames > 0
    e = [rxInfo ~= infoBits; false(crcInfo.pad, 1)];
    frameErr = any(reshape(e, crcInfo.frameLen, []), 1).';
    res.crcUndetected = sum(frameErr & ~crcFail);
end
res.N0 = N0;
res.tx = tx;
res.rx = rx;
res.noise = noise;
res.mod = m;
res.demod = d;
res.theory = theoreticalBER(sch.name, cfg.EbN0dB);
end

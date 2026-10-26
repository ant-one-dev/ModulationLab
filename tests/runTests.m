function runTests()
%RUNTESTS Self-checks of the ModulationLab signal processing blocks.
%   Run from anywhere:  >> runTests
root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(root, 'src')));
rng(42);
nFail = 0;

    function check(cond, msg)
        if cond
            fprintf('  [ OK ] %s\n', msg);
        else
            fprintf('  [FAIL] %s\n', msg);
            nFail = nFail + 1;
        end
    end

fprintf('\n== Channel coding ==\n');
msg = reshape(dec2bin(double('123456789'), 8).' - '0', [], 1);
crc8 = crcCompute(msg, crcPoly('CRC-8'));
crc16 = crcCompute(msg, crcPoly('CRC-16-CCITT'));
check(isequal(bin2dec(char(crc8.' + '0')), hex2dec('F4')), 'CRC-8 check value 0xF4');
check(isequal(bin2dec(char(crc16.' + '0')), hex2dec('31C3')), 'CRC-16-CCITT (XMODEM) check value 0x31C3');

[enc, info] = crcEncode(randi([0 1], 1000, 1), 'CRC-16-CCITT', 128);
enc(77) = 1 - enc(77);
[~, fail] = crcDecode(enc, info);
check(fail(1) && ~any(fail(2:end)), 'CRC detects a single bit error in the right frame');

d = randi([0 1], 4, 1);
c = hammingEncode(d);
ok = true;
for p = 1:7
    e = c; e(p) = 1 - e(p);
    ok = ok && isequal(hammingDecode(e), d);
end
check(ok, 'Hamming (7,4) corrects every single error position');

for t = {'Conv. K=3 (7,5) + Viterbi', 'Conv. K=7 (171,133) + Viterbi'}
    [g, K] = convSpec(t{1});
    u = randi([0 1], 500, 1);
    cw = convEncode(u, g, K);
    check(isequal(viterbiDecode(cw, g, K), u), [t{1} ': noiseless decoding']);
    err = cw; pos = 20:40:numel(cw)-20; err(pos) = 1 - err(pos);
    check(isequal(viterbiDecode(err, g, K), u), [t{1} ': corrects spread errors']);
end

fprintf('\n== Constellations ==\n');
names = schemeNames();
schemes = cellfun(@getScheme, names);
lin = schemes(strcmp({schemes.kind}, 'linear'));
for s = lin(:).'
    [pts, labels] = getConstellation(s.name);
    uniq = numel(unique(round(pts * 1e6))) == numel(pts);
    check(abs(mean(abs(pts).^2) - 1) < 1e-12 && uniq && size(labels, 1) == s.M, ...
        sprintf('%-8s unit energy, %d distinct points', s.name, s.M));
    if ~contains(s.name, 'APSK') && s.M > 2
        D = abs(pts - pts.'); D(1:s.M+1:end) = inf;
        dmin = min(D(:));
        [i, j] = find(abs(D - dmin) < 1e-9);
        hd = sum(labels(i, :) ~= labels(j, :), 2);
        check(all(hd == 1), sprintf('%-8s Gray mapping (nearest neighbours differ by 1 bit)', s.name));
    end
end

fprintf('\n== Noiseless chain (every scheme x every code) ==\n');
fecs = {'None', 'Hamming (7,4)', 'Conv. K=3 (7,5) + Viterbi', 'Conv. K=7 (171,133) + Viterbi'};
for s = schemes(:).'
    ok = true;
    for f = fecs
        cfg = defaultConfig(struct('scheme', s.name, 'noise', false, 'fec', f{1}, 'crc', 'CRC-8'));
        r = runChain(cfg, randi([0 1], 999, 1));
        ok = ok && r.nErr == 0 && r.crcFail == 0;
    end
    check(ok, sprintf('%-14s error-free without noise', s.name));
end

fprintf('\n== Simulated BER vs theory (AWGN) ==\n');
for s = schemes(:).'
    % pick the Eb/N0 where the theory gives about 1e-2
    eb = 0:0.25:35;
    th = theoreticalBER(s.name, eb);
    [~, i] = min(abs(log10(th) + 2));
    cfg = defaultConfig(struct('scheme', s.name, 'EbN0dB', eb(i)));
    r = runChain(cfg, randi([0 1], 2e5, 1));
    ratio = r.ber / th(i);
    if contains(s.name, 'APSK')
        check(ratio > 0.4 && ratio < 1.1, sprintf('%-14s Eb/N0=%5.2f dB  sim %.2e  <= union bound %.2e', s.name, eb(i), r.ber, th(i)));
    else
        check(abs(ratio - 1) < 0.15, sprintf('%-14s Eb/N0=%5.2f dB  sim %.2e  theory %.2e', s.name, eb(i), r.ber, th(i)));
    end
end

fprintf('\n== Coding gain ==\n');
cfg = defaultConfig(struct('scheme', '2-PSK', 'EbN0dB', 6));
rU = runChain(cfg, randi([0 1], 1e5, 1));
cfg.fec = 'Conv. K=7 (171,133) + Viterbi';
rC = runChain(cfg, randi([0 1], 1e5, 1));
check(rC.ber < rU.ber / 10, sprintf('BPSK @ 6 dB: uncoded %.2e -> K=7 Viterbi %.2e', rU.ber, rC.ber));

fprintf('\n%d failure(s)\n', nFail);
if nFail > 0
    error('ModulationLab:tests', '%d test(s) failed.', nFail);
end
end

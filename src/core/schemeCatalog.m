function c = schemeCatalog()
%SCHEMECATALOG All supported transmission schemes.
%   Each entry has: family, name, kind ('line' | 'linear' | 'fsk'),
%   M (alphabet size), k (bits per symbol), a one-line description and
%   orders. Entries whose name starts with 'M-' are templates: the order M is
%   chosen among ORDERS and the concrete name is e.g. '8-PSK' (see getScheme).

L = 'Line coding (baseband)';
A = 'Amplitude (OOK / ASK)';
F = 'Frequency (FSK)';
P = 'Phase (PSK)';
Q = 'QAM / APSK';

c = [ ...
    entry(L, 'Unipolar NRZ',  'line', 2, 1, '1 -> +A, 0 -> 0 for the whole bit. Simple but has a strong DC component.')
    entry(L, 'Polar NRZ',     'line', 2, 1, '1 -> +A, 0 -> -A (antipodal). No DC for balanced data, best noise immunity.')
    entry(L, 'Unipolar RZ',   'line', 2, 1, '1 -> +A during the first half of the bit, then back to 0.')
    entry(L, 'Polar RZ',      'line', 2, 1, '+A / -A during the first half of the bit, then 0. Wider spectrum, easier clock recovery.')
    entry(L, 'Manchester',    'line', 2, 1, 'IEEE 802.3: 1 = low->high, 0 = high->low transition in the middle of the bit. Self-clocking, no DC.')
    entry(L, 'AMI (bipolar)', 'line', 3, 1, '0 -> 0, successive 1s alternate +A / -A. No DC component (T1/E1 lines).')
    entry(L, '2B1Q',          'line', 4, 2, '2 bits -> 1 of 4 levels (-3, -1, +1, +3). Halves the symbol rate (ISDN U interface).')
    entry(A, 'OOK',    'linear', 2, 1, 'On-Off Keying: carrier on (A) for 1, off for 0. Simplest ASK (RFID, 433 MHz remotes).')
    entry(A, 'BASK',   'linear', 2, 1, 'Binary ASK with two non-zero amplitudes (A for 0, 3A for 1): the carrier is never switched off.')
    entry(A, 'M-ASK',  'linear', 0, 0, 'M amplitudes 0, A, 2A ... (M-1)A, Gray coded, log2(M) bits/symbol. M = 2 would be OOK.', [4 8 16])
    entry(F, 'BFSK',   'fsk',  2, 1, '2 orthogonal tones (h = 1), continuous phase, non-coherent detection.')
    entry(F, '4-FSK',  'fsk',  4, 2, '4 orthogonal tones (h = 1), 2 bits/symbol, non-coherent detection.')
    entry(P, 'M-PSK',  'linear', 0, 0, 'M phases on a circle, Gray coded, constant envelope: only the phase jumps from one symbol to the next. M = 2 is BPSK, M = 4 is QPSK.', [2 4 8 16 32])
    entry(Q, '16-QAM', 'linear', 16, 4, 'Square 4x4 grid, Gray coded on I and Q, 4 bits/symbol (Wi-Fi, LTE).')
    entry(Q, '64-QAM', 'linear', 64, 6, 'Square 8x8 grid, Gray coded on I and Q, 6 bits/symbol (Wi-Fi, DVB-C).')
    entry(Q, '16-APSK', 'linear', 16, 4, '4 + 12 points on 2 rings (DVB-S2 ratio 2.85). Fewer amplitude levels than 16-QAM: robust to amplifier non-linearity.')
    entry(Q, '32-APSK', 'linear', 32, 5, '4 + 12 + 16 points on 3 rings (DVB-S2 ratios 2.84 / 5.27), 5 bits/symbol.')
    ];
end

function e = entry(family, name, kind, M, k, desc, orders)
if nargin < 7, orders = []; end
e = struct('family', family, 'name', name, 'kind', kind, 'M', M, 'k', k, ...
    'desc', desc, 'orders', orders);
end

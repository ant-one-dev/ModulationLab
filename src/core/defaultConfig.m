function cfg = defaultConfig(cfg)
%DEFAULTCONFIG Fill the missing fields of a simulation configuration.
%
%   scheme      name from schemeCatalog            ('4-PSK')
%   EbN0dB      Eb/N0 per information bit, in dB   (8)
%   noise       add AWGN or not                    (true)
%   sps         samples per symbol (per bit for line codes)  (16)
%   Rb          channel bit rate in bit/s, only used to label the time
%               and frequency axes (9600)
%   crc         'None' | 'CRC-8' | 'CRC-16-CCITT'
%   crcFrameLen information bits per CRC frame     (128)
%   fec         'None' | 'Hamming (7,4)' | 'Conv. K=3 (7,5) + Viterbi'
%               | 'Conv. K=7 (171,133) + Viterbi'
if nargin < 1, cfg = struct(); end
def = struct('scheme', '4-PSK', 'EbN0dB', 8, 'noise', true, ...
    'sps', 16, 'Rb', 9600, ...
    'crc', 'None', 'crcFrameLen', 128, 'fec', 'None');
f = fieldnames(def);
for i = 1:numel(f)
    if ~isfield(cfg, f{i}), cfg.(f{i}) = def.(f{i}); end
end
end

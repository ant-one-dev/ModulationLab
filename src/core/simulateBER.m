function [ber, nErr] = simulateBER(cfg, EbN0dB, nBits, progressFcn)
%SIMULATEBER Monte-Carlo bit error rate for a list of Eb/N0 values.
%   progressFcn(i, n), if given, is called before each point and must return
%   true to continue (false cancels the simulation).
if nargin < 4, progressFcn = []; end
ber = nan(size(EbN0dB));
nErr = nan(size(EbN0dB));
for i = 1:numel(EbN0dB)
    if ~isempty(progressFcn) && ~progressFcn(i, numel(EbN0dB))
        break
    end
    cfg.EbN0dB = EbN0dB(i);
    r = runChain(cfg, randi([0 1], nBits, 1));
    ber(i) = r.ber;
    nErr(i) = r.nErr;
end
end

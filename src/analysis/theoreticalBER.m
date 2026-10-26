function [ber, label] = theoreticalBER(name, EbN0dB)
%THEORETICALBER Uncoded bit error rate on the AWGN channel.
%   APSK uses the union bound computed from the actual constellation and
%   labelling. Returns [] for an unknown name.
g = 10.^(EbN0dB / 10);
label = 'Theory';
ask = regexp(name, '^(\d+)-ASK$', 'tokens', 'once');
psk = regexp(name, '^(\d+)-PSK$', 'tokens', 'once');
if ~isempty(ask)                                  % unipolar M-ASK, Gray
    M = str2double(ask{1}); k = log2(M);
    ber = min(2*(M-1)/(M*k) * qfun(sqrt(3*k*g/((M-1)*(2*M-1)))), 0.5);
    return
elseif ~isempty(psk)                              % M-PSK, Gray
    M = str2double(psk{1}); k = log2(M);
    if M <= 4
        ber = qfun(sqrt(2*g));
    else
        ber = (2/k) * qfun(sqrt(2*k*g) * sin(pi/M));
    end
    ber = min(ber, 0.5);
    return
end
switch name
    case {'Polar NRZ', 'Polar RZ', 'Manchester'}
        ber = qfun(sqrt(2*g));
    case {'Unipolar NRZ', 'Unipolar RZ', 'OOK'}
        ber = qfun(sqrt(g));
    case 'AMI (bipolar)'
        ber = 1.5 * qfun(sqrt(g));
    case '2B1Q'                                   % 4-PAM, Gray
        ber = 0.75 * qfun(sqrt(0.8*g));
    case 'BASK'                                   % amplitudes A and 3A
        ber = qfun(sqrt(0.4*g));
    case {'16-QAM', '64-QAM'}
        M = sscanf(name, '%d'); k = log2(M);
        ber = 4/k * (1 - 1/sqrt(M)) * qfun(sqrt(3*k*g/(M-1)));
    case {'16-APSK', '32-APSK'}
        ber = unionBoundBER(name, g);
        label = 'Union bound';
    case {'BFSK', '4-FSK'}                        % orthogonal, non-coherent
        M = 2 + 2*strcmp(name, '4-FSK'); k = log2(M);
        Ps = zeros(size(g));
        for n = 1:M-1
            Ps = Ps + (-1)^(n+1) * nchoosek(M-1, n) / (n+1) * exp(-n*k*g/(n+1));
        end
        ber = Ps * (M/2) / (M-1);
    otherwise
        ber = [];
        label = '';
        return
end
ber = min(ber, 0.5);
end

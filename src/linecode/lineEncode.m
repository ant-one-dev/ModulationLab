function x = lineEncode(bits, name, sps)
%LINEENCODE Baseband line code waveform (amplitude A = 1, SPS samples per bit).
b = double(bits(:));
h = sps/2;
switch name
    case 'Unipolar NRZ'
        x = repelem(b, sps);
    case 'Polar NRZ'
        x = repelem(2*b - 1, sps);
    case 'Unipolar RZ'
        x = kron(b, [ones(h, 1); zeros(h, 1)]);
    case 'Polar RZ'
        x = kron(2*b - 1, [ones(h, 1); zeros(h, 1)]);
    case 'Manchester'
        % IEEE 802.3 convention: 1 = low -> high, 0 = high -> low
        x = kron(2*b - 1, [-ones(h, 1); ones(h, 1)]);
    case 'AMI (bipolar)'
        s = zeros(numel(b), 1);
        ones_ = find(b == 1);
        s(ones_) = (-1).^(0:numel(ones_)-1);   % +1, -1, +1, ...
        x = repelem(s, sps);
    case '2B1Q'
        B = reshape(b, 2, []).';
        % 10 -> +3, 11 -> +1, 01 -> -1, 00 -> -3 (Gray: one bit per step)
        lv = (2*B(:, 1) - 1) .* (3 - 2*B(:, 2));
        x = repelem(lv, 2*sps);
    otherwise
        error('ModulationLab:line', 'Unknown line code "%s".', name);
end
end

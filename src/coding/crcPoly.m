function [poly, r] = crcPoly(type)
%CRCPOLY Generator polynomial bits (x^(r-1) ... x^0, leading x^r implied).
switch type
    case 'None'
        poly = [];
    case 'CRC-8'            % x^8 + x^2 + x + 1           (0x07)
        poly = dec2bin(hex2dec('07'), 8) - '0';
    case 'CRC-16-CCITT'     % x^16 + x^12 + x^5 + 1       (0x1021)
        poly = dec2bin(hex2dec('1021'), 16) - '0';
    otherwise
        error('ModulationLab:crc', 'Unknown CRC "%s".', type);
end
r = numel(poly);
end

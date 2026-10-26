function [g, K] = convSpec(type)
%CONVSPEC Generators (binary, one row per output) of the rate-1/2 codes.
if contains(type, 'K=3')
    oct = {'7', '5'};     K = 3;   % classic textbook code, d_free = 5
elseif contains(type, 'K=7')
    oct = {'171', '133'}; K = 7;   % NASA / IEEE 802.11 code, d_free = 10
else
    error('ModulationLab:fec', 'Unknown convolutional code "%s".', type);
end
g = zeros(2, K);
for i = 1:2
    g(i, :) = dec2bin(base2dec(oct{i}, 8), K) - '0';
end
end

function out = fecDecode(bits, info)
%FECDECODE Forward error correction decoder (inverse of FECENCODE).
switch info.type
    case 'None'
        out = bits(:);
    case 'Hamming (7,4)'
        out = hammingDecode(bits);
        out = out(1:info.nIn);
    otherwise
        out = viterbiDecode(bits, info.g, info.K);
end
end

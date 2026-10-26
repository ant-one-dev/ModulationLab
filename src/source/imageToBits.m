function bits = imageToBits(px)
%IMAGETOBITS 8 bits per sample (MSB first): 24 bits per RGB pixel.
bits = reshape(dec2bin(px(:), 8).' - '0', [], 1);
end

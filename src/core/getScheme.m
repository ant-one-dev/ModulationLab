function s = getScheme(name)
%GETSCHEME Catalog entry of the scheme called NAME.
%   Concrete names of the template schemes are accepted, e.g. '8-PSK' or
%   '16-ASK' (order M taken from the name).
persistent cat
if isempty(cat), cat = schemeCatalog(); end
i = find(strcmp({cat.name}, name), 1);
if ~isempty(i)
    s = cat(i);
    return
end
tok = regexp(name, '^(\d+)-(ASK|PSK)$', 'tokens', 'once');
if ~isempty(tok)
    s = cat(strcmp({cat.name}, ['M-' tok{2}]));
    M = str2double(tok{1});
    if ismember(M, s.orders)
        s.name = name;
        s.M = M;
        s.k = log2(M);
        return
    end
end
error('ModulationLab:unknownScheme', 'Unknown scheme "%s".', name);
end

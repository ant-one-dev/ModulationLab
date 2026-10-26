function names = schemeNames()
%SCHEMENAMES Every concrete scheme name (templates expanded for each M).
cat = schemeCatalog();
names = {};
for s = cat.'
    if isempty(s.orders)
        names{end+1} = s.name; %#ok<AGROW>
    else
        for M = s.orders
            names{end+1} = sprintf('%d-%s', M, s.name(3:end)); %#ok<AGROW>
        end
    end
end
end

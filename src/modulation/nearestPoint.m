function idx = nearestPoint(r, pts)
%NEARESTPOINT Index of the closest constellation point (minimum distance).
r = r(:);
pts = pts(:).';
idx = zeros(numel(r), 1);
B = 20000;                                 % chunks keep memory bounded
for s = 1:B:numel(r)
    e = min(s + B - 1, numel(r));
    [~, idx(s:e)] = min(abs(r(s:e) - pts), [], 2);
end
end

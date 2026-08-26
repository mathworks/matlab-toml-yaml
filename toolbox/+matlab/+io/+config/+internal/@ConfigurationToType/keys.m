function [k, perElementKeys] = keys(obj)
if ~isscalar(obj)
    keySets = cell(size(obj));
    for i = 1:numel(obj)
        keySets{i} = keys(obj(i));
    end
    k = unique([keySets{:}], 'stable');
    if nargout > 1
        perElementKeys = keySets;
    end
    return;
end
k = keys(obj.Data)';  % Row vector for compatibility
if nargout > 1
    perElementKeys = {k};
end
end

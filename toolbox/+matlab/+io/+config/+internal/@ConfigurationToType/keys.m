function k = keys(obj)
    if ~isscalar(obj)
        keySets = cell(size(obj));
        for i = 1:numel(obj)
            keySets{i} = keys(obj(i));
        end
        k = unique([keySets{:}], 'stable');
        return;
    end
    k = keys(obj.Data)';  % Row vector for compatibility
end

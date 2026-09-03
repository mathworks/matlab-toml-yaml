function uniqueKeys = collectUnionOfKeys(obj)
    %COLLECTUNIONOFKEYS Get union of keys across array elements (preserving order)
    allKeys = string.empty(0,1);
    for i = 1:numel(obj)
        elementKeys = keys(obj(i));
        allKeys = [allKeys; reshape(elementKeys, [], 1)]; %#ok<AGROW>
    end
    uniqueKeys = unique(allKeys, 'stable');
end

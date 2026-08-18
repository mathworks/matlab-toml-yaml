function [paths, types, sizes] = collectRows(obj, prefix, paths, types, sizes, currentDepth, maxDepth)
%COLLECTROWS Collect table rows for a scalar ConfigurationData
originalKeys = keys(obj);

for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if prefix == ""
        fullPath = key;
    else
        fullPath = prefix + "." + key;
    end

    % Get size and type strings
    sizeStr = join(string(size(value)), "x");
    typeName = string(shortClassName(class(value)));

    % Add row for this key
    paths(end+1,1) = fullPath; %#ok<AGROW>
    types(end+1,1) = typeName; %#ok<AGROW>
    sizes(end+1,1) = sizeStr; %#ok<AGROW>

    % Recurse into nested ConfigurationData
    if isa(value, 'matlab.io.config.ConfigurationData') && currentDepth < maxDepth
        if isscalar(value)
            [paths, types, sizes] = collectRows(value, fullPath, paths, types, sizes, currentDepth + 1, maxDepth);
        else
            [paths, types, sizes] = collectArrayRows(value, fullPath, paths, types, sizes, currentDepth + 1, maxDepth);
        end
    end
end
end

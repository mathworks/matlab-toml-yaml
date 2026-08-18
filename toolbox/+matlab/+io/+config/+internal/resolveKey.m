function resolvedKey = resolveKey(dataDictionary, key)
%RESOLVEKEY Resolve a key against a data dictionary, checking aliases
%   Checks for direct match first, then scans for makeValidName aliases.
key = string(key);

% Direct match in data dictionary
if isKey(dataDictionary, key)
    resolvedKey = key;
    return;
end

% Check if key is a valid-name alias for an original key
originalKeys = keys(dataDictionary);
for i = 1:numel(originalKeys)
    if matlab.lang.makeValidName(originalKeys(i)) == key
        resolvedKey = originalKeys(i);
        return;
    end
end

resolvedKey = '';
end

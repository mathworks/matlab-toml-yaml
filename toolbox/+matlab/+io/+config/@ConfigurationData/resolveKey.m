function resolvedKey = resolveKey(obj, key)
key = string(key);

% Direct match in data dictionary
if isKey(obj.Data, key)
    resolvedKey = key;
    return;
end

% Check if key is a valid-name alias for an original key
originalKeys = keys(obj.Data);
for i = 1:numel(originalKeys)
    if matlab.lang.makeValidName(originalKeys(i)) == key
        resolvedKey = originalKeys(i);
        return;
    end
end

resolvedKey = '';
end

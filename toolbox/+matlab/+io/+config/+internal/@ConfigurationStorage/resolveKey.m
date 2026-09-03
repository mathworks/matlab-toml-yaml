function resolvedKeys = resolveKey(obj, key)
    %RESOLVEKEY Resolve key against data dictionaries, checking aliases
    %   For scalar obj, returns a string (missing if not found).
    %   For non-scalar obj, returns a string array (same size as obj).
    key = string(key);
    resolvedKeys = strings(size(obj));
    for i = 1:numel(obj)
        resolvedKeys(i) = resolveOne(obj(i).Data, key);
    end
end

function resolvedKey = resolveOne(dataDictionary, key)
    if isKey(dataDictionary, key)
        resolvedKey = key;
        return;
    end

    originalKeys = keys(dataDictionary);
    for i = 1:numel(originalKeys)
        if matlab.lang.makeValidName(originalKeys(i)) == key
            resolvedKey = originalKeys(i);
            return;
        end
    end

    resolvedKey = string(missing);
end

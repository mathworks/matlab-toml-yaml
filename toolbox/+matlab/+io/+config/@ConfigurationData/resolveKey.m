function resolvedKey = resolveKey(obj, key)
key = string(key);

if isKey(obj.xInternal__.Data, key)
    resolvedKey = key;
    return;
end

if isKey(obj.xInternal__.KeyAliases, key)
    resolvedKey = obj.xInternal__.KeyAliases(key);
    return;
end

resolvedKey = '';
end

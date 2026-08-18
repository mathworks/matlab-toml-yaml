function obj = rmfield(obj, key)
%RMFIELD Remove a field
resolvedKey = obj.resolveKey(key);
if isempty(resolvedKey)
    error('ConfigurationData:InvalidKey', ...
        'Key "%s" does not exist.', key);
end

% Remove from data (dictionary requires capturing return)
obj.xInternal__.Data = remove(obj.xInternal__.Data, resolvedKey);

% Remove from order tracking
obj.xInternal__.OriginalKeys(obj.xInternal__.OriginalKeys == resolvedKey) = [];

% Remove alias if exists
validKey = matlab.lang.makeValidName(key);
if isKey(obj.xInternal__.KeyAliases, validKey)
    obj.xInternal__.KeyAliases = remove(obj.xInternal__.KeyAliases, validKey);
end
end

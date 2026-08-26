function obj = rmfield(obj, key)
%RMFIELD Remove a field
resolvedKey = resolveKey(obj, key);
if ismissing(resolvedKey)
    error('ConfigurationData:InvalidKey', ...
        'Key "%s" does not exist.', key);
end

% Remove from data dictionary
obj.Data = remove(obj.Data, resolvedKey);
end

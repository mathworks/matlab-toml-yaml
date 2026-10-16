function obj = rmfield(obj, key)
    %RMFIELD Remove a field
    key = string(key);
    if ~hasKey(obj.Data, key)
        error('ConfigurationData:InvalidKey', ...
            'Key "%s" does not exist.', key);
    end
    obj.Data = removeKey(obj.Data, key);
end

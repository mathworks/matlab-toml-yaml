function obj = remove(obj, key)
    %REMOVE Remove a key (alias for rmfield)
    obj = obj.rmfield(key);
end

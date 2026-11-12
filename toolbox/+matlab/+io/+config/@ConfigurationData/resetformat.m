function obj = resetformat(obj, keyPath)
    %RESETFORMAT Remove format metadata
    %   obj = resetformat(obj, key) removes the metadata of key and of its
    %   value. Nested tables inside the value keep their own metadata.
    %
    %   obj = resetformat(obj, "a.b.c") navigates nested tables.
    %
    %   obj = resetformat(obj) removes the metadata of obj's table and of
    %   all its keys (not recursive).
    %
    %   See also GETFORMAT, SETFORMAT

    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        keyPath (1,1) string = missing
    end

    if ismissing(keyPath)
        obj.Data = setTableMetadata(obj.Data, []);
        for key = allKeys(obj.Data)
            obj.Data = resetKey(obj.Data, key);
        end
        return
    end

    [head, rest] = splitFormatPath(obj.Data, keyPath);
    if rest ~= ""
        child = getValue(obj.Data, head);
        if ~isa(child, "matlab.io.config.ConfigurationData") || ~isscalar(child)
            error("setformat:InvalidKey", "Key '%s' is not a table.", head);
        end
        obj.Data = setValue(obj.Data, head, resetformat(child, rest));
        return
    end

    obj.Data = resetKey(obj.Data, head);
end

function store = resetKey(store, key)
    store = setKeyMetadata(store, key, []);
    store = setNodeMetadata(store, key, []);
end

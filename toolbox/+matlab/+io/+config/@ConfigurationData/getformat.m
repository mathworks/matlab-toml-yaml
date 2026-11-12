function meta = getformat(obj, keyPath)
    %GETFORMAT Get the format metadata of a key or table
    %   meta = getformat(obj, key) returns a struct with the format
    %   properties set for key, combining the metadata of the key entry
    %   and of its value. Properties that are not set are omitted; the
    %   writer then uses its options or defaults.
    %
    %   meta = getformat(obj, "a.b.c") navigates nested tables.
    %
    %   meta = getformat(obj) returns the metadata of obj's own table,
    %   such as TOML file header comments.
    %
    %   See also SETFORMAT, RESETFORMAT

    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        keyPath (1,1) string = missing
    end

    if ismissing(keyPath)
        meta = toStruct(getTableMetadata(obj.Data));
        return
    end

    [head, rest] = splitFormatPath(obj.Data, keyPath);
    if rest ~= ""
        child = getValue(obj.Data, head);
        mustBeTable(child, head);
        meta = getformat(child, rest);
        return
    end

    meta = toStruct(getKeyMetadata(obj.Data, head));
    nodeMeta = toStruct(getNodeMetadata(obj.Data, head));
    for name = string(fieldnames(nodeMeta))'
        meta.(name) = nodeMeta.(name);
    end
end

function s = toStruct(meta)
    if isempty(meta)
        s = struct();
    else
        s = meta;
    end
end

function mustBeTable(value, key)
    if ~isa(value, "matlab.io.config.ConfigurationData") || ~isscalar(value)
        error("setformat:InvalidKey", "Key '%s' is not a table.", key);
    end
end

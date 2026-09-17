function obj = setformat(obj, keyPath, nvargs)
    %SETFORMAT Set format metadata on configuration data keys
    %   obj = setformat(obj, key, Name=Value) sets metadata properties.
    %   obj = setformat(obj, [key1, key2], Name=Value) sets on multiple keys.
    %   obj = setformat(obj, "a.b.c", Name=Value) navigates nested paths.
    %
    %   Returns a modified copy (value class semantics). Creates metadata
    %   entries as needed.
    %
    %   Name-value pairs: ContainerStyle, ScalarStyle, IsArray, Comments,
    %   TrailingComment, and TOML-specific properties for TOMLData.
    %
    %   Example:
    %       data = setformat(data, "ports", ContainerStyle="flow", IsArray=true);
    %
    %   See also: getformat, resetformat, YAMLMetadata, TOMLMetadata

    arguments
        obj
        keyPath (1,:) string
        nvargs.ContainerStyle
        nvargs.ScalarStyle
        nvargs.IsArray
        nvargs.Comments
        nvargs.TrailingComment
        nvargs.IntegerFormat
        nvargs.FloatFormat
        nvargs.StringMultiline
        nvargs.TableFormat
        nvargs.ArrayOfTables
    end

    for i = 1:numel(keyPath)
        obj = setOneKey(obj, keyPath(i), nvargs);
    end
end

function obj = setOneKey(obj, keyPath, nvargs)
    parts = split(keyPath, ".");
    if numel(parts) > 1
        obj = setNestedKey(obj, parts, nvargs);
        return;
    end

    leafKey = parts(1);
    resolved = resolveKey(obj, leafKey);
    if ismissing(resolved)
        error("setformat:InvalidKey", "Key '%s' not found.", leafKey);
    end

    val = obj.Data{resolved};
    if isa(val, 'matlab.io.config.ConfigurationData')
        if isempty(val.Metadata)
            val.Metadata = makeMetadata(obj);
        end
        val.Metadata = applyProperties(val.Metadata, nvargs);
        obj.Data{resolved} = val;
        return;
    end

    if isempty(obj.Metadata)
        obj.Metadata = makeMetadata(obj);
    end
    if ~isConfigured(obj.Metadata.Keys) || ~isKey(obj.Metadata.Keys, resolved)
        obj.Metadata.Keys = matlab.io.config.internal.assignCellDictionaryKey(obj.Metadata.Keys, resolved, makeMetadata(obj));
    end
    meta = matlab.io.config.internal.lookupCellDictionaryKey(obj.Metadata.Keys, resolved);
    meta = applyProperties(meta, nvargs);
    obj.Metadata.Keys = matlab.io.config.internal.assignCellDictionaryKey(obj.Metadata.Keys, resolved, meta);
end

function obj = setNestedKey(obj, parts, nvargs)
    resolved = resolveKey(obj, parts(1));
    if ismissing(resolved)
        error("setformat:InvalidKey", "Key '%s' not found.", parts(1));
    end
    val = obj.Data{resolved};
    if ~isa(val, 'matlab.io.config.ConfigurationData')
        error("setformat:InvalidKey", "Key '%s' is not a nested object.", parts(1));
    end
    remainingPath = join(parts(2:end), ".");
    args = namedargs2cell(nvargs);
    val = setformat(val, remainingPath, args{:});
    obj.Data{resolved} = val;
end

function meta = makeMetadata(obj)
    if isa(obj, 'matlab.io.config.TOMLData')
        meta = matlab.io.config.TOMLMetadata();
    else
        meta = matlab.io.config.YAMLMetadata();
    end
end

function meta = applyProperties(meta, nvargs)
    fields = fieldnames(nvargs);
    for i = 1:numel(fields)
        meta.(fields{i}) = nvargs.(fields{i});
    end
end

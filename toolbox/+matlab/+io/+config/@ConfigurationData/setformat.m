function obj = setformat(obj, keyPath, options)
    %SETFORMAT Set the format metadata of a key or table
    %   obj = setformat(obj, key, Name=Value) sets format properties used
    %   when writing key. Setting a property to "auto" clears it.
    %
    %   obj = setformat(obj, "a.b.c", Name=Value) navigates nested tables.
    %
    %   obj = setformat(obj, Name=Value) sets properties of obj's own table.
    %
    %   TOMLData properties:
    %     ArrayStyle, TableStyle, TableArrayStyle, StringEscapeStyle,
    %     StringLayout - same values as the writetoml options
    %     IntegerFormat - "dec", "hex", "oct", or "bin"
    %     FloatFormat   - "fixed" or "scientific"
    %     Comments      - comment lines written above the key
    %
    %   YAMLData properties:
    %     ContainerStyle - "block" or "flow" (mappings and sequences)
    %     ScalarStyle    - "plain", "single-quoted", "double-quoted",
    %                      "literal", or "folded"
    %     KeyStyle       - "plain", "single-quoted", or "double-quoted"
    %
    %   Per-key metadata takes precedence over writer options.
    %
    %   Example:
    %       config = setformat(config, "port", IntegerFormat="hex");
    %
    %   See also GETFORMAT, RESETFORMAT

    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        keyPath (1,1) string = missing
        options.ArrayStyle
        options.TableStyle
        options.TableArrayStyle
        options.StringEscapeStyle
        options.StringLayout
        options.IntegerFormat
        options.FloatFormat
        options.Comments
        options.ContainerStyle
        options.ScalarStyle
        options.KeyStyle
    end

    options = validateFormatOptions(obj, options);

    if ismissing(keyPath)
        obj.Data = setTableMetadata(obj.Data, ...
            applyOptions(getTableMetadata(obj.Data), options));
        return
    end

    [head, rest] = splitFormatPath(obj.Data, keyPath);
    if rest ~= ""
        child = getValue(obj.Data, head);
        if ~isa(child, "matlab.io.config.ConfigurationData") || ~isscalar(child)
            error("setformat:InvalidKey", "Key '%s' is not a table.", head);
        end
        args = namedargs2cell(options);
        child = setformat(child, rest, args{:});
        obj.Data = setValue(obj.Data, head, child);
        return
    end

    names = string(fieldnames(options))';
    isKeyLevel = ismember(names, keyLevelProperties());
    keyOptions = rmfield(options, names(~isKeyLevel));
    nodeOptions = rmfield(options, names(isKeyLevel));

    obj.Data = setKeyMetadata(obj.Data, head, ...
        applyOptions(getKeyMetadata(obj.Data, head), keyOptions));
    obj.Data = setNodeMetadata(obj.Data, head, ...
        applyOptions(getNodeMetadata(obj.Data, head), nodeOptions));
end

function options = validateFormatOptions(obj, options)
    format = formatName(obj);
    allowed = matlab.io.config.internal.formatProperties(format);
    for name = string(fieldnames(options))'
        if ~isfield(allowed, name)
            error("setformat:InvalidProperty", ...
                "'%s' is not a %s format property.", name, upper(format));
        end
        value = string(options.(name));
        if name == "Comments"
            options.(name) = value(:);
        else
            if ~isscalar(value) || ~ismember(value, allowed.(name))
                error("setformat:InvalidValue", ...
                    "%s must be one of: %s.", name, join(allowed.(name), ", "));
            end
            options.(name) = value;
        end
    end
end

function meta = applyOptions(meta, options)
    if isempty(meta)
        meta = struct();
    end
    for name = string(fieldnames(options))'
        value = options.(name);
        isCleared = (name == "Comments" && isempty(value)) ...
            || (name ~= "Comments" && value == "auto");
        if isCleared
            if isfield(meta, name)
                meta = rmfield(meta, name);
            end
        else
            meta.(name) = value;
        end
    end
end

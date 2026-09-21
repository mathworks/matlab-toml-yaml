function obj = expand(cs, format, options)
    %expand Convert a CompactStruct to a ConfigurationData object.
    %   obj = expand(cs, format) returns a YAMLData or TOMLData object.
    %
    %   cs is a struct with fields:
    %     Keys           - (1×n string) key names
    %     Values         - (1×n cell) scalar values or nested CompactStructs
    %     NullIndices    - (1×m double) indices where value is null
    %     DatetimeIndices - (1×m double) indices where value is a datetime
    %     QuotedIndices  - (1×m double) (unused, retained for write path)
    %
    %   format is "yaml" or "toml".
    %
    %   Optional name-value:
    %     DatetimeType - "string" (default) or "datetime". When "datetime",
    %                    TOML datetime strings are parsed as datetime objects.

    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
        options.Recursive (1,1) logical = true
        options.Lazy (1,1) logical = false
    end

    if options.Lazy
        store = matlab.io.config.internal.CompactStructStore.fromCompactStruct( ...
            cs, format, DatetimeType=options.DatetimeType);
        obj = matlab.io.config.ConfigurationData.fromStore(store, format);
        return
    end

    isYAML = (format == "yaml");

    if isYAML
        obj = matlab.io.config.YAMLData;
    else
        obj = matlab.io.config.TOMLData;
    end

    n = numel(cs.Keys);
    isNull = false(1, n);
    isNull(cs.NullIndices) = true;
    isDatetime = false(1, n);
    isDatetime(cs.DatetimeIndices) = true;
    for i = 1:n
        key = cs.Keys(i);

        if isNull(i)
            obj.(key) = missing;
            continue
        end

        val = cs.Values{i};

        if isstruct(val) && isfield(val, 'Keys')
            obj.(key) = expandOrWrap(val, format, options);

        elseif iscell(val) && ~isempty(val) && isstruct(val{1}) && isfield(val{1}, 'Keys')
            children = cellfun(@(c) expandOrWrap(c, format, options), val);
            obj.(key) = vertcat(children(:));

        elseif isDatetime(i)
            if options.DatetimeType == "datetime"
                obj.(key) = matlab.io.config.internal.read.parseTOMLDatetime(val);
            else
                obj.(key) = val;
            end

        elseif ~isscalar(val) && ~isempty(val)
            obj.(key) = val(:);
        else
            obj.(key) = val;
        end
    end
end

function child = expandOrWrap(childCS, format, options)
    if options.Recursive
        child = matlab.io.config.internal.read.expand(childCS, format, ...
            DatetimeType=options.DatetimeType);
    else
        store = matlab.io.config.internal.CompactStructStore.fromCompactStruct( ...
            childCS, format, DatetimeType=options.DatetimeType);
        child = matlab.io.config.ConfigurationData.fromStore(store, format);
    end
end

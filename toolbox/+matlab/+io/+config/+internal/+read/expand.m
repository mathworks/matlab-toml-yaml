function obj = expand(cs, format, options)
%expand Convert a CompactStruct to a ConfigurationData object.
%   obj = expand(cs, format) returns a YAMLData or TOMLData object.
%
%   cs is a struct with fields:
%     Keys           - (1×n string) key names
%     Values         - (1×n cell) scalar values or nested CompactStructs
%     NullIndices    - (1×m double) indices where value is null
%     DatetimeIndices - (1×m double) indices where value is a datetime
%     QuotedIndices  - (1×m double) indices where scalar was quoted (YAML only)
%     NodeStyle      - (optional) struct or [] — per-node format metadata
%     KeyStyles      - (optional, 1×n cell) per-key format metadata
%
%   format is "yaml" or "toml".
%
%   Optional name-value:
%     DatetimeType - "string" (default) or "datetime". When "datetime" and
%                    format is "yaml", quoted scalars that look like dates
%                    are parsed as datetime objects.

    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
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
    isQuoted = false(1, n);
    isQuoted(cs.QuotedIndices) = true;

    for i = 1:n
        key = cs.Keys(i);

        if isNull(i)
            obj.(key) = missing;
            continue
        end

        val = cs.Values{i};

        if isstruct(val) && isfield(val, 'Keys')
            obj.(key) = matlab.io.config.internal.read.expand(val, format, ...
                DatetimeType=options.DatetimeType);

        elseif iscell(val) && ~isempty(val) && isstruct(val{1}) && isfield(val{1}, 'Keys')
            children = cellfun(@(c) matlab.io.config.internal.read.expand(c, format, ...
                DatetimeType=options.DatetimeType), val);
            obj.(key) = vertcat(children(:));

        elseif isDatetime(i)
            if options.DatetimeType == "datetime"
                obj.(key) = parseTOMLDatetime(val);
            else
                obj.(key) = val;
            end

        elseif isYAML && isstring(val) && isscalar(val)
            obj.(key) = matlab.io.config.internal.read.parseYAMLScalar( ...
                val, isQuoted(i), options.DatetimeType);

        elseif isYAML && isstring(val) && ~isscalar(val)
            obj.(key) = parseYAMLSequence(val, options.DatetimeType);

        else
            obj.(key) = val;
        end
    end

    obj = applyStyles(obj, cs, format);
end

function obj = applyStyles(obj, cs, format)
    hasNodeStyle = isfield(cs, 'NodeStyle') && ~isempty(cs.NodeStyle);
    hasKeyStyles = isfield(cs, 'KeyStyles');
    if ~hasNodeStyle && ~hasKeyStyles
        return
    end

    meta = [];
    if hasNodeStyle
        meta = styleStructToMetadata(cs.NodeStyle, format);
    end

    if hasKeyStyles
        for i = 1:numel(cs.KeyStyles)
            if ~isempty(cs.KeyStyles{i})
                if isempty(meta)
                    meta = makeDefaultMetadata(format);
                end
                meta.Keys{cs.Keys(i)} = styleStructToMetadata(cs.KeyStyles{i}, format);
            end
        end
    end

    if ~isempty(meta)
        obj = setmetadata(obj, meta);
    end
end

function meta = styleStructToMetadata(s, format)
    args = {};
    fields = fieldnames(s);
    for i = 1:numel(fields)
        args = [args, fields(i), {s.(fields{i})}]; %#ok<AGROW>
    end
    if format == "toml"
        meta = matlab.io.config.TOMLMetadata(args{:});
    else
        meta = matlab.io.config.YAMLMetadata(args{:});
    end
end

function meta = makeDefaultMetadata(format)
    if format == "toml"
        meta = matlab.io.config.TOMLMetadata();
    else
        meta = matlab.io.config.YAMLMetadata();
    end
end

function result = parseYAMLSequence(values, datetimeType)
    parsed = cell(numel(values), 1);
    for j = 1:numel(values)
        parsed{j} = matlab.io.config.internal.read.parseYAMLScalar( ...
            values(j), false, datetimeType);
    end
    firstClass = class(parsed{1});
    if all(cellfun(@(x) isa(x, firstClass), parsed))
        result = vertcat(parsed{:});
    else
        result = parsed;
    end
end

function dt = parseTOMLDatetime(str)
    if contains(str, "T")
        if endsWith(str, "Z") || ~isempty(regexp(str, '[+-]\d{2}:\d{2}$', 'once'))
            dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ssXXX", TimeZone="UTC");
        else
            dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ss");
        end
    elseif contains(str, ":")
        dt = datetime(str, InputFormat="HH:mm:ss");
    else
        dt = datetime(str, InputFormat="uuuu-MM-dd");
    end
end

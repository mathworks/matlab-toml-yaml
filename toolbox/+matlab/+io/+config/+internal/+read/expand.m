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
        options.DatetimeType (1,1) string {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "string"
    end

    if format == "yaml"
        obj = matlab.io.config.YAMLData;
    else
        obj = matlab.io.config.TOMLData;
    end

    isYAML = (format == "yaml");
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
            obj.(key) = [];
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
            obj.(key) = val;

        elseif isYAML && isstring(val) && isscalar(val)
            obj.(key) = matlab.io.config.internal.read.parseYAMLScalar( ...
                val, isQuoted(i), options.DatetimeType);

        else
            obj.(key) = val;
        end
    end
end

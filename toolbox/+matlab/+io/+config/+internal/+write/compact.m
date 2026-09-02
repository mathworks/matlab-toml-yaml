function cs = compact(obj, format, precision)
%compact Convert ConfigurationData to a CompactStruct for MEX serialization.
%   cs = compact(obj, format) returns a struct with fields:
%     Keys           - (1×n string) key names in insertion order
%     Values         - (1×n cell) scalar values or nested CompactStructs
%     NullIndices    - (1×m double) indices where value is null
%     DatetimeIndices - (1×m double) indices where value is a datetime
%     QuotedIndices  - (1×m double) indices where scalar needs quoting (YAML only)
%
%   format is "yaml" or "toml". When "yaml", scalar Values are pre-formatted
%   strings and QuotedIndices is populated. When "toml", scalar Values are
%   raw typed MATLAB values and QuotedIndices is empty.

    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        precision (1,1) double {mustBeInteger, mustBePositive} = 6
    end

    isYAML = (format == "yaml");

    k = keys(obj);
    n = numel(k);
    values = cell(1, n);
    nullIndices = [];
    datetimeIndices = [];
    quotedIndices = [];

    for i = 1:n
        val = obj.(k(i));

        if isa(val, 'missing') || (isnumeric(val) && isempty(val))
            nullIndices(end+1) = i; %#ok<AGROW>
            values{i} = [];

        elseif isa(val, 'matlab.io.config.ConfigurationData')
            if isempty(val)
                nullIndices(end+1) = i; %#ok<AGROW>
                values{i} = [];
            elseif isscalar(val)
                values{i} = matlab.io.config.internal.write.compact(val, format, precision);
            else
                nc = numel(val);
                children = cell(1, nc);
                for j = 1:nc
                    children{j} = matlab.io.config.internal.write.compact(val(j), format, precision);
                end
                values{i} = children;
            end

        elseif isa(val, 'datetime')
            datetimeIndices(end+1) = i; %#ok<AGROW>
            values{i} = val;

        elseif isYAML && isscalar(val) && ~iscell(val)
            [text, quoted] = matlab.io.config.internal.write.formatYAMLScalar(val, precision);
            values{i} = text;
            if quoted
                quotedIndices(end+1) = i; %#ok<AGROW>
            end

        else
            values{i} = val;
        end
    end

    cs.Keys = k(:)';
    cs.Values = values;
    cs.NullIndices = nullIndices;
    cs.DatetimeIndices = datetimeIndices;
    cs.QuotedIndices = quotedIndices;
end

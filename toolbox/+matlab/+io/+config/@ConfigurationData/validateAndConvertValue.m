function value = validateAndConvertValue(obj, value, key)
%VALIDATEANDCONVERTVALUE Validate and optionally convert a value
%   Subclasses can override to add format-specific type handling.
%   Returns the (possibly converted) value, or throws an error.
%
%   Objects with SourceFormat "unknown" accept all MATLAB types
%   since they are not constrained by serialization requirements.

if obj.SourceFormat == "unknown"
    return;
end

% Handle cell arrays recursively
if iscell(value)
    for i = 1:numel(value)
        value{i} = obj.validateAndConvertValue(value{i}, key);
    end
    return;
end

% Handle struct recursively
if isstruct(value)
    fields = fieldnames(value);
    for i = 1:numel(value)
        for j = 1:numel(fields)
            value(i).(fields{j}) = obj.validateAndConvertValue(value(i).(fields{j}), key);
        end
    end
    return;
end

% Allowed base types (numeric must be real - complex checked separately below)
if (isnumeric(value) && isreal(value)) || islogical(value) || ischar(value) || isstring(value)
    return;  % OK
end

% ConfigurationData is always allowed
if isa(value, 'matlab.io.config.ConfigurationData')
    return;  % OK
end

% missing represents a null/absent config value
if isa(value, 'missing')
    return;  % OK
end

% Empty values
if isempty(value)
    return;  % OK (will revisit serialization)
end

% Datetime - base class converts to ISO 8601 string
% Subclasses (like TOMLData) can override to keep native datetime
if isa(value, 'datetime')
    value = string(value, 'yyyy-MM-dd''T''HH:mm:ss');
    return;
end

% Duration - convert to ISO 8601 duration or seconds
if isa(value, 'duration')
    value = seconds(value);  % Convert to numeric seconds
    return;
end

% Disallowed types with helpful messages
if isa(value, 'function_handle')
    error('ConfigurationData:InvalidType', ...
        ['Cannot assign function_handle to key "%s".\n' ...
        'Function handles cannot be serialized to configuration files.'], key);
end

if isa(value, 'table') || isa(value, 'timetable')
    error('ConfigurationData:InvalidType', ...
        ['Cannot assign %s to key "%s".\n' ...
        'Convert to struct first: struct(yourTable)'], class(value), key);
end

if isa(value, 'categorical')
    error('ConfigurationData:InvalidType', ...
        ['Cannot assign categorical to key "%s".\n' ...
        'Convert to string first: string(yourCategorical)'], key);
end

if isnumeric(value) && ~isreal(value)
    error('ConfigurationData:InvalidType', ...
        ['Cannot assign complex numbers to key "%s".\n' ...
        'Configuration files do not support imaginary numbers.'], key);
end

% Generic unsupported type
error('ConfigurationData:InvalidType', ...
    ['Cannot assign %s to key "%s".\n' ...
    'Supported types: numeric, logical, char, string, cell, struct, ' ...
    'datetime, duration, and ConfigurationData objects.'], class(value), key);
end

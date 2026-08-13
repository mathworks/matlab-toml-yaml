function writejson(data, filename, options)
%WRITEJSON Write data to a JSON file
%   WRITEJSON(data, filename) writes the data to a JSON file with pretty
%   printing enabled by default.
%
%   WRITEJSON(data, filename, Name, Value) specifies additional options:
%
%       'PrettyPrint' - Format output with indentation and newlines
%           true    - (default) Human-readable formatting
%           false   - Compact single-line output
%
%       'Precision'   - Number of significant digits for numeric values
%           6       - (default)
%
%       'EmptyValue'  - How to handle empty arrays ([])
%           'array' - (default) Write as empty JSON array []
%           'null'  - Write as JSON null
%           'omit'  - Omit the key entirely from output
%
%       'ArrayKeys'   - Keys that should always be arrays
%           string array - Keys to force as JSON arrays even if scalar
%           []          - (default) No forced arrays
%
%   To write explicit JSON null, assign missing to a key:
%
%   Supported input types:
%       - JSONData, YAMLData, TOMLData, INIData (ConfigurationData)
%       - struct
%       - dictionary
%       - containers.Map
%
%   Original key names are preserved, including keys with special characters
%   like hyphens or keys starting with numbers. Key order from the source
%   file is preserved for ConfigurationData objects.
%
%   Example:
%       % Write JSONData to file
%       config = jsondata();
%       config.("my-key") = 'value';  % Key with hyphen preserved
%       writejson(config, 'config.json');
%
%       % Write without pretty printing
%       writejson(config, 'compact.json', 'PrettyPrint', false);
%
%       % Force specific keys to be arrays (useful for API schemas)
%       config = jsondata();
%       config.ports = 8080;  % Scalar in MATLAB
%       writejson(config, 'config.json', 'ArrayKeys', "ports");
%       % Output: {"ports": [8080]}
%
%       % Multiple keys (e.g., Kubernetes manifests)
%       config.spec.containers.name = "web";
%       config.spec.containers.ports.containerPort = 3000;
%       writejson(config, 'deployment.json', ...
%           'ArrayKeys', ["containers", "ports"]);
%       % Both containers and ports become arrays even if single element
%
%   See also: readjson, jsondata, matlab.io.config.JSONData, jsonencode

    arguments
        data
        filename {mustBeTextScalar, mustBeNonzeroLengthText} = "untitled.json"
        options.PrettyPrint (1,1) logical = true
        options.Precision (1,1) {mustBePositive, mustBeInteger} = 6
        options.EmptyValue {mustBeMember(options.EmptyValue, ["array", "null", "omit"])} = "array"
        options.ArrayKeys (:,1) string = string.empty
    end

    % Serialize to JSON string with preserved key order
    jsonText = encodeValue(data, 0, options.PrettyPrint, options.EmptyValue, options.ArrayKeys);

    % Write to file
    fid = fopen(filename, 'w', 'n', 'UTF-8');
    if fid == -1
        error('writejson:FileError', 'Could not open file for writing: %s', filename);
    end
    try
        fprintf(fid, '%s', jsonText);
        fclose(fid);
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function str = encodeValue(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Recursively encode a value to a JSON string.
% Dispatches to type-specific encoders; leaf values use jsonencode.

    if isa(data, 'matlab.io.config.ConfigurationData')
        if numel(data) > 1
            % Array of ConfigurationData objects -> JSON array
            str = encodeArray(num2cell(data), depth, prettyPrint, emptyValueOption, arrayKeys);
        else
            str = encodeConfigObject(data, depth, prettyPrint, emptyValueOption, arrayKeys);
        end
    elseif iscell(data)
        str = encodeArray(data, depth, prettyPrint, emptyValueOption, arrayKeys);
    elseif isstruct(data)
        if isscalar(data)
            str = encodeStructObject(data, depth, prettyPrint, emptyValueOption, arrayKeys);
        else
            % Struct array -> JSON array
            str = encodeArray(num2cell(data), depth, prettyPrint, emptyValueOption, arrayKeys);
        end
    elseif isa(data, 'containers.Map')
        str = encodeMapObject(data, depth, prettyPrint, emptyValueOption, arrayKeys);
    elseif isa(data, 'dictionary')
        str = encodeDictObject(data, depth, prettyPrint, emptyValueOption, arrayKeys);
    elseif isa(data, 'missing')
        str = 'null';
    elseif isempty(data) && (isnumeric(data) || islogical(data))
        if emptyValueOption == "null"
            str = 'null';
        else
            str = '[]';
        end
    else
        % Leaf values: scalars, primitive arrays (numeric, string, logical)
        str = indentedEncode(data, depth, prettyPrint);
    end
end

function str = encodeConfigObject(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Encode a scalar ConfigurationData as a JSON object.
% Uses keys() which returns OriginalKeys, preserving insertion order.

    allKeys = keys(data);
    pairs = {};
    for i = 1:numel(allKeys)
        key = allKeys(i);
        value = data.(key);
        if isempty(value) && (isnumeric(value) || islogical(value)) && emptyValueOption == "omit"
            continue;
        end
        % Force array if key matches ArrayKeys
        if shouldForceArray(key, value, arrayKeys)
            value = {value};
        end
        valueStr = encodeValue(value, depth + 1, prettyPrint, emptyValueOption, arrayKeys);
        pairs{end+1} = [jsonencode(char(key)), ': ', valueStr];
    end
    str = formatObject(pairs, depth, prettyPrint);
end

function str = encodeStructObject(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Encode a scalar struct as a JSON object.
% fieldnames() preserves struct field order.

    fields = fieldnames(data);
    pairs = {};
    for i = 1:numel(fields)
        fieldName = fields{i};
        value = data.(fieldName);
        if isempty(value) && (isnumeric(value) || islogical(value)) && emptyValueOption == "omit"
            continue;
        end
        % Force array if key matches ArrayKeys
        if shouldForceArray(fieldName, value, arrayKeys)
            value = {value};
        end
        valueStr = encodeValue(value, depth + 1, prettyPrint, emptyValueOption, arrayKeys);
        pairs{end+1} = [jsonencode(fieldName), ': ', valueStr];
    end
    str = formatObject(pairs, depth, prettyPrint);
end

function str = encodeMapObject(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Encode a containers.Map as a JSON object.
% Note: Map keys are always alphabetically sorted.

    allKeys = keys(data);
    pairs = {};
    for i = 1:numel(allKeys)
        keyStr = allKeys{i};
        value = data(keyStr);
        if isempty(value) && (isnumeric(value) || islogical(value)) && emptyValueOption == "omit"
            continue;
        end
        % Force array if key matches ArrayKeys
        if shouldForceArray(keyStr, value, arrayKeys)
            value = {value};
        end
        valueStr = encodeValue(value, depth + 1, prettyPrint, emptyValueOption, arrayKeys);
        pairs{end+1} = [jsonencode(keyStr), ': ', valueStr];
    end
    str = formatObject(pairs, depth, prettyPrint);
end

function str = encodeDictObject(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Encode a dictionary as a JSON object.

    allKeys = keys(data);
    pairs = {};
    for i = 1:numel(allKeys)
        key = allKeys(i);
        value = data(key);
        if iscell(value)
            value = value{1};
        end
        if isempty(value) && (isnumeric(value) || islogical(value)) && emptyValueOption == "omit"
            continue;
        end
        % Force array if key matches ArrayKeys
        if shouldForceArray(key, value, arrayKeys)
            value = {value};
        end
        valueStr = encodeValue(value, depth + 1, prettyPrint, emptyValueOption, arrayKeys);
        pairs{end+1} = [jsonencode(char(key)), ': ', valueStr];
    end
    str = formatObject(pairs, depth, prettyPrint);
end

function str = encodeArray(data, depth, prettyPrint, emptyValueOption, arrayKeys)
% Encode a cell array as a JSON array.

    if isempty(data)
        str = '[]';
        return;
    end
    elements = cell(1, numel(data));
    for i = 1:numel(data)
        elements{i} = encodeValue(data{i}, depth + 1, prettyPrint, emptyValueOption, arrayKeys);
    end
    str = formatArray(elements, depth, prettyPrint);
end

function str = formatObject(pairs, depth, prettyPrint)
% Assemble key-value pair strings into a JSON object with optional indentation.

    if isempty(pairs)
        str = '{}';
        return;
    end
    if prettyPrint
        childIndent = repmat('  ', 1, depth + 1);
        closeIndent = repmat('  ', 1, depth);
        str = ['{', char(10)];
        for i = 1:numel(pairs)
            str = [str, childIndent, pairs{i}];
            if i < numel(pairs)
                str = [str, ','];
            end
            str = [str, char(10)];
        end
        str = [str, closeIndent, '}'];
    else
        str = ['{', strjoin(pairs, ', '), '}'];
    end
end

function str = formatArray(elements, depth, prettyPrint)
% Assemble element strings into a JSON array with optional indentation.

    if isempty(elements)
        str = '[]';
        return;
    end
    if prettyPrint
        childIndent = repmat('  ', 1, depth + 1);
        closeIndent = repmat('  ', 1, depth);
        str = ['[', char(10)];
        for i = 1:numel(elements)
            str = [str, childIndent, elements{i}];
            if i < numel(elements)
                str = [str, ','];
            end
            str = [str, char(10)];
        end
        str = [str, closeIndent, ']'];
    else
        str = ['[', strjoin(elements, ', '), ']'];
    end
end

function str = indentedEncode(data, depth, prettyPrint)
% Encode leaf values via jsonencode, re-indenting any multiline output.
% jsonencode uses 2-space relative indentation; we prepend depth*2 spaces
% to lines 2+ so the absolute indentation is correct when nested.

    if prettyPrint
        str = jsonencode(data, 'PrettyPrint', true);
    else
        str = jsonencode(data);
    end
    if ~isempty(strfind(str, char(10)))
        lines = strsplit(str, char(10));
        baseIndent = repmat('  ', 1, depth);
        str = lines{1};
        for i = 2:numel(lines)
            str = [str, char(10), baseIndent, lines{i}];
        end
    end
end

function tf = shouldForceArray(key, value, arrayKeys)
%SHOULDFORCEARRAY Determine if scalar value should be forced to array
%   Returns true if:
%     - key matches one of arrayKeys
%     - value is not already a cell array
%     - value is not already an array (numel > 1)
%     - value is not empty (handled by EmptyValue option)
%     - value is not missing (JSON null)

    tf = false;

    % No array keys specified
    if isempty(arrayKeys)
        return;
    end

    % Key doesn't match
    if ~any(strcmp(key, arrayKeys))
        return;
    end

    % Already a cell array (explicitly marked as array)
    if iscell(value)
        return;
    end

    % Already an array of ConfigurationData objects
    if isa(value, 'matlab.io.config.ConfigurationData') && numel(value) > 1
        return;
    end

    % Struct array
    if isstruct(value) && numel(value) > 1
        return;
    end

    % Numeric/string/logical array with multiple elements
    if (isnumeric(value) || isstring(value) || islogical(value)) && numel(value) > 1
        return;
    end

    % Empty values handled by EmptyValue option
    if isempty(value)
        return;
    end

    % Missing values (JSON null) should not be wrapped
    if isa(value, 'missing')
        return;
    end

    % All checks passed - this is a scalar that should be forced to array
    tf = true;
end

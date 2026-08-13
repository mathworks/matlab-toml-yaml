function data = readjson(filename, options)
%READJSON Read JSON file into a JSONData object
%   data = READJSON(filename) reads the JSON file and returns a JSONData
%   object with dot notation access to the configuration values.
%
%   data = READJSON(filename, Name, Value) specifies additional options:
%
%       'SequenceRule' - How to convert JSON arrays to MATLAB types
%           'auto'  - (default) Numeric arrays stay numeric, string arrays
%                     stay string, mixed arrays become cell arrays
%           'cell'  - All arrays are returned as cell arrays
%
%   JSON null values are returned as missing. Use ismissing() to detect them.
%   This distinguishes null from empty arrays ([]).
%
%   Original key names are preserved, including keys with special characters
%   like hyphens or keys starting with numbers. Access via:
%       data.("my-key")   % Original key
%       data.my_key       % Aliased access (if key contains special chars)
%
%   Example:
%       % Read a package.json file
%       pkg = readjson('package.json');
%       disp(pkg.name)
%       disp(pkg.version)
%
%       % Access keys with special characters
%       data = readjson('config.json');
%       value = data.("build-system");  % Access original key
%
%       % Force all arrays to cells
%       pkg = readjson('package.json', 'SequenceRule', 'cell');
%
%   See also: writejson, jsondata, matlab.io.config.JSONData, jsondecode

    arguments
        filename {mustBeTextScalar, mustBeNonzeroLengthText, mustBeFile}
        options.SequenceRule {mustBeMember(options.SequenceRule, ["auto", "cell"])} = "auto"
    end

    % Read file content
    fileContent = fileread(filename);

    % Extract original keys from JSON text (before jsondecode mangles them)
    keyMap = extractJSONKeys(fileContent);

    % Extract array context for single-element array preservation
    arrayKeyMap = extractArrayKeys(fileContent);

    % Extract null keys for explicit null representation
    nullKeyMap = extractNullKeys(fileContent);

    % Parse JSON using built-in jsondecode
    try
        rawData = jsondecode(fileContent);
    catch ME
        error('readjson:ParseError', 'Failed to parse JSON file: %s\n%s', filename, ME.message);
    end

    % Convert to JSONData hierarchy, using original keys
    data = convertToJSONData(rawData, keyMap, options.SequenceRule, arrayKeyMap, nullKeyMap, '');
end

function keyMap = extractJSONKeys(jsonText)
%EXTRACTJSONKEYS Extract original key names from JSON text
%   Returns a containers.Map mapping mangled keys to original keys.
%   jsondecode mangles keys (e.g., "this-name" -> "this_name"), so we
%   need to extract the original keys before parsing.

    keyMap = containers.Map('KeyType', 'char', 'ValueType', 'char');

    % Find all quoted keys in JSON objects using regex
    % Pattern: "key"\s*: matching key names in JSON
    pattern = '"([^"\\]*(?:\\.[^"\\]*)*)"\s*:';
    matches = regexp(jsonText, pattern, 'tokens');

    % For each original key, compute what jsondecode will mangle it to
    for i = 1:numel(matches)
        originalKey = matches{i}{1};
        % jsondecode uses makeValidName to convert keys
        mangledKey = matlab.lang.makeValidName(originalKey);
        keyMap(mangledKey) = originalKey;
    end
end

function arrayKeyMap = extractArrayKeys(jsonText)
%EXTRACTARRAYKEYS Identify keys with array values in raw JSON
%   Returns a containers.Map where keys are the JSON key names and values
%   are true if that key has an array value somewhere in the JSON.
%   This enables SequenceRule='cell' to preserve single-element arrays,
%   which jsondecode otherwise converts to scalar structs.

    arrayKeyMap = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    % Pattern: "key" : [ (with optional whitespace)
    % Captures the key name for keys that have array values
    pattern = '"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*\[';
    matches = regexp(jsonText, pattern, 'tokens');

    for i = 1:numel(matches)
        key = matches{i}{1};
        arrayKeyMap(key) = true;
    end
end

function nullKeyMap = extractNullKeys(jsonText)
%EXTRACTNULLKEYS Identify keys with null values in raw JSON
%   Returns a containers.Map where keys are the JSON key names and values
%   are true if that key has a null value somewhere in the JSON.
%   This enables explicit null representation via missing.

    nullKeyMap = containers.Map('KeyType', 'char', 'ValueType', 'logical');

    % Pattern: "key" : null (with optional whitespace)
    % Lookahead ensures we match null followed by comma, brace, or whitespace
    pattern = '"([^"\\]*(?:\\.[^"\\]*)*)"\s*:\s*null(?=[,}\s\]])';
    matches = regexp(jsonText, pattern, 'tokens');

    for i = 1:numel(matches)
        key = matches{i}{1};
        nullKeyMap(key) = true;
    end
end

function result = convertToJSONData(value, keyMap, sequenceRule, arrayKeyMap, nullKeyMap, currentKey)
%CONVERTTOJSONDATA Recursively convert parsed JSON to JSONData objects
%   Converts struct hierarchies from jsondecode to JSONData objects.
%   Uses keyMap to restore original key names that jsondecode mangled.
%   Uses arrayKeyMap to detect single-element arrays (which jsondecode
%   converts to scalar structs) when SequenceRule='cell'.
%   Uses nullKeyMap to convert empty arrays from null to missing.
%
%   Arguments:
%     value        - Value from jsondecode
%     keyMap       - Map of mangled keys to original keys
%     sequenceRule - 'auto' or 'cell'
%     arrayKeyMap  - Map of keys known to have array values in original JSON
%     nullKeyMap   - Map of keys known to have null values in original JSON
%     currentKey   - Current key being processed (for array/null detection)

    if isstruct(value)
        if isscalar(value)
            % Check if this scalar struct was originally a single-element array
            shouldWrapInCell = false;
            if sequenceRule == "cell" && ~isempty(currentKey) && isKey(arrayKeyMap, currentKey)
                shouldWrapInCell = true;
            end

            % Scalar struct -> JSONData object
            result = matlab.io.config.JSONData();
            fields = fieldnames(value);
            for i = 1:numel(fields)
                mangledKey = fields{i};
                fieldValue = value.(mangledKey);

                % Look up original key name
                if isKey(keyMap, mangledKey)
                    originalKey = keyMap(mangledKey);
                else
                    originalKey = mangledKey;  % Key wasn't mangled
                end

                % Recursively convert nested values
                convertedValue = convertToJSONData(fieldValue, keyMap, sequenceRule, arrayKeyMap, nullKeyMap, originalKey);

                % Use parenthesized indexing to assign with original key
                result.(originalKey) = convertedValue;
            end

            % Wrap in cell if this was originally a single-element array
            if shouldWrapInCell
                result = {result};
            end
        else
            % Struct array (from JSON array of objects)
            % Convert each element to JSONData
            result = cell(size(value));
            for i = 1:numel(value)
                result{i} = convertToJSONData(value(i), keyMap, sequenceRule, arrayKeyMap, nullKeyMap, '');
            end
            % Convert to JSONData array if all elements are JSONData
            allJSON = true;
            for iVal = 1:numel(result)
                if ~isa(result{iVal}, 'matlab.io.config.JSONData')
                    allJSON = false;
                    break;
                end
            end
            if allJSON
                result = [result{:}];
                result = reshape(result, size(value));
            end
            % Apply SequenceRule
            if sequenceRule == "cell" && ~iscell(result)
                result = num2cell(result);
            end
        end
    elseif iscell(value)
        % Cell array (from JSON mixed-type array or string array)
        result = cell(size(value));
        for i = 1:numel(value)
            result{i} = convertToJSONData(value{i}, keyMap, sequenceRule, arrayKeyMap, nullKeyMap, '');
        end
        % For SequenceRule='auto', try to consolidate homogeneous cell arrays
        if sequenceRule == "auto" && ~isempty(result)
            result = consolidateArray(result);
        end
    elseif isnumeric(value) || islogical(value)
        % Numeric or logical array (including empty [] from null)
        % Check if this empty value was originally a JSON null
        if isempty(value) && ~isempty(currentKey) && isKey(nullKeyMap, currentKey)
            result = missing;
        elseif sequenceRule == "cell" && ~isempty(value)
            if isscalar(value)
                % Check if this scalar came from a single-element array
                if ~isempty(currentKey) && isKey(arrayKeyMap, currentKey)
                    result = {value};  % Wrap in cell to preserve array semantics
                else
                    result = value;
                end
            else
                % Multi-element array -> cell array
                result = num2cell(value);
            end
        else
            result = value;
        end
    elseif ischar(value) || isstring(value)
        % String value
        result = string(value);
        if sequenceRule == "cell"
            if isscalar(result)
                % Check if this scalar came from a single-element array
                if ~isempty(currentKey) && isKey(arrayKeyMap, currentKey)
                    result = {char(result)};  % Wrap in cell to preserve array semantics
                end
            else
                % Multi-element string array -> cell array
                result = cellstr(result);
            end
        end
    else
        % Other types - pass through
        result = value;
    end
end

function result = consolidateArray(cellArray)
%CONSOLIDATEARRAY Try to convert cell array to homogeneous array
%   If all elements are the same type (numeric, string, logical, char),
%   consolidate into a native array. Otherwise keep as cell.

    if isempty(cellArray)
        result = cellArray;
        return;
    end

    % Single pass type check
    allScalarString = true; allCharRow = true; allNumericScalar = true; allLogicalScalar = true;
    for iVal = 1:numel(cellArray)
        v = cellArray{iVal};
        if ~(isstring(v) && isscalar(v)); allScalarString = false; end
        if ~(ischar(v) && (isrow(v) || isempty(v))); allCharRow = false; end
        if ~(isnumeric(v) && isscalar(v)); allNumericScalar = false; end
        if ~(islogical(v) && isscalar(v)); allLogicalScalar = false; end
        if ~allScalarString && ~allCharRow && ~allNumericScalar && ~allLogicalScalar; break; end
    end

    % Check if all elements are strings (scalar string)
    if allScalarString
        result = vertcat(cellArray{:});
        return;
    end

    % Check if all elements are char vectors (from jsondecode string arrays)
    if allCharRow
        result = string(cellArray);
        result = result(:);  % Make column vector
        return;
    end

    % Check if all elements are numeric scalars
    if allNumericScalar
        result = vertcat(cellArray{:});
        return;
    end

    % Check if all elements are logical scalars
    if allLogicalScalar
        result = vertcat(cellArray{:});
        return;
    end

    % Check if all elements are JSONData objects
    allJSONData = true;
    for iVal = 1:numel(cellArray)
        if ~isa(cellArray{iVal}, 'matlab.io.config.JSONData')
            allJSONData = false;
            break;
        end
    end
    if allJSONData
        result = vertcat(cellArray{:});
        return;
    end

    % Keep as cell array for mixed types
    result = cellArray;
end

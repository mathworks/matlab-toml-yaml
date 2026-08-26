function data = readtoml(filename, options)
% READTOML Read TOML file and return TOMLData object
%
%   DATA = READTOML(FILENAME) reads a TOML file and returns a TOMLData object
%   with dot notation access and support for special characters in field names.
%
%   DATA = READTOML(FILENAME, Name, Value) specifies options:
%       DatetimeType - How to represent dates ('datetime' | 'string')
%                      Default: 'datetime'
%
% Examples:
%   Read TOML file
%       config = readtoml('pyproject.toml');
%       name = config.project.name;
%       deps = config.("build-system").requires;
%
%   Access with special characters
%       version = config.("project").("version");
%
%   Formatted Display 
%       show(config);
%
%   Convert to struct
%       s = struct(config);
%
% See also WRITETOML, TOMLData

    arguments
        filename (1,1) string {mustBeFile}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["datetime", "string"])} = "datetime"
    end

    % Read file contents
    fileContent = readFileAsString(filename);

    % Parse TOML content
    data = parseToml(fileContent, options.DatetimeType);
end

function content = readFileAsString(filename)
    % Read file and return as string
    fid = fopen(filename, 'r', 'n', 'UTF-8');
    if fid == -1
        error('tomlToolbox:readtoml:FileOpenError', 'Cannot open file: %s', filename);
    end

    try
        content = string(fread(fid, '*char')');
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    fclose(fid);
end

function data = parseToml(content, datetimeType)
    % Parse TOML content string and return TOMLData object
    
    % Initialize root TOMLData
    data = matlab.io.config.TOMLData;
    currentTable = data;
    currentTablePath = "";
    currentArrayIndex = 0;  % Track if we're in an array of tables
    currentArrayPath = "";  % Track which array we're in

    % Split into lines
    lines = splitlines(content);

    % Track array of tables
    arrayOfTables = containers.Map('KeyType', 'char', 'ValueType', 'double');

    i = 1;
    while i <= numel(lines)
        line = strtrim(lines(i));

        % Skip empty lines and comments
        if strlength(line) == 0 || startsWith(line, "#")
            i = i + 1;
            continue;
        end

        % Check for table headers
        if startsWith(line, "[[") && endsWith(line, "]]")
            % Array of tables
            tableName = extractBetween(line, 3, strlength(line) - 2);
            tableName = strtrim(tableName);
            [data, currentTable, currentTablePath, currentArrayIndex, currentArrayPath] = handleArrayOfTables(data, tableName, arrayOfTables);
            i = i + 1;

        elseif startsWith(line, "[") && endsWith(line, "]")
            % Standard table
            tableName = extractBetween(line, 2, strlength(line) - 1);
            tableName = strtrim(tableName);
            [data, currentTable, currentTablePath, currentArrayIndex, currentArrayPath] = handleTable(data, tableName, currentArrayIndex, currentArrayPath);
            % Don't reset currentArrayIndex - handleTable manages array context
            i = i + 1;

        else
            % Key-value pair - check if it spans multiple lines
            if needsMultiLineHandling(line)
                [fullLine, i] = accumulateMultiLineValue(lines, i);
                line = fullLine;
            end
            [data, currentTable] = parseKeyValue(data, currentTable, currentTablePath, currentArrayIndex, currentArrayPath, line, datetimeType, arrayOfTables);
            i = i + 1;
        end
    end
end

function [rootData, tableRef, tablePath, arrayIndex, arrayPath] = handleTable(rootData, tableName, arrayIndex, arrayPath)
    % Handle [table] syntax

    keys = splitDottedKey(tableName);
    tablePath = tableName;

    % Check if this is a nested table within an array of tables
    if strlength(arrayPath) > 0 && startsWith(tableName, arrayPath)
        % We're in a nested context, keep the array index
        % tablePath already set correctly
    else
        % Not in array context anymore
        arrayIndex = 0;
        arrayPath = "";
    end

    % Build the nested structure
    if strlength(arrayPath) > 0 && startsWith(tableName, arrayPath)
        % Nested table in array context - navigate to array element first
        arrayKeys = split(arrayPath, ".");
        arrayData = getDataPath(rootData, arrayPath);

        % Get the current array element
        currentElement = arrayData(arrayIndex);

        % Get the nested path
        if strcmp(tableName, arrayPath)
            tableRef = currentElement;
        else
            nestedPath = extractAfter(tableName, arrayPath + ".");
            nestedKeys = split(nestedPath, ".");

            % Ensure nested path exists - use helper that handles value semantics
            currentElement = ensureNestedPath(currentElement, nestedKeys);

            % Navigate to the final nested table
            tableRef = currentElement;
            for k = 1:numel(nestedKeys)
                tableRef = tableRef.(cleanKey(nestedKeys(k)));
            end
        end

        % Update the array element back
        arrayData(arrayIndex) = currentElement;
        rootData = setDataPath(rootData, arrayKeys, arrayData);
    else
        % Normal table - no array context
        rootData = ensureDataPath(rootData, keys, "");
        tableRef = getDataPath(rootData, tablePath);
    end
end

function data = ensureDataPath(data, pathKeys, currentPath)
    % Ensure a path exists in TOMLData, creating it if necessary
    if isempty(pathKeys)
        return;
    end

    key = char(cleanKey(strtrim(pathKeys(1))));

    if ~isfield(data, key)
        data.(key) = matlab.io.config.TOMLData;
    end

    % Recursively ensure rest of path
    if numel(pathKeys) > 1
        nestedData = data.(key);
        data.(key) = ensureDataPath(nestedData, pathKeys(2:end), currentPath);
    end
end

function data = ensureNestedPath(data, pathKeys)
    % Ensure nested path exists, handling value semantics correctly
    % This recursively creates paths and writes back modifications
    if isempty(pathKeys)
        return;
    end

    key = char(cleanKey(strtrim(pathKeys(1))));

    if ~isfield(data, key)
        data.(key) = matlab.io.config.TOMLData;
    end

    % Recursively ensure rest of path and write back
    if numel(pathKeys) > 1
        nestedData = data.(key);
        data.(key) = ensureNestedPath(nestedData, pathKeys(2:end));
    end
end

function data = setNestedValue(data, pathKeys, finalKey, value)
    % Set a value at a nested path, handling value semantics correctly
    % pathKeys: keys to navigate to the parent table
    % finalKey: the key to set in the final table
    % value: the value to set
    if isempty(pathKeys)
        data.(finalKey) = value;
        return;
    end

    key = char(cleanKey(strtrim(pathKeys(1))));
    nestedData = data.(key);

    if numel(pathKeys) == 1
        % At the final level, set the value
        nestedData.(finalKey) = value;
    else
        % Recursively navigate and set
        nestedData = setNestedValue(nestedData, pathKeys(2:end), finalKey, value);
    end

    % Write back the modified nested data
    data.(key) = nestedData;
end

function data = setNestedValueDirect(data, pathKeys, value)
    % Set a value at a nested path (replaces entire object at that path)
    % pathKeys: keys to navigate to the target
    % value: the value to set at that path
    if isempty(pathKeys)
        data = value;
        return;
    end

    key = char(cleanKey(strtrim(pathKeys(1))));

    if numel(pathKeys) == 1
        % At the final level, set the value
        data.(key) = value;
    else
        % Recursively navigate and set
        nestedData = data.(key);
        data.(key) = setNestedValueDirect(nestedData, pathKeys(2:end), value);
    end
end

function [rootData, tableRef, tablePath, arrayIndex, arrayPath] = handleArrayOfTables(rootData, tableName, arrayOfTables)
    % Handle [[array.of.tables]] syntax
    % This includes nested arrays like [[jobs.steps]] where jobs is already an array

    keys = splitDottedKey(tableName);
    tablePath = string(tableName);

    % Check if this is a nested array within an existing array-of-tables
    % e.g., [[jobs.steps]] where [[jobs]] is already tracked
    parentArrayPath = "";
    parentArrayIndex = 0;
    for k = 1:numel(keys)-1
        testPath = char(join(keys(1:k), "."));
        if isKey(arrayOfTables, testPath)
            parentArrayPath = testPath;
            parentArrayIndex = arrayOfTables(testPath);
        end
    end

    % Handle array element
    lastKey = char(strtrim(keys(end)));

    if strlength(parentArrayPath) > 0
        % Nested array-of-tables within parent array element
        % Navigate to the specific parent array element
        parentArray = getDataPath(rootData, parentArrayPath);
        parentElement = parentArray(parentArrayIndex);

        % Get remaining path after the parent array
        remainingPath = extractAfter(tableName, parentArrayPath + ".");
        remainingKeys = splitDottedKey(remainingPath);

        % Ensure intermediate path exists within the parent element (with value semantics)
        if numel(remainingKeys) > 1
            parentElement = ensureNestedPath(parentElement, remainingKeys(1:end-1));
        end

        % Create new element
        newElement = matlab.io.config.TOMLData;

        if numel(remainingKeys) > 1
            % Get the direct parent and modify it
            directParentPath = join(remainingKeys(1:end-1), ".");
            parent = getDataPathFromObj(parentElement, directParentPath);

            if ~isfield(parent, lastKey)
                % First element
                parent.(lastKey) = newElement;
                arrayIndex = 1;
                arrayPath = tablePath;
                arrayOfTables(tablePath) = arrayIndex;
            elseif isKey(arrayOfTables, tablePath)
                % Append to existing array
                currentArray = parent.(lastKey);
                if isa(currentArray, 'matlab.io.config.TOMLData')
                    parent.(lastKey) = [currentArray, newElement];
                else
                    error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                        'Key "%s" is not a TOMLData array', lastKey);
                end
                arrayIndex = arrayOfTables(tablePath) + 1;
                arrayPath = tablePath;
                arrayOfTables(tablePath) = arrayIndex;
            else
                error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                    'Key "%s" already exists and is not an array of tables', lastKey);
            end

            % Write back the modified parent to parentElement using the path
            parentElement = setNestedValueDirect(parentElement, remainingKeys(1:end-1), parent);
        else
            % Direct child of parent element
            if ~isfield(parentElement, lastKey)
                % First element
                parentElement.(lastKey) = newElement;
                arrayIndex = 1;
                arrayPath = tablePath;
                arrayOfTables(tablePath) = arrayIndex;
            elseif isKey(arrayOfTables, tablePath)
                % Append to existing array
                currentArray = parentElement.(lastKey);
                if isa(currentArray, 'matlab.io.config.TOMLData')
                    parentElement.(lastKey) = [currentArray, newElement];
                else
                    error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                        'Key "%s" is not a TOMLData array', lastKey);
                end
                arrayIndex = arrayOfTables(tablePath) + 1;
                arrayPath = tablePath;
                arrayOfTables(tablePath) = arrayIndex;
            else
                error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                    'Key "%s" already exists and is not an array of tables', lastKey);
            end
        end

        % Write the modified parent element back to the parent array
        parentArray(parentArrayIndex) = parentElement;

        % Write the parent array back to rootData
        parentArrayKeys = splitDottedKey(parentArrayPath);
        rootData = setDataPath(rootData, parentArrayKeys, parentArray);

        tableRef = newElement;
    else
        % Top-level array-of-tables (original behavior)

        % Ensure parent path exists
        if numel(keys) > 1
            rootData = ensureDataPath(rootData, keys(1:end-1), "");
        end

        % Navigate to the parent context
        if numel(keys) > 1
            parentPath = join(keys(1:end-1), ".");
            parent = getDataPath(rootData, parentPath);
        else
            parent = rootData;
        end

        % Create new element
        newElement = matlab.io.config.TOMLData;

        if ~isfield(parent, lastKey)
            % First element - just assign
            parent.(lastKey) = newElement;
            arrayIndex = 1;
            arrayPath = tablePath;
            arrayOfTables(tablePath) = arrayIndex;
        elseif isKey(arrayOfTables, tablePath)
            % Append to existing array
            currentArray = parent.(lastKey);
            if isa(currentArray, 'matlab.io.config.TOMLData')
                % Use vertical concatenation for column-oriented arrays (Issue #77)
                parent.(lastKey) = [currentArray; newElement];
            else
                error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                    'Key "%s" is not a TOMLData array', lastKey);
            end
            arrayIndex = arrayOfTables(tablePath) + 1;
            arrayPath = tablePath;
            arrayOfTables(tablePath) = arrayIndex;
        else
            error('tomlToolbox:readtoml:InvalidArrayOfTables', ...
                'Key "%s" already exists and is not an array of tables', lastKey);
        end

        % Write parent back to rootData
        if numel(keys) > 1
            parentPath = keys(1:end-1);
            rootData = setDataPath(rootData, parentPath, parent);
        else
            rootData = parent;
        end

        tableRef = newElement;
    end
end

function tableRef = getDataPathFromObj(data, tablePath)
    % Get reference at given path from a specific object (not rootData)
    if strlength(tablePath) == 0
        tableRef = data;
        return;
    end

    keys = splitDottedKey(tablePath);
    tableRef = data;

    for i = 1:numel(keys)
        tableRef = tableRef.(cleanKey(keys(i)));
    end
end

function [rootData, tableRef] = parseKeyValue(rootData, tableRef, tablePath, arrayIndex, arrayPath, line, datetimeType, arrayOfTables)
    % Parse key = value line

    % Find first '=' not in quotes
    eqPos = findUnquotedChar(line, '=');

    if eqPos == 0
        error('tomlToolbox:readtoml:InvalidSyntax', 'Invalid key-value syntax: %s', line);
    end

    keyPart = strtrim(extractBefore(line, eqPos));
    valuePart = strtrim(extractAfter(line, eqPos));

    % Remove quotes from key if present
    key = cleanKey(keyPart);

    % Parse value
    value = parseValue(valuePart, datetimeType);

    % Handle dotted keys (e.g., a.b.c = value)
    % Use splitDottedKey to respect quotes in keys
    keys = splitDottedKey(keyPart);
    if numel(keys) > 1
        currentData = tableRef;

        for i = 1:numel(keys) - 1
            k = char(cleanKey(strtrim(keys(i))));

            if ~isfield(currentData, k)
                currentData.(k) = matlab.io.config.TOMLData;
            end
            currentData = currentData.(k);
        end

        finalKey = char(cleanKey(strtrim(keys(end))));
        currentData.(finalKey) = value;

        % Update tableRef in rootData
        if strlength(tablePath) == 0
            rootData = updateDataPath(rootData, keys(:), currentData, numel(keys) - 1);
        else
            % Ensure both are column vectors before concatenation
            tablePathKeys = splitDottedKey(tablePath);
            rootData = updateDataPath(rootData, [tablePathKeys(:); keys(:)], currentData, numel(keys) - 1);
        end
        tableRef = getDataPath(rootData, tablePath);
    else
        % Simple assignment using dot notation
        % Some keys conflict with method names (e.g., 'empty'), so use try-catch
        try
            tableRef.(key) = value;
        catch ME
            if contains(ME.message, 'temporary value') || contains(ME.message, 'method')
                % Method name conflict - store directly using setData
                tableRef = tableRef.setData(char(key), value);
            else
                rethrow(ME);
            end
        end

        % Update in rootData (value semantics require explicit write-back)
        if arrayIndex > 0 && (strcmp(tablePath, arrayPath) || startsWith(tablePath, arrayPath + "."))
            % Array element update (direct or nested table within array)
            % Use array-aware navigation for nested arrays
            currentArray = getArrayAtPath(rootData, arrayPath, arrayOfTables);

            % Get the array element
            element = currentArray(arrayIndex);

            if strcmp(tablePath, arrayPath)
                % Direct array element field
                element.(key) = value;
            else
                % Nested table within array element - use helper for value semantics
                relativePath = extractAfter(tablePath, arrayPath + ".");
                relativeKeys = split(relativePath, ".");
                element = setNestedValue(element, relativeKeys, key, value);
            end

            % Write the modified element back to the array
            currentArray(arrayIndex) = element;
            rootData = setArrayAtPath(rootData, arrayPath, arrayOfTables, currentArray);
            tableRef = currentArray(arrayIndex);
        elseif strlength(tablePath) == 0
            rootData = tableRef;
        else
            pathKeys = split(tablePath, ".");
            rootData = setDataPath(rootData, pathKeys, tableRef);
        end
    end
end

function data = setDataPath(data, pathKeys, value)
    % Set a value at a specific path
    if numel(pathKeys) == 1
        data.(cleanKey(pathKeys(1))) = value;
    else
        key = char(cleanKey(pathKeys(1)));
        if isfield(data, key)
            data.(key) = setDataPath(data.(key), pathKeys(2:end), value);
        else
            data.(key) = setDataPath(matlab.io.config.TOMLData, pathKeys(2:end), value);
        end
    end
end

function data = updateDataPath(data, pathKeys, value, levelsFromEnd)
    % Update data at given path
    if levelsFromEnd == 0
        data = value;
        return;
    end

    key = char(cleanKey(pathKeys(1)));
    if numel(pathKeys) == 1
        data.(key) = value;
    else
        if isfield(data, key)
            data.(key) = updateDataPath(data.(key), pathKeys(2:end), value, levelsFromEnd - 1);
        else
            data.(key) = updateDataPath(matlab.io.config.TOMLData, pathKeys(2:end), value, levelsFromEnd - 1);
        end
    end
end

function tableRef = getDataPath(data, tablePath)
    % Get reference at given path
    if strlength(tablePath) == 0
        tableRef = data;
        return;
    end

    keys = splitDottedKey(tablePath);
    tableRef = data;

    for i = 1:numel(keys)
        tableRef = tableRef.(cleanKey(keys(i)));
    end
end

function arrayData = getArrayAtPath(data, arrayPath, arrayOfTables)
    % Get array at path, handling nested arrays properly
    % For nested paths like "jobs.steps", use arrayOfTables to navigate through parent arrays

    pathKeys = splitDottedKey(arrayPath);

    % Find parent arrays in the path
    current = data;
    for i = 1:numel(pathKeys)
        key = char(cleanKey(pathKeys(i)));

        % Check if this key points to a parent array
        partialPath = char(join(pathKeys(1:i), "."));
        if i < numel(pathKeys) && isKey(arrayOfTables, partialPath)
            % This is a parent array - index into it
            parentIndex = arrayOfTables(partialPath);
            current = current.(key);
            current = current(parentIndex);
        else
            % Regular field access
            current = current.(key);
        end
    end

    arrayData = current;
end

function data = setArrayAtPath(data, arrayPath, arrayOfTables, arrayData)
    % Set array at path, handling nested arrays properly
    % For nested paths like "jobs.steps", use arrayOfTables to navigate through parent arrays

    pathKeys = splitDottedKey(arrayPath);

    if numel(pathKeys) == 1
        % Simple case - direct assignment
        data.(cleanKey(pathKeys(1))) = arrayData;
    else
        % Find the innermost parent array
        parentArrayPath = "";
        parentArrayIndex = 0;
        for i = 1:numel(pathKeys)-1
            partialPath = char(join(pathKeys(1:i), "."));
            if isKey(arrayOfTables, partialPath)
                parentArrayPath = partialPath;
                parentArrayIndex = arrayOfTables(partialPath);
            end
        end

        if strlength(parentArrayPath) > 0
            % Navigate to parent array element and set the nested array
            parentArray = getArrayAtPath(data, parentArrayPath, arrayOfTables);
            parentElement = parentArray(parentArrayIndex);

            % Get the remaining path after the parent array
            remainingPath = extractAfter(arrayPath, parentArrayPath + ".");
            parentElement = setNestedValueDirect(parentElement, splitDottedKey(remainingPath), arrayData);

            % Write back
            parentArray(parentArrayIndex) = parentElement;
            data = setArrayAtPath(data, parentArrayPath, arrayOfTables, parentArray);
        else
            % No parent arrays - use regular setDataPath
            data = setDataPath(data, pathKeys, arrayData);
        end
    end
end

function pos = findUnquotedChar(str, char)
    % Find position of character not inside quotes
    
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(str)
        c = extractBetween(str, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
        elseif c == char && ~inQuotes
            pos = i;
            return;
        end
    end

    pos = 0;
end

function key = cleanKey(keyStr)
    % Remove quotes from key if present
    
    keyStr = strtrim(keyStr);

    if (startsWith(keyStr, '"') && endsWith(keyStr, '"')) || ...
       (startsWith(keyStr, "'") && endsWith(keyStr, "'"))
        key = extractBetween(keyStr, 2, strlength(keyStr) - 1);
    else
        key = keyStr;
    end
end

function value = parseValue(valueStr, datetimeType)
    % Parse TOML value from string
    
    valueStr = strtrim(valueStr);

    % Remove inline comments
    valueStr = removeInlineComment(valueStr);

    % Arrays
    if startsWith(valueStr, "[")
        value = parseArray(valueStr, datetimeType);

    % Inline tables  
    elseif startsWith(valueStr, "{")
        value = parseInlineTable(valueStr, datetimeType);

    % Strings
    elseif startsWith(valueStr, '"') || startsWith(valueStr, "'")
        value = parseString(valueStr);

    % Booleans
    elseif valueStr == "true"
        value = true;
    elseif valueStr == "false"
        value = false;

    % DateTime
    elseif isDateTime(valueStr)
        if datetimeType == "datetime"
            value = parseDatetime(valueStr);
        else
            value = char(valueStr);
        end

    % Numbers
    else
        value = parseNumber(valueStr);
    end
end

function valueStr = removeInlineComment(valueStr)
    % Remove inline comments from value string
    
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(valueStr)
        c = extractBetween(valueStr, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
        elseif c == "#" && ~inQuotes
            valueStr = extractBefore(valueStr, i);
            return;
        end
    end
end

function arr = parseArray(arrayStr, datetimeType)
    % Parse TOML array
    
    arrayStr = strtrim(arrayStr);

    if ~startsWith(arrayStr, "[") || ~endsWith(arrayStr, "]")
        error('tomlToolbox:readtoml:InvalidArray', 'Invalid array syntax');
    end

    content = extractBetween(arrayStr, 2, strlength(arrayStr) - 1);
    content = strtrim(content);

    if strlength(content) == 0
        arr = [];
        return;
    end

    % Split by commas (respecting nesting)
    elements = splitArrayElements(content);

    % Parse each element
    parsedElements = cell(size(elements));
    for i = 1:numel(elements)
        parsedElements{i} = parseValue(elements(i), datetimeType);
    end

    % Try to convert to homogeneous array
    if numel(parsedElements) > 0
        % Check if all same type
        firstType = class(parsedElements{1});
        allSame = true;
        for i = 2:numel(parsedElements)
            if class(parsedElements{i}) ~= firstType
                allSame = false;
                break;
            end
        end

        if allSame && (isnumeric(parsedElements{1}) || islogical(parsedElements{1}))
            % Convert to numeric/logical array
            arr = [parsedElements{:}];
        elseif allSame && (ischar(parsedElements{1}) || isstring(parsedElements{1}))
            % Convert to string array
            arr = string(parsedElements);
        elseif allSame && isa(parsedElements{1}, 'matlab.io.config.TOMLData')
            % Object array
            arr = [parsedElements{:}];
        else
            % Keep as cell array for mixed types
            arr = parsedElements;
        end
    else
        arr = [];
    end
end

function elements = splitArrayElements(content)
    % Split array content by commas, respecting nesting
    
    elements = string.empty;
    currentElement = "";
    depth = 0;
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(content)
        c = extractBetween(content, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
            currentElement = currentElement + c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
            currentElement = currentElement + c;
        elseif ~inQuotes && (c == "[" || c == "{")
            depth = depth + 1;
            currentElement = currentElement + c;
        elseif ~inQuotes && (c == "]" || c == "}")
            depth = depth - 1;
            currentElement = currentElement + c;
        elseif c == "," && depth == 0 && ~inQuotes
            elements = [elements, strtrim(currentElement)]; %#ok<AGROW>
            currentElement = "";
        else
            currentElement = currentElement + c;
        end
    end

    if strlength(currentElement) > 0
        elements = [elements, strtrim(currentElement)];
    end
end

function tbl = parseInlineTable(tableStr, datetimeType)
    % Parse inline table {key = value, ...} - returns TOMLData
    
    tableStr = strtrim(tableStr);

    if ~startsWith(tableStr, "{") || ~endsWith(tableStr, "}")
        error('tomlToolbox:readtoml:InvalidInlineTable', 'Invalid inline table syntax');
    end

    content = extractBetween(tableStr, 2, strlength(tableStr) - 1);
    content = strtrim(content);

    tbl = matlab.io.config.TOMLData;  % Return TOMLData instead of struct

    if strlength(content) == 0
        return;
    end

    % Split by commas
    pairs = splitArrayElements(content);

    for i = 1:numel(pairs)
        pair = pairs(i);
        eqPos = findUnquotedChar(pair, '=');

        if eqPos == 0
            error('tomlToolbox:readtoml:InvalidInlineTable', 'Invalid key-value pair in inline table');
        end

        key = cleanKey(strtrim(extractBetween(pair, 1, eqPos - 1)));
        valuePart = strtrim(extractAfter(pair, eqPos));
        value = parseValue(valuePart, datetimeType);

        tbl.(key) = value;
    end
end

function str = parseString(strValue)
    % Parse TOML string (basic, literal, or multi-line)

    strValue = strtrim(strValue);

    % Multi-line basic string (""")
    if startsWith(strValue, '"""') && endsWith(strValue, '"""')
        content = extractBetween(strValue, 4, strlength(strValue) - 3);
        % Per TOML spec: trim one newline immediately after opening delimiter
        if startsWith(content, newline)
            content = extractAfter(content, 1);
        end
        % Unescape and return
        str = unescapeString(content);
        return;
    end

    % Multi-line literal string (''')
    if startsWith(strValue, "'''") && endsWith(strValue, "'''")
        content = extractBetween(strValue, 4, strlength(strValue) - 3);
        % Per TOML spec: trim one newline immediately after opening delimiter
        if startsWith(content, newline)
            content = extractAfter(content, 1);
        end
        % No unescaping for literal strings
        str = string(content);
        return;
    end

    % Regular basic string (")
    if startsWith(strValue, '"') && endsWith(strValue, '"')
        str = string(extractBetween(strValue, 2, strlength(strValue) - 1));
        str = unescapeString(str);
        return;
    end

    % Regular literal string (')
    if startsWith(strValue, "'") && endsWith(strValue, "'")
        str = string(extractBetween(strValue, 2, strlength(strValue) - 1));
        return;
    end

    error('tomlToolbox:readtoml:InvalidString', 'Invalid string syntax');
end

function str = unescapeString(str)
    % Unescape string escape sequences

    str = strrep(str, '\"', '"');
    str = strrep(str, '\\', '\');
    str = strrep(str, '\n', newline);
    str = strrep(str, '\t', sprintf('\t'));
    str = strrep(str, '\r', sprintf('\r'));
end

function keys = splitDottedKey(keyStr)
    % Split dotted key while respecting quotes
    % "a"."b.c".d -> ["a", "b.c", "d"]
    % a.b.c -> ["a", "b", "c"]

    keyStr = char(strtrim(keyStr));
    keys = string.empty;
    currentKey = "";
    inQuotes = false;
    quoteChar = '';
    i = 1;

    while i <= length(keyStr)
        c = keyStr(i);

        if ~inQuotes && (c == '"' || c == '''')
            % Start of quoted key
            inQuotes = true;
            quoteChar = c;
            currentKey = currentKey + string(c);
        elseif inQuotes && c == quoteChar
            % End of quoted key
            inQuotes = false;
            currentKey = currentKey + string(c);
        elseif ~inQuotes && c == '.'
            % Dot separator outside quotes
            if strlength(currentKey) > 0
                keys(end+1) = strtrim(currentKey); %#ok<AGROW>
                currentKey = "";
            end
        else
            % Regular character
            currentKey = currentKey + string(c);
        end

        i = i + 1;
    end

    % Add final key
    if strlength(currentKey) > 0
        keys(end+1) = strtrim(currentKey);
    end
end

function tf = isDateTime(str)
    % Check if string is a datetime value

    str = string(str);

    % Check for date (yyyy-MM-dd) with optional time
    datePattern = '^\d{4}-\d{2}-\d{2}';
    if ~isempty(regexp(str, datePattern, 'once'))
        tf = true;
        return;
    end

    % Check for local time only (HH:mm:ss or HH:mm:ss.fraction)
    timePattern = '^\d{2}:\d{2}:\d{2}';
    if ~isempty(regexp(str, timePattern, 'once'))
        tf = true;
        return;
    end

    tf = false;
end

function dt = parseDatetime(str)
    % Parse datetime string
    
    try
        dt = datetime(str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        try
            dt = datetime(str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
        catch
            try
                dt = datetime(str, 'InputFormat', 'yyyy-MM-dd');
            catch
                try
                    dt = datetime(str, 'InputFormat', 'HH:mm:ss');
                catch
                    error('tomlToolbox:readtoml:InvalidDatetime', 'Cannot parse datetime: %s', str);
                end
            end
        end
    end
end

function num = parseNumber(numStr)
    % Parse TOML number (integer or float)

    numStr = strtrim(numStr);

    % Remove underscores (TOML allows _ in numbers)
    numStr = strrep(numStr, '_', '');

    % Hex, octal, binary
    if startsWith(numStr, '0x')
        num = hex2dec(extractAfter(numStr, 2));
    elseif startsWith(numStr, '0o')
        num = base2dec(extractAfter(numStr, 2), 8);
    elseif startsWith(numStr, '0b')
        num = bin2dec(extractAfter(numStr, 2));
    else
        % Regular number
        num = str2double(numStr);

        if isnan(num)
            error('tomlToolbox:readtoml:InvalidNumber', 'Invalid number: %s', numStr);
        end
    end
end

function tf = needsMultiLineHandling(line)
    % Check if a line needs multi-line value accumulation
    % This happens when there's an opening bracket/brace/quote without a closing one

    % Find the equals sign to separate key from value
    eqPos = findUnquotedChar(line, '=');
    if eqPos == 0
        tf = false;
        return;
    end

    % Get the value part
    valuePart = strtrim(extractAfter(line, eqPos));

    % Check for multi-line strings (""" or ''')
    if startsWith(valuePart, '"""') || startsWith(valuePart, "'''")
        % Multi-line string - check if it closes on the same line
        delimiter = extractBetween(valuePart, 1, 3);
        % Look for closing delimiter after the opening one
        remainingPart = extractAfter(valuePart, 3);
        tf = ~contains(remainingPart, delimiter);
        return;
    end

    % Track bracket/brace depth for arrays and inline tables
    depth = 0;
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(valuePart)
        c = extractBetween(valuePart, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
        elseif ~inQuotes && (c == "[" || c == "{")
            depth = depth + 1;
        elseif ~inQuotes && (c == "]" || c == "}")
            depth = depth - 1;
        end
    end

    % If depth > 0, we have unclosed brackets/braces
    tf = depth > 0;
end

function [fullLine, newIndex] = accumulateMultiLineValue(lines, startIndex)
    % Accumulate lines until all brackets/braces/quotes are closed
    % Returns the combined line and the index of the last line used

    fullLine = strtrim(lines(startIndex));
    currentIndex = startIndex;

    % Check if this is a multi-line string
    eqPos = findUnquotedChar(fullLine, '=');
    if eqPos > 0
        valuePart = strtrim(extractAfter(fullLine, eqPos));
        isMultiLineString = startsWith(valuePart, '"""') || startsWith(valuePart, "'''");
        if isMultiLineString
            stringDelimiter = extractBetween(valuePart, 1, 3);
            % Accumulate multi-line string
            [fullLine, newIndex] = accumulateMultiLineString(lines, startIndex, stringDelimiter);
            return;
        end
    end

    % Track bracket/brace depth for arrays and inline tables
    depth = 0;
    inQuotes = false;
    inTripleQuotes = false;
    quoteChar = '';

    % Count initial depth from first line (handle triple quotes)
    i = 1;
    while i <= strlength(fullLine)
        % Check for triple quotes first
        if i <= strlength(fullLine) - 2
            threeChars = extractBetween(fullLine, i, i+2);
            if (threeChars == '"""' || threeChars == "'''") && ~inQuotes
                inTripleQuotes = ~inTripleQuotes;
                quoteChar = extractBetween(fullLine, i, i);
                i = i + 3;
                continue;
            end
        end

        c = extractBetween(fullLine, i, i);

        if ~inTripleQuotes
            if (c == '"' || c == "'") && ~inQuotes
                inQuotes = true;
                quoteChar = c;
            elseif c == quoteChar && inQuotes
                inQuotes = false;
            elseif ~inQuotes && (c == "[" || c == "{")
                depth = depth + 1;
            elseif ~inQuotes && (c == "]" || c == "}")
                depth = depth - 1;
            end
        end

        i = i + 1;
    end

    % Accumulate lines until depth reaches 0
    while depth > 0 && currentIndex < numel(lines)
        currentIndex = currentIndex + 1;
        nextLine = strtrim(lines(currentIndex));

        % Skip empty lines and comments in multi-line arrays/tables
        if strlength(nextLine) == 0 || startsWith(nextLine, "#")
            continue;
        end

        % Add this line to the accumulated value (with a space separator)
        fullLine = fullLine + " " + nextLine;

        % Update depth tracking (handle triple quotes)
        i = 1;
        while i <= strlength(nextLine)
            % Check for triple quotes first
            if i <= strlength(nextLine) - 2
                threeChars = extractBetween(nextLine, i, i+2);
                if (threeChars == '"""' || threeChars == "'''") && ~inQuotes
                    inTripleQuotes = ~inTripleQuotes;
                    quoteChar = extractBetween(nextLine, i, i);
                    i = i + 3;
                    continue;
                end
            end

            c = extractBetween(nextLine, i, i);

            if ~inTripleQuotes
                if (c == '"' || c == "'") && ~inQuotes
                    inQuotes = true;
                    quoteChar = c;
                elseif c == quoteChar && inQuotes
                    inQuotes = false;
                elseif ~inQuotes && (c == "[" || c == "{")
                    depth = depth + 1;
                elseif ~inQuotes && (c == "]" || c == "}")
                    depth = depth - 1;
                end
            end

            i = i + 1;
        end
    end

    newIndex = currentIndex;
end

function [fullLine, newIndex] = accumulateMultiLineString(lines, startIndex, delimiter)
    % Accumulate a multi-line string preserving newlines
    % delimiter is either '"""' or "'''"

    firstLine = lines(startIndex);
    eqPos = findUnquotedChar(firstLine, '=');
    keyPart = extractBefore(firstLine, eqPos + 1);
    valuePart = extractAfter(firstLine, eqPos);

    % Start with key = delimiter
    fullLine = keyPart + delimiter;

    % Get content after opening delimiter on first line
    afterDelimiter = extractAfter(valuePart, 3);
    currentIndex = startIndex;

    % Check if string closes on first line
    if contains(afterDelimiter, delimiter)
        fullLine = firstLine;
        newIndex = startIndex;
        return;
    end

    % Add first line content (if any) after delimiter
    if strlength(strtrim(afterDelimiter)) > 0
        fullLine = fullLine + afterDelimiter;
    end

    % Accumulate remaining lines until we find closing delimiter
    while currentIndex < numel(lines)
        currentIndex = currentIndex + 1;
        nextLine = lines(currentIndex);

        % Check if this line contains the closing delimiter
        if contains(nextLine, delimiter)
            % Add content before the delimiter
            beforeDelimiter = extractBefore(nextLine, strfind(nextLine, delimiter));
            if strlength(beforeDelimiter) > 0
                fullLine = fullLine + newline + beforeDelimiter;
            end
            fullLine = fullLine + delimiter;
            break;
        else
            % Add entire line with newline
            fullLine = fullLine + newline + nextLine;
        end
    end

    newIndex = currentIndex;
end
















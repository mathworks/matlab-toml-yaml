function writetoml(data, filename, options)
% WRITETOML Write data to TOML file
%
%   WRITETOML(DATA) writes DATA to 'untitled.toml' in the current directory.
%   DATA can be a TOMLData object, struct, or dictionary.
%
%   WRITETOML(DATA, FILENAME) writes DATA to the specified TOML file.
%
%   WRITETOML(..., Name, Value) specifies additional options using
%   name-value pairs:
%
%   'ArrayStyle' - Style for arrays (default: 'auto')
%                  'auto'  - Use heuristics (flow for small arrays, block for large)
%                  'flow'  - Use inline style as [1, 2, 3]
%                  'block' - Use multi-line style with one item per line
%
%   'NumIndentationSpaces' - Number of spaces for indentation (default: 2)
%                            Must be a positive integer
%
%   'SectionSpacing' - Spacing between top-level tables (default: 'loose')
%                      'loose'   - Blank line between each top-level table
%                      'compact' - No blank lines
%
%   'Precision' - Number of significant digits for numeric values (default: 6)
%                 Must be a positive integer
%
%   'TableStyle' - Style for nested tables (default: 'auto')
%                  'auto'     - Use heuristics based on table size/complexity
%                  'inline'   - Always use inline tables {x = 1, y = 2}
%                  'expanded' - Always use expanded [table] headers
%
%   'TableArrayStyle' - Style for arrays of tables (default: 'expanded')
%                       'expanded' - Use [[table]] syntax (most common, readable)
%                       'inline'   - Use inline array syntax [{x=1}, {x=2}]
%                       'auto'     - Choose based on array size/complexity
%
%   'StringEscapeStyle' - String escape processing (default: 'auto')
%                         'auto'     - Choose escaped or literal automatically
%                         'escaped'  - Use escape-processing (TOML basic strings)
%                         'literal'  - Use literal strings (no escape processing)
%
%   'StringLayout' - String layout style (default: 'auto')
%                    'auto'       - Choose single-line or multiline automatically
%                    'singleline' - Always use single-line strings
%                    'multiline'  - Always use multiline delimiters
%
% Examples:
%   Write TOMLData to file
%       config = TOMLData;
%       config.project.name = "my-package";
%       config.project.version = "1.0.0";
%       writetoml(config, 'pyproject.toml');
%
%   Write with default filename
%       writetoml(config);  % Creates untitled.toml
%
%   Compact format with flow arrays
%       writetoml(data, 'config.toml', ...
%           'ArrayStyle', 'flow', ...
%           'SectionSpacing', 'compact');
%
%   Expanded format with block arrays
%       writetoml(data, 'pyproject.toml', ...
%           'ArrayStyle', 'block', ...
%           'NumIndentationSpaces', 4);
%
%   Compact inline tables
%       writetoml(data, 'config.toml', ...
%           'TableStyle', 'inline');
%
%   Inline arrays of tables
%       writetoml(data, 'config.toml', ...
%           'TableArrayStyle', 'inline');
%
%   Literal strings for paths
%       writetoml(data, 'config.toml', ...
%           'StringEscapeStyle', 'literal');
%
%   Multiline strings
%       writetoml(data, 'config.toml', ...
%           'StringLayout', 'multiline');
%
% See also READTOML, TOMLData

%   Copyright 2025 The MathWorks, Inc.

    arguments
        data
        filename (1,1) string = "untitled.toml"
        options.ArrayStyle {mustBeMember(options.ArrayStyle, {'auto', 'flow', 'block'})} = 'auto'
        options.NumIndentationSpaces (1,1) {mustBeInteger, mustBePositive} = 2
        options.SectionSpacing {mustBeMember(options.SectionSpacing, {'compact', 'loose'})} = 'loose'
        options.Precision (1,1) {mustBeInteger, mustBePositive} = 6
        options.TableStyle {mustBeMember(options.TableStyle, {'auto', 'inline', 'expanded'})} = 'auto'
        options.TableArrayStyle {mustBeMember(options.TableArrayStyle, {'auto', 'inline', 'expanded'})} = 'expanded'
        options.StringEscapeStyle {mustBeMember(options.StringEscapeStyle, {'auto', 'escaped', 'literal'})} = 'auto'
        options.StringLayout {mustBeMember(options.StringLayout, {'auto', 'singleline', 'multiline'})} = 'auto'
    end

    % Convert input to TOMLData for consistent processing
    if isa(data, 'dictionary') || isstruct(data)
        data = tomldata(data);
    elseif ~isa(data, 'matlab.io.config.ConfigurationData')
        error("writetoml:InvalidInput", ...
            "Input must be TOMLData, struct, or dictionary.");
    end

    % Convert options for internal use
    addSectionSpacing = options.SectionSpacing == "loose";

    % Create options struct for passing to serialization functions
    serializeOpts = struct;
    serializeOpts.arrayStyle = options.ArrayStyle;
    serializeOpts.indentSize = options.NumIndentationSpaces;
    serializeOpts.addSectionSpacing = addSectionSpacing;
    serializeOpts.precision = options.Precision;
    serializeOpts.tableStyle = options.TableStyle;
    serializeOpts.tableArrayStyle = options.TableArrayStyle;
    serializeOpts.stringEscapeStyle = options.StringEscapeStyle;
    serializeOpts.stringLayout = options.StringLayout;

    % Generate TOML content
    tomlContent = serializeToml(data, serializeOpts);

    % Write to file
    try
        writelines(tomlContent, filename, WriteMode="overwrite");
    catch ME
        error('tomlToolbox:writetoml:FileOpenError', ...
            'Cannot open file for writing: %s', filename);
    end
end

function tomlStr = serializeToml(data, opts)
    % Serialize ConfigurationData to TOML string

    tomlStr = "";

    allKeys = keys(data);

    % Separate root key-values from tables
    rootPairs = string.empty;
    tables = string.empty;

    for i = 1:numel(allKeys)
        key = allKeys(i);
        value = getValue(data, key);

        if isa(value, 'matlab.io.config.ConfigurationData')
            tables = [tables, key]; %#ok<AGROW>
        else
            rootPairs = [rootPairs, key]; %#ok<AGROW>
        end
    end

    % Write root key-value pairs first
    for i = 1:numel(rootPairs)
        key = rootPairs(i);
        value = getValue(data, key);
        tomlStr = tomlStr + serializeKeyValue(key, value, opts) + newline;
    end

    if numel(rootPairs) > 0 && numel(tables) > 0
        tomlStr = tomlStr + newline;
    end

    % Write tables
    for i = 1:numel(tables)
        key = tables(i);
        value = getValue(data, key);
        tomlStr = tomlStr + serializeTable(key, value, "", opts);

        if i < numel(tables)
            if opts.addSectionSpacing
                tomlStr = tomlStr + newline;
            end
        end
    end
end

function value = getValue(data, key)
    % Get value from struct or ConfigurationData using dot notation
    value = data.(key);
end

function tomlStr = serializeTable(tableName, tableData, prefix, opts)
    % Serialize table with given prefix

    tomlStr = "";

    % Build full table name
    if strlength(prefix) > 0
        fullName = prefix + "." + tableName;
    else
        fullName = tableName;
    end

    % Check if this is an array (array of tables)
    if numel(tableData) > 1
        % Array of tables - check TableArrayStyle
        useInlineArray = shouldUseInlineTableArray(tableData, opts.tableArrayStyle);

        if useInlineArray
            % Write as inline array of inline tables: key = [{x=1}, {x=2}]
            tomlStr = tableName + " = " + serializeArrayOfTables(tableData, opts) + newline;
        else
            % Write as expanded array of tables using [[table]] syntax
            for i = 1:numel(tableData)
                tomlStr = tomlStr + "[[" + fullName + "]]" + newline;
                tomlStr = tomlStr + serializeStructContent(tableData(i), fullName, opts);
                if i < numel(tableData)
                    tomlStr = tomlStr + newline;
                end
            end
        end
    else
        % Regular table - get keys
        allKeys = keys(tableData);

        % Separate key-values from subtables
        pairs = string.empty;
        subtables = string.empty;

        for i = 1:numel(allKeys)
            key = allKeys(i);
            value = getValue(tableData, key);

            % Check if this is a table or array of tables
            isTableValue = isa(value, 'matlab.io.config.ConfigurationData') && numel(value) == 1;
            isTableArray = isa(value, 'matlab.io.config.ConfigurationData') && numel(value) > 1;

            if isTableValue && shouldUseInlineTable(value, opts.tableStyle)
                % Inline tables are written as key-value pairs
                pairs = [pairs, key]; %#ok<AGROW>
            elseif isTableArray && shouldUseInlineTableArray(value, opts.tableArrayStyle)
                % Inline table arrays are written as key-value pairs
                pairs = [pairs, key]; %#ok<AGROW>
            elseif isTableValue || isTableArray
                subtables = [subtables, key]; %#ok<AGROW>
            else
                pairs = [pairs, key]; %#ok<AGROW>
            end
        end

        % Only write table header if there are key-value pairs
        if numel(pairs) > 0
            tomlStr = tomlStr + "[" + fullName + "]" + newline;

            for i = 1:numel(pairs)
                key = pairs(i);
                value = getValue(tableData, key);
                tomlStr = tomlStr + serializeKeyValue(key, value, opts) + newline;
            end

            if numel(subtables) > 0
                tomlStr = tomlStr + newline;
            end
        end

        % Write subtables
        for i = 1:numel(subtables)
            key = subtables(i);
            value = getValue(tableData, key);
            tomlStr = tomlStr + serializeTable(key, value, fullName, opts);

            if i < numel(subtables)
                tomlStr = tomlStr + newline;
            end
        end
    end
end

function tomlStr = serializeStructContent(data, parentPath, opts)
    % Serialize ConfigurationData content without table header

    tomlStr = "";

    allKeys = keys(data);

    for i = 1:numel(allKeys)
        key = allKeys(i);
        value = getValue(data, key);

        if ~isa(value, 'matlab.io.config.ConfigurationData')
            tomlStr = tomlStr + serializeKeyValue(key, value, opts) + newline;
        end
    end

    % Handle nested tables - pass parentPath so nested tables get correct prefix
    for i = 1:numel(allKeys)
        key = allKeys(i);
        value = getValue(data, key);

        if isa(value, 'matlab.io.config.ConfigurationData')
            tomlStr = tomlStr + serializeTable(key, value, parentPath, opts);
        end
    end
end

function str = serializeKeyValue(key, value, opts)
    % Serialize a single key-value pair

    % Quote key if necessary
    if needsQuoting(key)
        keyStr = '"' + key + '"';
    else
        keyStr = key;
    end

    valueStr = serializeValue(value, opts, 0);
    str = keyStr + " = " + valueStr;
end

function tf = needsQuoting(key)
    % Check if key needs quoting
    % Per TOML spec, bare keys may only contain:
    %   A-Z, a-z, 0-9, -, _
    % All other characters require quoting

    % Check if key contains only valid bare key characters
    if isempty(regexp(key, '^[A-Za-z0-9_-]+$', 'once'))
        tf = true;
    else
        tf = false;
    end
end

function str = serializeValue(value, opts, depth)
    % Serialize a value to TOML format

    if islogical(value) && isscalar(value)
        if value
            str = "true";
        else
            str = "false";
        end

    elseif islogical(value) && ~isscalar(value)
        str = serializeArray(value, opts, depth);

    elseif isstring(value) && isscalar(value)
        str = formatTomlString(value, opts);

    elseif isstring(value) && ~isscalar(value)
        str = serializeArray(value, opts, depth);

    elseif isdatetime(value)
        if isempty(value.TimeZone)
            str = string(value, 'yyyy-MM-dd''T''HH:mm:ss');
        else
            str = string(value, 'yyyy-MM-dd''T''HH:mm:ssXXX');
        end

    elseif isnumeric(value) && isscalar(value)
        if value == floor(value) && abs(value) < 2^53
            str = sprintf('%d', value);
        else
            str = sprintf(['%.', num2str(opts.precision), 'g'], value);
        end

    elseif isnumeric(value) && ~isscalar(value)
        str = serializeArray(value, opts, depth);

    elseif isa(value, 'matlab.io.config.ConfigurationData') && isscalar(value)
        str = serializeInlineTable(value, opts);

    elseif isa(value, 'matlab.io.config.ConfigurationData') && ~isscalar(value)
        str = serializeArrayOfTables(value, opts);

    else
        error('tomlToolbox:writetoml:UnsupportedType', ...
            'Cannot serialize value of type: %s', class(value));
    end
end

function str = serializeArray(arr, opts, depth)
    % Serialize array to TOML format

    % Determine whether to use flow style for this array
    useFlow = shouldUseFlowArray(arr, opts);

    if useFlow
        % Flow style: [item1, item2, item3]
        str = "[";

        for i = 1:numel(arr)
            str = str + serializeValue(arr(i), opts, depth + 1);

            if i < numel(arr)
                str = str + ", ";
            end
        end

        str = str + "]";
    else
        % Block style: multi-line with indentation
        str = "[" + newline;
        indent = repmat(' ', 1, (depth + 1) * opts.indentSize);

        for i = 1:numel(arr)
            str = str + indent + serializeValue(arr(i), opts, depth + 1);

            if i < numel(arr)
                str = str + "," + newline;
            else
                str = str + newline;
            end
        end

        closeIndent = repmat(' ', 1, depth * opts.indentSize);
        str = str + closeIndent + "]";
    end
end

function useFlow = shouldUseFlowArray(arr, opts)
    % Determine whether to use flow style for an array

    if opts.arrayStyle == "flow"
        useFlow = true;
    elseif opts.arrayStyle == "block"
        useFlow = false;
    else % 'auto'
        % Heuristic: use flow if array is small enough
        % - 3 or fewer items AND
        % - total serialized length <= 60 characters

        if numel(arr) > 3
            useFlow = false;
            return;
        end

        % Estimate total length by serializing each element
        totalLen = 2; % for [ and ]
        for i = 1:numel(arr)
            elemStr = serializeValue(arr(i), opts, 0);
            totalLen = totalLen + strlength(elemStr);
            if i < numel(arr)
                totalLen = totalLen + 2; % for ", "
            end
        end

        useFlow = totalLen <= 60;
    end
end

function str = serializeInlineTable(tbl, opts)
    % Serialize ConfigurationData as inline table

    str = "{";

    tableKeys = keys(tbl);

    for i = 1:numel(tableKeys)
        fieldName = tableKeys(i);
        value = getValue(tbl, fieldName);

        if needsQuoting(fieldName)
            str = str + '"' + fieldName + '"';
        else
            str = str + fieldName;
        end

        str = str + " = " + serializeValue(value, opts, 0);

        if i < numel(tableKeys)
            str = str + ", ";
        end
    end

    str = str + "}";
end

function str = serializeArrayOfTables(tableArray, opts)
    % Serialize array of tables as inline array with one entry per line:
    % [
    %     {x = 1, y = 2},
    %     {x = 3, y = 4},
    % ]

    str = "[" + newline;

    for i = 1:numel(tableArray)
        str = str + "    " + serializeInlineTable(tableArray(i), opts) + "," + newline;
    end

    str = str + "]";
end

function useInline = shouldUseInlineTable(tbl, style)
    % Determine whether to use inline table syntax based on style setting

    if style == "inline"
        useInline = true;
    elseif style == "expanded"
        useInline = false;
    else % "auto"
        % Heuristic: use inline if table has ≤3 keys, all simple values,
        % and total serialized length <= 60 characters

        tableKeys = keys(tbl);

        % Too many keys?
        if numel(tableKeys) > 3
            useInline = false;
            return;
        end

        % Check if any values are complex (nested tables or arrays of tables)
        for i = 1:numel(tableKeys)
            value = getValue(tbl, tableKeys(i));
            if isa(value, 'matlab.io.config.ConfigurationData')
                useInline = false;
                return;
            end
        end

        % Estimate total length
        totalLen = 2; % for { and }
        for i = 1:numel(tableKeys)
            key = tableKeys(i);
            value = getValue(tbl, key);
            totalLen = totalLen + strlength(key) + 3; % key, " = "
            if isstring(value)
                strLens = strlength(value);
                totalLen = totalLen + sum(strLens(:)) + 2; % quotes
            elseif isnumeric(value) && ~isscalar(value)
                % Numeric array - estimate based on element count
                totalLen = totalLen + numel(value) * 5 + numel(value) - 1; % numbers + commas
            else
                totalLen = totalLen + 10; % estimate for numbers/bools
            end
            if i < numel(tableKeys)
                totalLen = totalLen + 2; % ", "
            end
        end

        useInline = (totalLen <= 60);
    end
end

function useInline = shouldUseInlineTableArray(tableArray, style)
    % Determine whether to use inline array of tables based on style setting

    if style == "inline"
        useInline = true;
    elseif style == "expanded"
        useInline = false;
    else % "auto"
        % Heuristic: use inline if array has ≤2 elements and each has ≤3 simple fields
        if numel(tableArray) > 2
            useInline = false;
            return;
        end

        % Check each element
        for i = 1:numel(tableArray)
            elem = tableArray(i);
            tableKeys = keys(elem);

            % Too many fields?
            if numel(tableKeys) > 3
                useInline = false;
                return;
            end

            % Check if any values are complex (nested tables)
            for j = 1:numel(tableKeys)
                value = getValue(elem, tableKeys(j));
                if isa(value, 'matlab.io.config.ConfigurationData')
                    useInline = false;
                    return;
                end
            end
        end

        useInline = true;
    end
end

function str = formatTomlString(value, opts)
    % Format string value according to StringEscapeStyle and StringLayout options

    % Determine escape style
    if opts.stringEscapeStyle == "literal"
        useLiteral = true;
    elseif opts.stringEscapeStyle == "escaped"
        useLiteral = false;
    else % "auto"
        % Use literal if string contains backslashes but no actual escape sequences
        useLiteral = shouldUseLiteralString(value);
    end

    % Determine layout
    if opts.stringLayout == "multiline"
        useMultiline = true;
    elseif opts.stringLayout == "singleline"
        useMultiline = false;
    else % "auto"
        % Use multiline if string contains newlines
        useMultiline = contains(value, newline);
    end

    % Format the string
    if useMultiline
        if useLiteral
            % Multi-line literal string: '''...'''
            str = "'''" + value + "'''";
        else
            % Multi-line basic string: """..."""
            escapedValue = escapeString(value);
            str = '"""' + escapedValue + '"""';
        end
    else
        if useLiteral
            % Single-line literal string: '...'
            str = "'" + value + "'";
        else
            % Single-line basic string: "..."
            str = '"' + escapeString(value) + '"';
        end
    end
end

function useLiteral = shouldUseLiteralString(value)
    % Heuristic: use literal strings for paths and strings with backslashes
    % but no escape sequences that need processing

    % If no backslashes, doesn't matter
    if ~contains(value, '\')
        useLiteral = false;
        return;
    end

    % If contains actual control characters (not the text "\n"), use escaped
    % These are the actual newline/tab/carriage-return characters
    if contains(value, newline) || contains(value, sprintf('\t')) || contains(value, sprintf('\r'))
        useLiteral = false;
        return;
    end

    % If contains single quotes (can't be in literal strings), use escaped
    if contains(value, "'")
        useLiteral = false;
        return;
    end

    % String has backslashes but no control characters - use literal to preserve them
    useLiteral = true;
end

function str = escapeString(str)
    % Escape special characters in string

    str = strrep(str, '\', '\\');
    str = strrep(str, '"', '\"');
    str = strrep(str, newline, '\n');
    str = strrep(str, sprintf('\t'), '\t');
    str = strrep(str, sprintf('\r'), '\r');
end

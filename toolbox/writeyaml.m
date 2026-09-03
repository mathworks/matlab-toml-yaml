function writeyaml(data, filename, options)
%WRITEYAML Write data to YAML file
%   WRITEYAML(DATA) writes the MATLAB data to 'untitled.yaml'.
%
%   WRITEYAML(DATA, FILENAME) writes to the specified file.
%
%   DATA can be a YAMLData object, struct, dictionary, or containers.Map.
%
%   WRITEYAML(..., Name, Value) specifies additional options using
%   name-value pairs:
%
%   'ArrayStyle' - Style for arrays/lists (default: 'block')
%                  'block' - Use block style with - items
%                  'flow'  - Use inline style as [1, 2, 3]
%
%   'NumIndentationSpaces' - Number of spaces for indentation (default: 2)
%                            Must be a positive integer
%
%   'SectionSpacing' - Spacing between top-level sections (default: 'loose')
%                      'loose'   - Blank line between each top-level key
%                      'compact' - No blank lines
%
%   'Precision' - Number of decimal places for numeric values (default: 6)
%                 Must be a positive integer
%
%   Examples:
%       % Write to default filename
%       writeyaml(data);  % Creates untitled.yaml
%
%       % Write to specific file
%       writeyaml(data, 'output.yaml');
%
%       % Compact format with 4-space indentation
%       writeyaml(myData, 'data.yml', ...
%           'NumIndentationSpaces', 4, ...
%           'SectionSpacing', 'compact');
%
%       % Flow style for compact arrays
%       writeyaml(data, 'list.yaml', 'ArrayStyle', 'flow');
%
%   See also READYAML, YAMLData

%   Copyright 2025 The MathWorks, Inc.

    arguments
        data
        filename {mustBeTextScalar, mustBeNonzeroLengthText} = "untitled.yaml"
        options.ArrayStyle {mustBeMember(options.ArrayStyle, {'block', 'flow'})} = 'block'
        options.NumIndentationSpaces (1,1) {mustBeInteger, mustBePositive} = 2
        options.SectionSpacing {mustBeMember(options.SectionSpacing, {'compact', 'loose'})} = 'loose'
        options.Precision (1,1) {mustBeInteger, mustBePositive} = 6
    end

    % Convert input to YAMLData for consistent processing
    if isa(data, 'dictionary') || isstruct(data) || isa(data, 'containers.Map')
        data = yamldata(data);
    elseif ~isa(data, 'matlab.io.config.ConfigurationData')
        error("writeyaml:InvalidInput", ...
            "Input must be YAMLData, struct, dictionary, or containers.Map.");
    end

    % Convert ArrayStyle to boolean for internal use
    flowStyle = options.ArrayStyle == "flow";

    % Convert SectionSpacing to boolean for internal use
    addSectionSpacing = options.SectionSpacing == "loose";

    % Generate YAML text
    try
        yamlText = generateYAML(data, 0, options.NumIndentationSpaces, flowStyle, options.Precision, addSectionSpacing);
    catch ME
        error('yamlToolbox:yamlwrite:GenerateError', ...
            'Error generating YAML content: %s', ME.message);
    end

    % Write to file
    try
        writelines(yamlText, filename, WriteMode="overwrite");
    catch ME
        error('yamlToolbox:yamlwrite:FileWriteError', ...
            'Unable to write to file "%s": %s', filename, ME.message);
    end
end

function yamlText = generateYAML(data, depth, indentSize, flowStyle, precision, addSectionSpacing)
    %GENERATEYAML Generate YAML text from MATLAB data

    if isempty(data)
        yamlText = "null";
        return;
    end

    % Handle different data types
    if isa(data, 'matlab.io.config.ConfigurationData')
        % Check if it's an array
        if numel(data) > 1
            % Object array - convert to cell array and process
            dataCell = cell(1, numel(data));
            for i = 1:numel(data)
                dataCell{i} = data(i);
            end
            yamlText = cellToYAML(dataCell, depth, indentSize, flowStyle, precision, addSectionSpacing);
        else
            % Single ConfigurationData object
            yamlText = configDataToYAML(data, depth, indentSize, flowStyle, precision, addSectionSpacing);
        end
    elseif ismissing(data)
        yamlText = "null";
    elseif iscell(data)
        yamlText = cellToYAML(data, depth, indentSize, flowStyle, precision, addSectionSpacing);
    elseif isstring(data) && numel(data) > 1
        % String array with multiple elements
        yamlText = stringArrayToYAML(data, depth, indentSize, flowStyle);
    elseif isnumeric(data) || islogical(data)
        yamlText = numericToYAML(data, depth, indentSize, flowStyle, precision);
    elseif ischar(data) || (isstring(data) && isscalar(data))
        % Scalar string or char
        yamlText = stringToYAML(data);
    else
        % Try to convert to string
        yamlText = stringToYAML(string(data));
    end
end

function yamlText = configDataToYAML(data, depth, indentSize, flowStyle, precision, addSectionSpacing)
    %CONFIGDATATOYAML Convert ConfigurationData or YAMLData to YAML
    %   Uses the original keys (including special characters like hyphens)

    keyList = keys(data);
    yamlLines = strings(length(keyList), 1);

    for i = 1:length(keyList)
        key = keyList(i);
        value = data.(key);

        indent = string(blanks(depth * indentSize));
        valueYAML = generateYAML(value, depth + 1, indentSize, flowStyle, precision, false);

        % Check if value should be on new line
        % Nested objects (ConfigurationData, struct, Map) are ALWAYS on new line
        % Multi-line values (arrays in block style) are on new line
        % Simple scalars and flow arrays can be on same line
        isNestedObject = isa(value, 'matlab.io.config.ConfigurationData');

        if isNestedObject || contains(valueYAML, newline)
            yamlLines(i) = indent + key + ":" + newline + valueYAML;
        else
            yamlLines(i) = indent + key + ": " + valueYAML;
        end
    end

    % Add section spacing for top-level keys (depth == 0)
    if depth == 0 && addSectionSpacing && length(yamlLines) > 1
        % Add blank line between sections
        % Note: [newline newline] is char concatenation; newline+newline would
        % be char arithmetic (= 20), which is not a valid join delimiter.
        separator = [newline newline];
    else
        separator = newline;
    end

    yamlText = join(yamlLines, separator);
end

function yamlText = stringArrayToYAML(data, depth, indentSize, flowStyle)
    %STRINGARRAYTOYAML Convert string array to YAML
    %   Note: Single-element arrays are always written as arrays (not scalars)
    %   This preserves the semantic difference between:
    %     branches: main        (scalar string)
    %     branches: [main]      (array with one element)

    if flowStyle && (isvector(data) || isscalar(data))
        % Flow style: [item1, item2, item3] or [item]
        items = strings(1, length(data));
        for i = 1:length(data)
            items(i) = stringToYAML(data(i));
        end
        yamlText = "[" + join(items, ", ") + "]";
    else
        % Block style
        yamlLines = strings(length(data), 1);
        indent = string(blanks(depth * indentSize));

        for i = 1:length(data)
            itemYAML = stringToYAML(data(i));
            yamlLines(i) = indent + "- " + itemYAML;
        end

        yamlText = join(yamlLines, newline);
    end
end

function yamlText = cellToYAML(data, depth, indentSize, flowStyle, precision, addSectionSpacing)
    %CELLTOYAML Convert cell array to YAML

    if flowStyle && isvector(data)
        % Flow style: [item1, item2, item3]
        items = strings(1, length(data));
        for i = 1:length(data)
            items(i) = generateYAML(data{i}, 0, indentSize, flowStyle, precision, false);
        end
        yamlText = "[" + join(items, ", ") + "]";
    else
        % Block style
        yamlLines = strings(length(data), 1);
        indent = string(blanks(depth * indentSize));

        for i = 1:length(data)
            itemYAML = generateYAML(data{i}, depth + 1, indentSize, flowStyle, precision, false);

            if contains(itemYAML, newline)
                % Multiline item - put first line on same line as dash
                itemLinesArray = splitlines(itemYAML);
                % First line goes after the dash (strip its indentation)
                firstLine = strtrim(itemLinesArray(1));
                yamlLines(i) = indent + "- " + firstLine;
                % Remaining lines keep their indentation
                if length(itemLinesArray) > 1
                    for j = 2:length(itemLinesArray)
                        yamlLines(i) = yamlLines(i) + newline + itemLinesArray(j);
                    end
                end
            else
                % Single line item (strip indentation)
                yamlLines(i) = indent + "- " + strtrim(itemYAML);
            end
        end

        yamlText = join(yamlLines, newline);
    end
end

function yamlText = numericToYAML(data, depth, indentSize, flowStyle, precision)
    %NUMERICTOYAML Convert numeric array to YAML

    if isscalar(data)
        % Single value
        if islogical(data)
            if data
                yamlText = "true";
            else
                yamlText = "false";
            end
        elseif isinteger(data)
            yamlText = sprintf('%d', data);
        else
            yamlText = sprintf(['%.', num2str(precision), 'g'], data);
        end
    elseif isvector(data) && flowStyle
        % Flow style vector
        if islogical(data)
            items = strings(size(data));
            items(data) = "true";
            items(~data) = "false";
        elseif isinteger(data)
            items = compose("%d", data);
        else
            formatStr = "%." + precision + "g";
            items = compose(formatStr, data);
        end
        yamlText = "[" + join(items, ", ") + "]";
    else
        % Block style array
        yamlLines = strings(numel(data), 1);
        indent = string(blanks(depth * indentSize));

        for i = 1:numel(data)
            if islogical(data(i))
                value = iif(data(i), "true", "false");
            elseif isinteger(data(i))
                value = sprintf('%d', data(i));
            else
                value = sprintf(['%.', num2str(precision), 'g'], data(i));
            end
            yamlLines(i) = indent + "- " + value;
        end

        yamlText = join(yamlLines, newline);
    end
end

function yamlText = stringToYAML(data)
    %STRINGTOYAML Convert string/char to YAML

    % Ensure we're working with string
    strData = string(data);

    % Check if quoting is needed
    needsQuoting = strlength(strData) == 0 || ...
       startsWith(strData, ["!", "#", "&", "*", "{", "[", "|", ">", "@", "`"]) || ...
       contains(strData, ": ") || ...
       contains(strData, " #") || ...
       ismember(lower(strData), ["true", "false", "null", "yes", "no", "on", "off", "~"]) || ...
       looksLikeNumber(strData) || ...
       looksLikeDate(strData);

    if needsQuoting
        % Use double quotes and escape special characters
        strData = strrep(strData, "\", "\\");
        strData = strrep(strData, """", "\""");
        strData = strrep(strData, newline, "\n");
        yamlText = """" + strData + """";
    else
        yamlText = strData;
    end
end

function tf = looksLikeNumber(str)
    %LOOKSLIKENUMBER Check if string looks like a number (int, float, hex, octal)
    %   Returns true for strings like '3.8', '123', '0x1A', '0o17', '.5', '1e10'

    persistent pat
    if isempty(pat)
        % Single combined pattern for all numeric forms
        pat = '^([+-]?(\d+\.?\d*|\d*\.\d+)([eE][+-]?\d+)?|0[xX][0-9a-fA-F]+|0[oO][0-7]+|[+-]?(\.inf|\.Inf|\.INF)|\.nan|\.NaN|\.NAN)$';
    end

    tf = strlength(str) > 0 && ~isempty(regexp(str, pat, 'once'));
end

function tf = looksLikeDate(str)
    %LOOKSLIKEDATE Check if string looks like an ISO date
    %   Returns true for strings like '2020-01-01', '2020-01-01T12:00:00'

    % Quick length and character check to avoid regexp
    if strlength(str) < 10
        tf = false;
        return;
    end
    ch = char(str);
    tf = ch(5) == '-' && ch(8) == '-' && ...
         all(ch([1 2 3 4 6 7 9 10]) >= '0' & ch([1 2 3 4 6 7 9 10]) <= '9');
end

function result = iif(condition, trueVal, falseVal)
    %IIF Inline if function - returns string type for consistency
    if condition
        result = string(trueVal);
    else
        result = string(falseVal);
    end
end

function mustBeNonzeroLengthText(str)
    %MUSTBENONZEROLENGTHTEXT Validate that text is not empty
    if strlength(str) == 0
        error('Value must be non-empty text');
    end
end

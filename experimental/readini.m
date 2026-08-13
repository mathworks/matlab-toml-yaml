function data = readini(filename, options)
    %READINI Read INI file
    %   data = READINI(filename) reads the INI file and returns an INIData object.
    %
    %   The function parses Windows INI format with sections [SectionName] and
    %   key=value pairs. Comments start with ; or # on a separate line.
    %
    %   Input:
    %       filename - Path to INI file (char or string)
    %
    %   Output:
    %       data - INIData object with configuration data
    %
    %   Example:
    %       config = readini('config.ini');
    %       host = config.database.host;
    %       port = config.database.port;
    %
    %   Supported Windows INI Features:
    %       - Sections: [SectionName]
    %       - Key-value pairs: key=value or key:value
    %       - Comments: ; or # at line start
    %       - Whitespace: trimmed around keys/values
    %       - No multiline values (each line is separate)
    %
    %   See also: writeini, INIData, readyaml, readtoml

    arguments
        filename {mustBeFile}
        options.SequenceRule {mustBeMember(options.SequenceRule, {'auto', 'cell'})} = 'auto'
    end

    % Read file contents using built-in readlines (R2020b+)
    try
        lines = readlines(filename, Encoding="UTF-8");
    catch ME
        error('readini:ReadFailed', 'Cannot read file "%s": %s', filename, ME.message);
    end

    % Parse INI format
    data = matlab.io.config.INIData();
    currentSectionName = "";

    for i = 1:length(lines)
        line = strtrim(lines(i));
        lineChar = char(line);  % Convert to char for operations

        % Skip empty lines and comments
        if isempty(line) || startsWith(line, ';') || startsWith(line, '#')
            continue;
        end

        % Section header: [SectionName]
        if startsWith(line, '[') && endsWith(line, ']')
            sectionName = extractBetween(line, '[', ']');
            sectionName = strtrim(sectionName);

            % Create section if it doesn't exist (using dot notation)
            if ~isfield(data, sectionName)
                data.(sectionName) = matlab.io.config.INIData();
            end
            currentSectionName = sectionName;
            continue;
        end

        % Key-value pair: key=value or key:value
        if contains(line, '=') || contains(line, ':')
            % Find delimiter (using char version for find function)
            eqIdx = find(lineChar == '=', 1);
            colonIdx = find(lineChar == ':', 1);

            if isempty(eqIdx) && isempty(colonIdx)
                continue;
            end

            if isempty(eqIdx)
                delimIdx = colonIdx;
            elseif isempty(colonIdx)
                delimIdx = eqIdx;
            else
                delimIdx = min(eqIdx, colonIdx);
            end

            key = strtrim(extractBefore(line, delimIdx));
            value = strtrim(extractAfter(line, delimIdx));

            % Parse value: detect type
            parsedValue = parseValue(value);

            % Store in current section (or root if no section)
            % Use dot notation which handles value semantics correctly
            if currentSectionName ~= ""
                data.(currentSectionName).(key) = parsedValue;
            else
                data.(key) = parsedValue;
            end
        end
    end
end

function value = parseValue(valueStr)
    %PARSEVALUE Parse INI value string to MATLAB type

    % Convert to string for consistent handling
    valueStr = string(valueStr);
    valueLower = lower(valueStr);

    % Try logical (only explicit true/false/yes/no)
    if ismember(valueLower, ["true", "yes"])
        value = true;
        return;
    elseif ismember(valueLower, ["false", "no"])
        value = false;
        return;
    end

    % Try comma-separated array BEFORE numeric check
    % (because str2double('1,2,3') returns 123)
    if contains(valueStr, ',')
        parts = split(valueStr, ',');
        parts = strtrim(parts);

        % Try parsing as numeric array
        numArray = str2double(parts);
        if ~any(isnan(numArray))
            value = numArray;  % Orientation normalized by ConfigurationData (Issue #77)
            return;
        end

        % Otherwise as string array
        value = parts;  % Orientation normalized by ConfigurationData (Issue #77)
        return;
    end

    % Try numeric
    numVal = str2double(valueStr);
    if ~isnan(numVal)
        value = numVal;
        return;
    end

    % Default to string
    value = valueStr;
end

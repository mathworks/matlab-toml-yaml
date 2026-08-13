classdef INIData < matlab.io.config.ConfigurationData
    %INIDATA INI configuration data container
    %   INIData represents structured configuration data from INI files
    %   with dot notation access and support for special characters in field names.
    %   Follows Windows INI dialect with sections and key=value pairs.
    %
    %   This is a value class. Assignment creates an independent copy.
    %
    %   To create an INIData object, use the informal wrapper function:
    %       data = inidata();           % empty
    %       data = inidata(myStruct);   % from struct
    %
    %   Example:
    %       % Read from file
    %       config = readini('config.ini');
    %
    %       % Create and write
    %       config = inidata();
    %       config.database.host = 'localhost';
    %       config.database.port = '5432';
    %       writeini(config, 'config.ini');
    %
    %   See also INIDATA, READINI, WRITEINI, matlab.io.config.ConfigurationData

    methods
        function obj = INIData()
            %INIDATA Create empty INI data object
            %   obj = INIData() creates an empty INIData object
            %
            %   To create from existing data, use the inidata() function:
            %       config = inidata(myStruct);
            %
            %   See also INIDATA

            obj@matlab.io.config.ConfigurationData();
            obj.xInternal__.SourceFormat = "ini";
        end

        function iniText = show(obj)
            %SHOW Display INI content as formatted text
            %   show(obj) displays the INI structure without writing to file.

            iniText = generateINI(obj);
            if nargout == 0
                disp(iniText);
            end
        end
    end
end

function iniText = generateINI(obj)
    %GENERATEINI Generate INI text from INIData object
    lines = {};

    keyList = keys(obj);
    for i = 1:length(keyList)
        key = keyList(i);
        value = obj.(key);  % Use dot notation to get value

        if isa(value, 'matlab.io.config.ConfigurationData')
            % Section header
            lines{end+1} = sprintf('[%s]', key); %#ok<AGROW>

            % Section contents
            subKeyList = keys(value);
            for j = 1:length(subKeyList)
                subkey = subKeyList(j);
                subvalue = value.(subkey);  % Use dot notation

                if isa(subvalue, 'matlab.io.config.ConfigurationData')
                    % Skip nested ConfigurationData (INI doesn't support deep nesting)
                    continue;
                end

                % Convert value to string
                valueStr = valueToString(subvalue);
                lines{end+1} = sprintf('%s=%s', subkey, valueStr); %#ok<AGROW>
            end
            lines{end+1} = '';  % Blank line between sections %#ok<AGROW>
        end
    end

    iniText = strjoin(lines, newline);
end

function valueStr = valueToString(value)
    %VALUETOSTRING Convert MATLAB value to INI string representation
    if isstring(value) && isscalar(value)
        valueStr = value;
    elseif ischar(value)
        valueStr = string(value);
    elseif isscalar(value)
        if islogical(value)
            if value
                valueStr = 'true';
            else
                valueStr = 'false';
            end
        else
            valueStr = num2str(value);
        end
    elseif isnumeric(value) || isstring(value)
        % Array: convert to comma-separated list
        if isstring(value)
            items = cellstr(value);
        else
            items = cell(1, numel(value));
            for i = 1:numel(value)
                items{i} = num2str(value(i));
            end
        end
        valueStr = strjoin(items, ',');
    else
        valueStr = '';
    end
end

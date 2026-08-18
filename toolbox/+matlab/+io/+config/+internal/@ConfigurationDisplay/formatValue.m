function str = formatValue(~, value)
% Format a value for display (similar to struct)
if isa(value, 'matlab.io.config.ConfigurationData')
    if numel(value) > 1
        % Array of ConfigurationData
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        shortName = shortClassName(class(value));
        str = sprintf('[%s %s]', sizeStr, shortName);
    else
        % Scalar ConfigurationData - show actual subclass name
        nFields = numEntries(value.Data);
        shortName = shortClassName(class(value));
        str = sprintf('[1x1 %s with %d %s]', shortName, nFields, pluralize("key", nFields));
    end
elseif isa(value, 'dictionary')
    nKeys = numEntries(value);
    str = sprintf('[1x1 dictionary with %d %s]', nKeys, pluralize("entry", nKeys));
elseif ischar(value)
    if length(value) > 50
        str = sprintf('''%s...'' [1x%d char]', value(1:50), length(value));
    else
        str = sprintf('''%s''', value);
    end
elseif isstring(value) && isscalar(value)
    if strlength(value) > 50
        str = sprintf('"%s..."', extractBefore(value, 51));
    else
        str = sprintf('"%s"', value);
    end
elseif isnumeric(value)
    if isscalar(value)
        str = sprintf('%g', value);
    elseif numel(value) <= 5
        % Show small arrays inline
        numStr = sprintf('%g ', value);
        str = sprintf('[%s]', strtrim(numStr));
    else
        % Show size and type for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1); % Remove trailing 'x'
        str = sprintf('[%s %s]', sizeStr, class(value));
    end
elseif islogical(value)
    if isscalar(value)
        if value
            str = 'true';
        else
            str = 'false';
        end
    else
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s logical]', sizeStr);
    end
else
    % Generic handling
    sizeStr = sprintf('%dx', size(value));
    sizeStr = sizeStr(1:end-1);
    str = sprintf('[%s %s]', sizeStr, class(value));
end
end

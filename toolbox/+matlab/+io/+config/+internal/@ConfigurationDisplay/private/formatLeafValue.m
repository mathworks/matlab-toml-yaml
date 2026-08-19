function str = formatLeafValue(value, includeType)
%FORMATLEAFVALUE Format a scalar leaf value for display
%   formatLeafValue(value, true)  — with type annotation: "hello" (string)
%   formatLeafValue(value, false) — without: "hello"
if isstring(value)
    if strlength(value) > 40
        str = sprintf('"%s..."', extractBefore(value, 41));
    else
        str = sprintf('"%s"', value);
    end
    if includeType, str = str + " (string)"; end
elseif isnumeric(value)
    str = sprintf('%g', value);
    if includeType, str = sprintf('%s (%s)', str, class(value)); end
elseif islogical(value)
    if value
        str = "true";
    else
        str = "false";
    end
    if includeType, str = str + " (logical)"; end
else
    str = sprintf('%s', class(value));
end
end

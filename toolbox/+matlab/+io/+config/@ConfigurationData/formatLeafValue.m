function str = formatLeafValue(value)
%FORMATLEAFVALUE Format a scalar leaf value for describe() display
if isstring(value)
    if strlength(value) > 40
        str = sprintf('"%s..." (string)', extractBefore(value, 41));
    else
        str = sprintf('"%s" (string)', value);
    end
elseif ischar(value)
    if length(value) > 40
        str = sprintf('''%s...'' (char)', value(1:40));
    else
        str = sprintf('''%s'' (char)', value);
    end
elseif isnumeric(value)
    str = sprintf('%g (%s)', value, class(value));
elseif islogical(value)
    if value
        str = "true (logical)";
    else
        str = "false (logical)";
    end
else
    str = sprintf('%s', class(value));
end
end

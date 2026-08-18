function str = formatShowLeafValue(value)
%FORMATSHOWLEAFVALUE Format a scalar leaf value for show() — no type annotation
if isstring(value)
    if strlength(value) > 40
        str = sprintf('"%s..."', extractBefore(value, 41));
    else
        str = sprintf('"%s"', value);
    end
elseif ischar(value)
    if length(value) > 40
        str = sprintf('''%s...''', value(1:40));
    else
        str = sprintf('''%s''', value);
    end
elseif isnumeric(value)
    str = sprintf('%g', value);
elseif islogical(value)
    if value
        str = "true";
    else
        str = "false";
    end
else
    str = sprintf('%s', class(value));
end
end

function text = formatLeafText(value)
%FORMATLEAFTEXT Format a leaf value for describe() text output
if isa(value, 'missing')
    text = "missing";
elseif isempty(value)
    sizeStr = join(string(size(value)), "x");
    text = sizeStr + " " + class(value);
elseif isscalar(value) && isstring(value)
    if strlength(value) > 40
        text = """" + extractBefore(value, 41) + "..."" (string)";
    else
        text = """" + value + """ (string)";
    end
elseif isscalar(value) && isnumeric(value)
    text = string(value) + " (" + class(value) + ")";
elseif isscalar(value) && islogical(value)
    if value
        text = "true (logical)";
    else
        text = "false (logical)";
    end
else
    sizeStr = join(string(size(value)), "x");
    text = sizeStr + " " + class(value);
end
end

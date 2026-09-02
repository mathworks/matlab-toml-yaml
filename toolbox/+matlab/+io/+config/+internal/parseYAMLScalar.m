function value = parseYAMLScalar(text, isQuoted, datetimeType)
%parseYAMLScalar Convert a YAML scalar string to a typed MATLAB value.
%   Called by readyamlMex to infer types from untyped YAML scalar text.

    arguments
        text (1,1) string
        isQuoted (1,1) logical
        datetimeType (1,1) string
    end

    if isQuoted
        if datetimeType == "datetime"
            dt = tryParseDatetime(text);
            if ~isempty(dt)
                value = dt;
                return
            end
        end
        value = text;
        return
    end

    lower_text = lower(text);

    if ismember(lower_text, ["true", "yes", "on"])
        value = true;
        return
    end
    if ismember(lower_text, ["false", "no", "off"])
        value = false;
        return
    end
    if ismember(lower_text, ["null", "~", ""])
        value = [];
        return
    end

    numValue = str2double(text);
    if ~isnan(numValue)
        value = numValue;
        return
    end

    if datetimeType == "datetime" && strlength(text) >= 10 ...
            && ~isempty(regexp(text, '^\d{4}-\d{2}-\d{2}', 'once'))
        dt = tryParseDatetime(text);
        if ~isempty(dt)
            value = dt;
            return
        end
    end

    value = text;
end

function dt = tryParseDatetime(str)
    dt = [];
    try
        dt = datetime(str, 'InputFormat', "yyyy-MM-dd'T'HH:mm:ssXXX", 'TimeZone', 'UTC');
        return
    catch
    end
    try
        dt = datetime(str, 'InputFormat', "yyyy-MM-dd'T'HH:mm:ss");
        return
    catch
    end
    try
        dt = datetime(str, 'InputFormat', "yyyy-MM-dd");
        return
    catch
    end
end

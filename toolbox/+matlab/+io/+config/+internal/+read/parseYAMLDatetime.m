function dt = parseYAMLDatetime(str)
    dt = [];
    if strlength(str) < 10
        return
    end
    if isempty(regexp(str, '^\d{4}-\d{2}-\d{2}', 'once'))
        return
    end
    try
        if contains(str, "T")
            if endsWith(str, "Z") || ~isempty(regexp(str, '[+-]\d{2}:\d{2}$', 'once'))
                if isempty(regexp(str, '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]\d{2}:\d{2}|Z)$', 'once'))
                    return
                end
                dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ssXXX", TimeZone="UTC");
            else
                if isempty(regexp(str, '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$', 'once'))
                    return
                end
                dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ss");
            end
        else
            if isempty(regexp(str, '^\d{4}-\d{2}-\d{2}$', 'once'))
                return
            end
            dt = datetime(str, InputFormat="uuuu-MM-dd");
        end
    catch
    end
end

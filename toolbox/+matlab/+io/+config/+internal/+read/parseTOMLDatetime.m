function dt = parseTOMLDatetime(str)
    if contains(str, "T")
        if endsWith(str, "Z") || ~isempty(regexp(str, '[+-]\d{2}:\d{2}$', 'once'))
            dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ssXXX", TimeZone="UTC");
        else
            dt = datetime(str, InputFormat="uuuu-MM-dd'T'HH:mm:ss");
        end
    elseif contains(str, ":")
        dt = datetime(str, InputFormat="HH:mm:ss");
    else
        dt = datetime(str, InputFormat="uuuu-MM-dd");
    end
end

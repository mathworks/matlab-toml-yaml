function dt = parseTOMLDatetime(str)
    persistent fracPat offsetPat
    if isempty(fracPat)
        fracPat = "." + digitsPattern;
        offsetPat = ("+" | "-") + digitsPattern(2) + ":" + digitsPattern(2) + textBoundary("end");
    end

    frac = fractionalFormat(str, fracPat);
    if contains(str, "T")
        if endsWith(str, "Z") || contains(str, offsetPat)
            fmt = "uuuu-MM-dd'T'HH:mm:ss" + frac + "XXX";
            dt = datetime(str, InputFormat=fmt, TimeZone="UTC");
        else
            fmt = "uuuu-MM-dd'T'HH:mm:ss" + frac;
            dt = datetime(str, InputFormat=fmt);
        end
    elseif contains(str, ":")
        dt = matlab.io.config.internal.read.timeStringToDuration(str);
    else
        dt = datetime(str, InputFormat="uuuu-MM-dd");
    end
end

function fmt = fractionalFormat(str, fracPat)
    tok = extract(str, fracPat);
    if isempty(tok)
        fmt = "";
    else
        fmt = "." + repmat('S', 1, strlength(tok) - 1);
    end
end

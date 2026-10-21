function dt = parseYAMLDatetime(str)
    persistent fracPat offsetPat datetimeOffsetPat datetimeLocalPat datePat
    if isempty(fracPat)
        d2 = digitsPattern(2);
        d4 = digitsPattern(4);
        fracPat = "." + digitsPattern;
        offsetPat = ("+" | "-") + d2 + ":" + d2;
        timePart = d2 + ":" + d2 + ":" + d2 + optionalPattern(fracPat);
        datetimeOffsetPat = textBoundary("start") + d4 + "-" + d2 + "-" + d2 ...
            + "T" + timePart + (offsetPat | "Z") + textBoundary("end");
        datetimeLocalPat = textBoundary("start") + d4 + "-" + d2 + "-" + d2 ...
            + "T" + timePart + textBoundary("end");
        datePat = textBoundary("start") + d4 + "-" + d2 + "-" + d2 + textBoundary("end");
    end

    dt = [];
    if strlength(str) < 10
        return
    end
    try
        if contains(str, "T")
            frac = fractionalFormat(str, fracPat);
            if matches(str, datetimeOffsetPat)
                fmt = "uuuu-MM-dd'T'HH:mm:ss" + frac + "XXX";
                dt = datetime(str, InputFormat=fmt, TimeZone="UTC");
            elseif matches(str, datetimeLocalPat)
                fmt = "uuuu-MM-dd'T'HH:mm:ss" + frac;
                dt = datetime(str, InputFormat=fmt);
            end
        else
            if matches(str, datePat)
                dt = datetime(str, InputFormat="uuuu-MM-dd");
            end
        end
    catch
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

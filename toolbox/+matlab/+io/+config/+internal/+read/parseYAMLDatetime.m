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

    if ~isscalar(str)
        dt = parseArray(str, fracPat, datetimeOffsetPat, datetimeLocalPat, datePat);
        return
    end

    dt = parseOne(str, fracPat, datetimeOffsetPat, datetimeLocalPat, datePat);
end

function dt = parseOne(str, fracPat, datetimeOffsetPat, datetimeLocalPat, datePat)
    dt = [];
    if strlength(str) < 10
        dt = tryParseTimeOnly(str);
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

function dt = parseArray(str, fracPat, datetimeOffsetPat, datetimeLocalPat, datePat)
    dt = [];
    results = cell(numel(str), 1);
    for j = 1:numel(str)
        d = parseOne(str(j), fracPat, datetimeOffsetPat, datetimeLocalPat, datePat);
        if isempty(d)
            return
        end
        results{j} = d;
    end
    try
        dt = vertcat(results{:});
    catch
    end
end

function d = tryParseTimeOnly(str)
    persistent timePat
    if isempty(timePat)
        timePat = textBoundary("start") + digitsPattern(2) + ":" ...
            + digitsPattern(2) + ":" + digitsPattern(2) ...
            + optionalPattern("." + digitsPattern) + textBoundary("end");
    end
    d = [];
    if ~matches(str, timePat)
        return
    end
    d = matlab.io.config.internal.read.timeStringToDuration(str);
end

function fmt = fractionalFormat(str, fracPat)
    tok = extract(str, fracPat);
    if isempty(tok)
        fmt = "";
    else
        fmt = "." + repmat('S', 1, strlength(tok) - 1);
    end
end

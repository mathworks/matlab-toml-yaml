function [text, quoted] = formatYAMLScalar(value, precision)
    %formatYAMLScalar Format a MATLAB scalar value for YAML output.
    %   Called by writeyamlMex to convert typed values to YAML text.

    arguments
        value
        precision (1,1) double = 6
    end

    if isa(value, 'missing') || isempty(value)
        text = "null";
        quoted = false;
        return
    end

    if islogical(value)
        if value
            text = "true";
        else
            text = "false";
        end
        quoted = false;
        return
    end

    if isinteger(value)
        text = string(sprintf("%d", value));
        quoted = false;
        return
    end

    if isnumeric(value)
        if isnan(value)
            text = ".nan";
        elseif isinf(value)
            if value > 0
                text = ".inf";
            else
                text = "-.inf";
            end
        elseif value == floor(value) && abs(value) < 2^53
            text = string(sprintf("%d", value));
        else
            text = string(sprintf("%.*g", precision, double(value)));
        end
        quoted = false;
        return
    end

    if isstring(value) || ischar(value)
        text = string(value);
        quoted = needsQuoting(text);
        return
    end

    text = string(value);
    quoted = needsQuoting(text);
end

function tf = needsQuoting(str)
    if strlength(str) == 0
        tf = true;
        return
    end

    if startsWith(str, ["!", "#", "&", "*", "{", "[", "|", ">", "@", "`"])
        tf = true;
        return
    end

    if contains(str, ": ") || contains(str, " #")
        tf = true;
        return
    end

    if ismember(lower(str), ...
            ["true", "false", "null", "yes", "no", "on", "off", "~"])
        tf = true;
        return
    end

    if looksLikeNumber(str) || looksLikeDate(str)
        tf = true;
        return
    end

    tf = false;
end

function tf = looksLikeNumber(str)
    persistent pat
    if isempty(pat)
        pat = '^([+-]?(\d+\.?\d*|\d*\.\d+)([eE][+-]?\d+)?|0[xX][0-9a-fA-F]+|0[oO][0-7]+|[+-]?(\.inf|\.Inf|\.INF)|\.nan|\.NaN|\.NAN)$';
    end
    tf = strlength(str) > 0 && ~isempty(regexp(str, pat, 'once'));
end

function tf = looksLikeDate(str)
    if strlength(str) < 10
        tf = false;
        return
    end
    ch = char(str);
    tf = ch(5) == '-' && ch(8) == '-' && ...
        all(ch([1 2 3 4 6 7 9 10]) >= '0' & ch([1 2 3 4 6 7 9 10]) <= '9');
end

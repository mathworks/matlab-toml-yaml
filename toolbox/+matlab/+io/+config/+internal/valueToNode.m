function node = valueToNode(val)
    %valueToNode Convert a MATLAB value to a node tree node.
    %   node = valueToNode(val) converts expanded MATLAB values back to the
    %   node tree representation. Used by toNodeTree when user-set values
    %   need to be serialized back into the tree.
    %
    %   Values that are already node tree nodes pass through unchanged.

    if isa(val, "matlab.io.config.ConfigurationData")
        if isempty(val)
            node = struct("Data", [], "Type", "missing");
        else
            node = toNodeTree(val);
        end
    elseif isa(val, "datetime")
        if isscalar(val)
            node = struct("Data", formatDatetime(val), "Type", "datetime");
        else
            node = cell(size(val));
            for j = 1:numel(val)
                node{j} = struct("Data", formatDatetime(val(j)), "Type", "datetime");
            end
        end
    elseif isa(val, "missing")
        node = struct("Data", [], "Type", "missing");
    elseif iscell(val)
        for j = 1:numel(val)
            val{j} = matlab.io.config.internal.valueToNode(val{j});
        end
        node = val;
    else
        node = val;
    end
end

function str = formatDatetime(dt)
    hasTime = (dt.Hour ~= 0 || dt.Minute ~= 0 || dt.Second ~= 0);
    hasZone = ~isempty(dt.TimeZone);
    frac = fractionalFormat(dt);

    if hasZone
        str = string(dt, "uuuu-MM-dd'T'HH:mm:ss" + frac + "XXX");
    elseif hasTime
        str = string(dt, "uuuu-MM-dd'T'HH:mm:ss" + frac);
    else
        str = string(dt, "uuuu-MM-dd");
    end
end

function fmt = fractionalFormat(dt)
    frac = second(dt) - floor(second(dt));
    if frac == 0
        fmt = "";
    else
        digits = strip(sprintf('%.9f', frac), 'right', '0');
        fmt = "." + repmat('S', 1, strlength(digits) - 2);
    end
end

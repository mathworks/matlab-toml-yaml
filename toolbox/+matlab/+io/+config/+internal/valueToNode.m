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
        elseif isscalar(val)
            node = toNodeTree(val);
        else
            elements = cell(1, numel(val));
            for j = 1:numel(val)
                elements{j} = toNodeTree(val(j));
            end
            node = elements;
        end
    elseif isa(val, "datetime")
        node = struct("Data", val, "Type", "datetime");
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

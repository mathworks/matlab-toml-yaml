function tree = compactStructToNodeTree(cs)
    %compactStructToNodeTree Convert a CompactStruct to a node tree.
    %   tree = compactStructToNodeTree(cs) converts a CompactStruct (from the
    %   MEX reader) into a TableNode struct with the node tree representation.
    %
    %   Node types in the output tree:
    %     TableNode  — struct(Keys, Values)
    %     ValueNode  — struct(Data, Type) or struct(Data, Metadata)
    %     Bare value — scalar, native array, or cell

    n = numel(cs.Keys);
    values = cell(1, n);

    nullSet = false(1, max(n, 1));
    dtSet = false(1, max(n, 1));
    quotedSet = false(1, max(n, 1));
    if ~isempty(cs.NullIndices)
        nullSet(cs.NullIndices) = true;
    end
    if ~isempty(cs.DatetimeIndices)
        dtSet(cs.DatetimeIndices) = true;
    end
    if ~isempty(cs.QuotedIndices)
        quotedSet(cs.QuotedIndices) = true;
    end

    for i = 1:n
        if nullSet(i)
            values{i} = struct("Data", [], "Type", "missing");
        elseif dtSet(i)
            values{i} = struct("Data", cs.Values{i}, "Type", "datetime");
        elseif quotedSet(i)
            values{i} = struct("Data", cs.Values{i}, ...
                "Metadata", struct("Quoted", true));
        else
            values{i} = convertValue(cs.Values{i});
        end
    end

    tree = struct("Keys", cs.Keys, "Values", {values});
end

function val = convertValue(val)
    if isstruct(val) && isfield(val, "Keys")
        val = matlab.io.config.internal.read.compactStructToNodeTree(val);
    elseif iscell(val)
        for j = 1:numel(val)
            val{j} = convertValue(val{j});
        end
    end
end

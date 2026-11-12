function store = setNodeMetadata(store, key, meta)
    %setNodeMetadata Set metadata of the value node at key.
    %   Wraps a bare value in a ValueNode (scalars) or ArrayNode (arrays)
    %   to hold the metadata, and unwraps it again when meta is empty.
    idx = find(store.Tree.Keys == key, 1);
    node = store.Tree.Values{idx};
    clearing = isempty(meta) || (isstruct(meta) && isempty(fieldnames(meta)));

    if isstruct(node) && isscalar(node) && isfield(node, "Keys")
        if clearing
            if isfield(node, "TableMetadata")
                node = rmfield(node, "TableMetadata");
            end
        else
            node.TableMetadata = meta;
        end
    elseif isstruct(node) && isscalar(node) && isfield(node, "Elements")
        if clearing
            node = node.Elements;
        else
            node.Metadata = meta;
        end
    elseif isstruct(node) && isscalar(node) && isfield(node, "Data")
        if clearing
            if isfield(node, "Type")
                if isfield(node, "Metadata")
                    node = rmfield(node, "Metadata");
                end
            else
                node = node.Data;
            end
        else
            node.Metadata = meta;
        end
    elseif ~clearing
        if iscell(node) || ~isscalar(node)
            node = struct("Elements", {node}, "Metadata", meta);
        else
            node = struct("Data", {node}, "Metadata", meta);
        end
    end
    store.Tree.Values{idx} = node;
end

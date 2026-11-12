function meta = getNodeMetadata(store, key)
    %getNodeMetadata Metadata of the value node at key ([] if none).
    %   Table values carry TableMetadata, arrays and scalars carry
    %   Metadata on their ArrayNode/ValueNode wrapper.
    meta = [];
    node = store.Tree.Values{store.Tree.Keys == key};
    if ~isstruct(node) || ~isscalar(node)
        return
    end
    if isfield(node, "Keys")
        if isfield(node, "TableMetadata")
            meta = node.TableMetadata;
        end
    elseif isfield(node, "Metadata")
        meta = node.Metadata;
    end
end

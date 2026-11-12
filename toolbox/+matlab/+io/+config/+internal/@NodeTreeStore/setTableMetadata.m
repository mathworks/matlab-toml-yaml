function store = setTableMetadata(store, meta)
    %setTableMetadata Set metadata of this table. Empty meta clears it.
    if isempty(meta) || (isstruct(meta) && isempty(fieldnames(meta)))
        if isfield(store.Tree, "TableMetadata")
            store.Tree = rmfield(store.Tree, "TableMetadata");
        end
    else
        store.Tree.TableMetadata = meta;
    end
end

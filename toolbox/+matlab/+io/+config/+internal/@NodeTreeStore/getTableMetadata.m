function meta = getTableMetadata(store)
    %getTableMetadata Metadata of this table itself ([] if none).
    meta = [];
    if isfield(store.Tree, "TableMetadata")
        meta = store.Tree.TableMetadata;
    end
end

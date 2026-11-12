function meta = getKeyMetadata(store, key)
    %getKeyMetadata Metadata of the key entry itself ([] if none).
    meta = [];
    idx = find(store.Tree.Keys == key, 1);
    if isfield(store.Tree, "KeyMetadata") && ~isempty(idx)
        meta = store.Tree.KeyMetadata{idx};
    end
end

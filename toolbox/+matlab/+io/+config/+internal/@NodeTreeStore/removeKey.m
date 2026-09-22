function store = removeKey(store, key)
    idx = find(store.Tree.Keys == key, 1);
    if isempty(idx)
        return
    end
    store.Tree.Keys(idx) = [];
    store.Tree.Values(idx) = [];
    if isfield(store.Tree, "KeyMetadata")
        store.Tree.KeyMetadata(idx) = [];
    end
end

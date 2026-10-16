function store = removeKey(store, key)
    idx = find(store.Tree.Keys == key, 1);
    store.Tree.Keys(idx) = [];
    store.Tree.Values(idx) = [];
end

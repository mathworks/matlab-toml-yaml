function store = setValue(store, key, value)
    idx = find(store.Tree.Keys == key, 1);
    if isempty(idx)
        store.Tree.Keys(end+1) = key;
        store.Tree.Values{end+1} = value;
        if isfield(store.Tree, "KeyMetadata")
            store.Tree.KeyMetadata{end+1} = [];
        end
    else
        store.Tree.Values{idx} = value;
        if isfield(store.Tree, "KeyMetadata")
            store.Tree.KeyMetadata{idx} = [];
        end
    end
end

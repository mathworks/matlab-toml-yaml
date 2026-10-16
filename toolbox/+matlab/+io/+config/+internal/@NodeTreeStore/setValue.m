function store = setValue(store, key, value)
    value = matlab.io.config.internal.valueToNode(value);
    idx = find(store.Tree.Keys == key, 1);
    if isempty(idx)
        store.Tree.Keys(end+1) = key;
        store.Tree.Values{end+1} = value;
    else
        store.Tree.Values{idx} = value;
    end
end

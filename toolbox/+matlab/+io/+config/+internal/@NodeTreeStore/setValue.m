function store = setValue(store, key, value)
    value = matlab.io.config.internal.valueToNode(value);
    idx = find(store.Tree.Keys == key, 1);
    if isempty(idx)
        store.Tree.Keys(end+1) = key;
        store.Tree.Values{end+1} = value;
        if isfield(store.Tree, "KeyMetadata")
            store.Tree.KeyMetadata{end+1} = [];
        end
    else
        % Overwriting replaces the value node (and its metadata) but keeps
        % the key's metadata.
        store.Tree.Values{idx} = value;
    end
end

function store = setValue(store, key, value)
    idx = find(store.Struct.Keys == key, 1);
    if isempty(idx)
        store.Struct.Keys(end+1) = key;
        store.Struct.Values{end+1} = value;
        store.Expanded(end+1) = true;
    else
        store.Struct.Values{idx} = value;
        store.Expanded(idx) = true;
        store.Struct.NullIndices(store.Struct.NullIndices == idx) = [];
        store.Struct.DatetimeIndices(store.Struct.DatetimeIndices == idx) = [];
        store.Struct.QuotedIndices(store.Struct.QuotedIndices == idx) = [];
    end
end

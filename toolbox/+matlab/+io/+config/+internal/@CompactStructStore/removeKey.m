function store = removeKey(store, key)
    idx = find(store.Struct.Keys == key, 1);
    if isempty(idx)
        return
    end
    store.Struct.Keys(idx) = [];
    store.Struct.Values(idx) = [];
    store.Expanded(idx) = [];
    store.Struct.NullIndices = shiftIndices(store.Struct.NullIndices, idx);
    store.Struct.DatetimeIndices = shiftIndices(store.Struct.DatetimeIndices, idx);
    store.Struct.QuotedIndices = shiftIndices(store.Struct.QuotedIndices, idx);
end

function indices = shiftIndices(indices, removed)
    indices(indices == removed) = [];
    indices(indices > removed) = indices(indices > removed) - 1;
end

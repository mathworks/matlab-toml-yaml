function val = getValue(store, key)
    idx = find(store.Struct.Keys == key, 1);

    if store.Expanded(idx)
        val = store.Struct.Values{idx};
        return
    end

    cs = extractSingleKey(store.Struct, idx);
    obj = matlab.io.config.internal.read.expand( ...
        cs, store.Format, DatetimeType=store.DatetimeType, Recursive=false);
    val = obj.(key);
end

function cs = extractSingleKey(fullCS, idx)
    cs.Keys = fullCS.Keys(idx);
    cs.Values = fullCS.Values(idx);
    cs.NullIndices = remapIndex(fullCS.NullIndices, idx);
    cs.DatetimeIndices = remapIndex(fullCS.DatetimeIndices, idx);
    cs.QuotedIndices = remapIndex(fullCS.QuotedIndices, idx);
end

function result = remapIndex(indices, idx)
    if any(indices == idx)
        result = 1;
    else
        result = [];
    end
end

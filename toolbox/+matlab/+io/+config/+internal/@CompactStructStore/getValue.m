function val = getValue(store, key)
    idx = find(store.Struct.Keys == key, 1);

    if store.Expanded(idx)
        val = store.Struct.Values{idx};
        return
    end

    val = expandValue(store, idx);
end

function val = expandValue(store, idx)
    isNull = any(store.Struct.NullIndices == idx);
    if isNull
        val = missing;
        return
    end

    val = store.Struct.Values{idx};
    isDatetime = any(store.Struct.DatetimeIndices == idx);

    if isstruct(val) && isfield(val, 'Keys')
        innerStore = matlab.io.config.internal.CompactStructStore.fromCompactStruct( ...
            val, store.Format, DatetimeType=store.DatetimeType);
        val = matlab.io.config.ConfigurationData.fromStore(innerStore, store.Format);

    elseif iscell(val) && ~isempty(val) && isstruct(val{1}) && isfield(val{1}, 'Keys')
        children = cellfun(@(c) wrapChild(c, store), val);
        val = vertcat(children(:));

    elseif isDatetime
        if store.DatetimeType == "datetime"
            val = matlab.io.config.internal.read.parseTOMLDatetime(val);
        end

    elseif store.Format == "yaml" && store.DatetimeType == "datetime" ...
            && isstring(val) && isscalar(val)
        dt = matlab.io.config.internal.read.parseYAMLDatetime(val);
        if ~isempty(dt)
            val = dt;
        end

    elseif ~isscalar(val) && ~isempty(val)
        val = val(:);
    end
end

function child = wrapChild(childCS, store)
    innerStore = matlab.io.config.internal.CompactStructStore.fromCompactStruct( ...
        childCS, store.Format, DatetimeType=store.DatetimeType);
    child = matlab.io.config.ConfigurationData.fromStore(innerStore, store.Format);
end


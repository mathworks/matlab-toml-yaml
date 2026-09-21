function cs = toCompactStruct(store, format, precision)
    if ~any(store.Expanded) && store.Format == format
        cs = store.Struct;
        return
    end
    obj = matlab.io.config.ConfigurationData.fromStore(store, format);
    cs = matlab.io.config.internal.write.compact(obj, format, precision);
end

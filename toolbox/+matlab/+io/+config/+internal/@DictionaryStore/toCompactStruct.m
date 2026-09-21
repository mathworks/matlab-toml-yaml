function cs = toCompactStruct(store, format, precision)
    obj = matlab.io.config.ConfigurationData.fromStore(store, format);
    cs = matlab.io.config.internal.write.compact(obj, format, precision);
end

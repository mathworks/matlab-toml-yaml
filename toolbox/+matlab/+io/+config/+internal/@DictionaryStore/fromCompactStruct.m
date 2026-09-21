function store = fromCompactStruct(cs, format, options)
    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
    end
    obj = matlab.io.config.internal.read.expand(cs, format, ...
        DatetimeType=options.DatetimeType);
    store = matlab.io.config.internal.DictionaryStore();
    k = keys(obj);
    for i = 1:numel(k)
        store = setValue(store, k(i), obj.(k(i)));
    end
end

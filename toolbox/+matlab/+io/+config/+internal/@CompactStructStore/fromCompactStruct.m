function store = fromCompactStruct(cs, format, options)
    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
    end
    store = matlab.io.config.internal.CompactStructStore();
    store.Struct = cs;
    store.Format = format;
    store.DatetimeType = options.DatetimeType;
    store.Expanded = false(1, numel(cs.Keys));
end

function store = fromCompactStruct(cs, format, options)
    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
    end
    tree = matlab.io.config.internal.read.compactStructToNodeTree(cs);
    store = matlab.io.config.internal.NodeTreeStore.fromNodeTree( ...
        tree, format, DatetimeType=options.DatetimeType);
end

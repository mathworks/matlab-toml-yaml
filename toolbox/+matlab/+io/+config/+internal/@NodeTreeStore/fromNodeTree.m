function store = fromNodeTree(tree, format, options)
    arguments
        tree (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
        options.ArrayType (1,1) string ...
            {mustBeMember(options.ArrayType, ["auto", "cell"])} = "auto"
    end
    store = matlab.io.config.internal.NodeTreeStore();
    store.Tree = tree;
    store.Format = format;
    store.DatetimeType = options.DatetimeType;
    store.ArrayType = options.ArrayType;
end

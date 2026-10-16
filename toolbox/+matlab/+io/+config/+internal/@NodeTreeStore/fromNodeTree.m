function store = fromNodeTree(tree, format, options)
    arguments
        tree
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
        options.ArrayType (1,1) string ...
            {mustBeMember(options.ArrayType, ["auto", "cell"])} = "auto"
    end
    if iscell(tree)
        n = numel(tree);
        store(n) = matlab.io.config.internal.NodeTreeStore();
        for i = 1:n
            store(i) = matlab.io.config.internal.NodeTreeStore.fromNodeTree( ...
                tree{i}, format, DatetimeType=options.DatetimeType, ...
                ArrayType=options.ArrayType);
        end
    else
        store = matlab.io.config.internal.NodeTreeStore();
        store.Tree = tree;
        store.Format = format;
        store.DatetimeType = options.DatetimeType;
        store.ArrayType = options.ArrayType;
    end
end

function store = defaultStore(format)
    arguments
        format (1,1) string = "toml"
    end
    store = matlab.io.config.internal.NodeTreeStore.empty(format);
end

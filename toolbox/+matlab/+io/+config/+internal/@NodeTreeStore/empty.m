function store = empty(format)
    arguments
        format (1,1) string = "toml"
    end
    store = matlab.io.config.internal.NodeTreeStore();
    store.Format = format;
end

function obj = fromStore(store, format)
    if format == "yaml"
        obj = matlab.io.config.YAMLData();
    else
        obj = matlab.io.config.TOMLData();
    end
    obj.Data = store;
end

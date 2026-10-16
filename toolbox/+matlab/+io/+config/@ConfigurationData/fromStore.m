function obj = fromStore(store, format)
    if isscalar(store)
        if format == "yaml"
            obj = matlab.io.config.YAMLData();
        else
            obj = matlab.io.config.TOMLData();
        end
        obj.Data = store;
    else
        n = numel(store);
        if format == "yaml"
            obj(n) = matlab.io.config.YAMLData();
        else
            obj(n) = matlab.io.config.TOMLData();
        end
        for i = 1:n
            obj(i) = matlab.io.config.ConfigurationData.fromStore(store(i), format);
        end
    end
end

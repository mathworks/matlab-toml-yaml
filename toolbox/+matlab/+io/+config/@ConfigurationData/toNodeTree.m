function tree = toNodeTree(obj)
    arguments
        obj (1,1) matlab.io.config.ConfigurationData
    end
    tree = toNodeTree(obj.Data);
end

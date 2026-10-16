function tree = toNodeTree(obj)
    arguments
        obj matlab.io.config.ConfigurationData
    end
    if isscalar(obj)
        tree = toNodeTree(obj.Data);
    else
        tree = cell(1, numel(obj));
        for i = 1:numel(obj)
            tree{i} = toNodeTree(obj(i));
        end
    end
end

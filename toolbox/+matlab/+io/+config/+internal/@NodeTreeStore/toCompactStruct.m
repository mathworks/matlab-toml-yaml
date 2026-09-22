function cs = toCompactStruct(store, format, precision)
    tree = toNodeTree(store);
    cs = matlab.io.config.internal.write.nodeTreeToCompactStruct(tree, format, precision);
end

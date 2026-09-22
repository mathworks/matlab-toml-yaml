function tree = toNodeTree(store)
    tree = store.Tree;
    for i = 1:numel(tree.Keys)
        tree.Values{i} = matlab.io.config.internal.valueToNode(tree.Values{i});
    end
end

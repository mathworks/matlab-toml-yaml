function tree = toNodeTree(store)
    %toNodeTree Convert store contents to a node tree.
    %   tree = toNodeTree(store) returns a TableNode struct representing all
    %   keys and values. Default implementation iterates keys and converts
    %   MATLAB values to node tree form via valueToNode. Subclasses that
    %   store data natively as a node tree (NodeTreeStore) override this.

    k = allKeys(store);
    n = numel(k);
    values = cell(1, n);
    for i = 1:n
        values{i} = matlab.io.config.internal.valueToNode(getValue(store, k(i)));
    end
    tree = struct("Keys", k, "Values", {values});
end

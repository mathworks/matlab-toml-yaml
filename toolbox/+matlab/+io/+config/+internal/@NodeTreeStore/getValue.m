function val = getValue(store, key)
    idx = find(store.Tree.Keys == key, 1);
    val = store.Tree.Values{idx};
    val = expandNodeValue(val, store);
end

function val = expandNodeValue(val, store)
    if isstruct(val)
        if isfield(val, "Keys")
            val = wrapTableNode(val, store);
            return
        elseif isfield(val, "Data")
            val = expandValueNode(val, store);
            return
        end
    end

    if iscell(val)
        if ~isempty(val) && isstruct(val{1}) && isfield(val{1}, "Keys")
            val = wrapTableNodeCell(val, store);
            return
        end
        if isscalar(val)
            val = expandNodeValue(val{1}, store);
            return
        end
        for j = 1:numel(val)
            val{j} = expandNodeValue(val{j}, store);
        end
        return
    end

    if store.Format == "yaml" && store.DatetimeType == "datetime" ...
            && isstring(val) && isscalar(val)
        dt = matlab.io.config.internal.read.parseYAMLDatetime(val);
        if ~isempty(dt)
            val = dt;
            return
        end
    end

    if ~isscalar(val) && ~isempty(val) && ~iscell(val) && isvector(val)
        val = val(:);
    end
end

function val = expandValueNode(node, store)
    if node.Type == "missing"
        val = missing;
    elseif node.Type == "datetime"
        if store.DatetimeType == "datetime"
            val = matlab.io.config.internal.read.parseTOMLDatetime(node.Data);
        else
            val = node.Data;
        end
    end
end

function obj = wrapTableNode(tableNode, store)
    childStore = matlab.io.config.internal.NodeTreeStore.fromNodeTree( ...
        tableNode, store.Format, DatetimeType=store.DatetimeType);
    obj = matlab.io.config.ConfigurationData.fromStore(childStore, store.Format);
end

function val = wrapTableNodeCell(nodes, store)
    children = cell(size(nodes));
    for j = 1:numel(nodes)
        children{j} = wrapTableNode(nodes{j}, store);
    end
    val = vertcat(children{:});
end

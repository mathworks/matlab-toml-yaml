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
        elseif isfield(val, "Elements")
            val = expandArrayNode(val, store);
            return
        elseif isfield(val, "Data")
            val = expandValueNode(val, store);
            return
        end
    end

    if isa(val, "matlab.io.config.ConfigurationData")
        return
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
    if isfield(node, "Type")
        if node.Type == "missing"
            val = missing;
            return
        elseif node.Type == "datetime"
            if isa(node.Data, "datetime")
                val = node.Data;
            elseif store.DatetimeType == "datetime"
                val = matlab.io.config.internal.read.parseTOMLDatetime(node.Data);
            else
                val = node.Data;
            end
            return
        end
    end
    val = node.Data;
end

function val = expandArrayNode(node, store)
    elements = node.Elements;
    if ~isempty(elements) && isstruct(elements{1}) && isfield(elements{1}, "Keys")
        val = wrapTableNodeCell(elements, store);
    else
        for j = 1:numel(elements)
            elements{j} = expandNodeValue(elements{j}, store);
        end
        if store.ArrayType == "cell"
            val = elements;
        elseif store.Format == "toml" && numel(elements) == 1
            val = elements;
        else
            val = tryConsolidate(elements);
        end
    end
end


function val = tryConsolidate(elements)
    if all(cellfun(@(x) isa(x, 'double') && isscalar(x), elements))
        val = [elements{:}]';
        return
    end

    if all(cellfun(@(x) isa(x, 'int64') && isscalar(x), elements))
        val = [elements{:}]';
        return
    end

    if all(cellfun(@(x) isa(x, 'uint64') && isscalar(x), elements))
        val = [elements{:}]';
        return
    end

    if all(cellfun(@(x) islogical(x) && isscalar(x), elements))
        val = [elements{:}]';
        return
    end

    if all(cellfun(@(x) isstring(x) && isscalar(x), elements))
        val = [elements{:}]';
        return
    end

    val = elements;
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

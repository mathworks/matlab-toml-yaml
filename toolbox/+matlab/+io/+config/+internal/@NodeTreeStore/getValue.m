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
            val = expandNodeValue(val.Elements, store);
            return
        elseif isfield(val, "Data")
            val = expandValueNode(val, store);
            return
        end
    end

    if iscell(val)
        if isscalar(val)
            expanded = expandNodeValue(val{1}, store);
            if store.ArrayType == "cell" ...
                    && ~isa(expanded, 'matlab.io.config.ConfigurationData')
                val = {expanded};
            else
                val = expanded;
            end
            return
        end
        % Elements wrapped only to carry metadata were not consolidated
        % by the reader, so consolidate them after unwrapping.
        hasStyledElements = any(cellfun(@isStyledValueNode, val));
        for j = 1:numel(val)
            val{j} = expandNodeValue(val{j}, store);
        end
        if hasStyledElements && store.ArrayType ~= "cell"
            val = tryConcatenateScalars(val);
        end
        if iscell(val)
            val = tryConcatenateCell(val);
        end
        return
    end

    if store.Format == "yaml" && store.DatetimeType == "datetime" ...
            && isstring(val) && ~isempty(val)
        dt = matlab.io.config.internal.read.parseYAMLDatetime(val);
        if ~isempty(dt)
            val = dt;
            return
        end
    end

    if ~isscalar(val) && ~isempty(val) && ~iscell(val) && isvector(val)
        if store.ArrayType == "cell"
            val = num2cell(val(:));
        else
            val = val(:);
        end
    end
end

function val = expandValueNode(node, store)
    if ~isfield(node, "Type")
        val = expandNodeValue(node.Data, store);
    elseif node.Type == "missing"
        val = missing;
    elseif node.Type == "datetime"
        if store.DatetimeType == "datetime"
            val = matlab.io.config.internal.read.parseTOMLDatetime(node.Data);
        else
            val = node.Data;
        end
    end
end

function tf = isStyledValueNode(element)
    tf = isstruct(element) && isfield(element, "Data") ...
        && isfield(element, "Metadata");
end

function val = tryConcatenateScalars(val)
    concatenableTypes = ["double", "logical", "string", "int64", "uint64"];
    firstClass = class(val{1});
    if all(cellfun(@(v) isscalar(v) && ~iscell(v) ...
            && strcmp(class(v), firstClass), val)) ...
            && ismember(firstClass, concatenableTypes)
        val = vertcat(val{:});
    end
end

function obj = wrapTableNode(tableNode, store)
    childStore = matlab.io.config.internal.NodeTreeStore.fromNodeTree( ...
        tableNode, store.Format, DatetimeType=store.DatetimeType, ...
        ArrayType=store.ArrayType);
    obj = matlab.io.config.ConfigurationData.fromStore(childStore, store.Format);
end

function val = tryConcatenateCell(val)
    if all(cellfun(@(v) isa(v, 'matlab.io.config.ConfigurationData'), val))
        try
            val = vertcat(val{:});
        catch
        end
    end
end

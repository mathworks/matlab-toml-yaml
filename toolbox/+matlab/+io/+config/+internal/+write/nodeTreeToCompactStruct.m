function cs = nodeTreeToCompactStruct(tree, format, precision)
    %nodeTreeToCompactStruct Convert a node tree to a CompactStruct for the MEX writer.
    %   cs = nodeTreeToCompactStruct(tree, format, precision) converts a
    %   TableNode into the flat CompactStruct format expected by
    %   writetomlMex / writeyamlMex.
    %
    %   For YAML output, scalar values are pre-formatted via formatYAMLScalar.
    %   For TOML output, values remain as raw typed MATLAB values.

    arguments
        tree (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        precision (1,1) double {mustBeInteger, mustBePositive} = 6
    end

    isYAML = (format == "yaml");
    n = numel(tree.Keys);
    values = cell(1, n);
    nullIndices = [];
    datetimeIndices = [];
    quotedIndices = [];

    for i = 1:n
        [values{i}, idxType] = convertNode(tree.Values{i}, isYAML, precision);
        switch idxType
            case "null"
                nullIndices(end+1) = i; %#ok<AGROW>
            case "datetime"
                datetimeIndices(end+1) = i; %#ok<AGROW>
            case "quoted"
                quotedIndices(end+1) = i; %#ok<AGROW>
        end
    end

    cs.Keys = tree.Keys;
    cs.Values = values;
    cs.NullIndices = nullIndices;
    cs.DatetimeIndices = datetimeIndices;
    cs.QuotedIndices = quotedIndices;
end

function [val, idxType] = convertNode(node, isYAML, precision)
    idxType = "none";

    if isstruct(node)
        if isfield(node, "Keys")
            val = matlab.io.config.internal.write.nodeTreeToCompactStruct( ...
                node, yamlOrToml(isYAML), precision);
            return

        elseif isfield(node, "Elements")
            val = convertElements(node.Elements, isYAML, precision);
            return

        elseif isfield(node, "Data")
            if isfield(node, "Type")
                if node.Type == "missing"
                    val = [];
                    idxType = "null";
                    return
                elseif node.Type == "datetime"
                    val = parseDatetimeForWriter(node.Data);
                    idxType = "datetime";
                    return
                end
            end
            val = node.Data;
            [val, idxType] = formatLeaf(val, isYAML, precision);
            return
        end
    end

    if iscell(node)
        val = convertCellElements(node, isYAML, precision);
        return
    end

    [val, idxType] = formatLeaf(node, isYAML, precision);
end

function [val, idxType] = formatLeaf(val, isYAML, precision)
    idxType = "none";
    if isa(val, "datetime")
        idxType = "datetime";
    elseif isYAML && isscalar(val) && ~iscell(val)
        [val, quoted] = matlab.io.config.internal.write.formatYAMLScalar(val, precision);
        if quoted
            idxType = "quoted";
        end
    end
end

function val = parseDatetimeForWriter(val)
    if isstring(val) || ischar(val)
        val = matlab.io.config.internal.read.parseTOMLDatetime(string(val));
    end
end

function c = convertElements(elements, isYAML, precision)
    c = cell(size(elements));
    for j = 1:numel(elements)
        c{j} = convertNode(elements{j}, isYAML, precision);
    end
end

function c = convertCellElements(c, isYAML, precision)
    for j = 1:numel(c)
        c{j} = convertNode(c{j}, isYAML, precision);
    end
end

function f = yamlOrToml(isYAML)
    if isYAML
        f = "yaml";
    else
        f = "toml";
    end
end

classdef DescribeTextVisitor < matlab.io.config.internal.ConfigurationVisitor
    %DESCRIBETEXTVISITOR Visitor that builds describe() text output
    %   Produces indented tree lines with type annotations for each key.

    properties (Access = private)
        MaxDepth (1,1) double = Inf
    end

    methods
        function obj = DescribeTextVisitor(maxDepth)
            arguments
                maxDepth (1,1) double = Inf
            end
            obj.MaxDepth = maxDepth;
        end

        function text = describeRoot(obj, data)
            import matlab.io.config.internal.shortClassName
            import matlab.io.config.internal.pluralize

            if ~isscalar(data)
                dims = size(data);
                dimStr = join(string(dims), "x");
                arrayResult = visitArray(obj, "", data, 1);
                if isstruct(arrayResult) && isfield(arrayResult, 'childLines')
                    indent = "    ";
                    childStrs = strings(numel(arrayResult.childLines), 1);
                    for i = 1:numel(arrayResult.childLines)
                        childStrs(i) = indent + arrayResult.childLines{i} + newline;
                    end
                    text = newline + "  " + dimStr + " array" + newline + newline + ...
                        join(childStrs, "") + newline;
                else
                    text = newline + "  " + dimStr + " array" + newline + newline;
                end
            else
                className = shortClassName(class(data));
                nKeys = numel(keys(data));
                if nKeys == 0
                    text = newline + "  " + className + " with no keys" + newline + newline;
                else
                    header = newline + "  " + className + " with " + nKeys + " " + ...
                        pluralize("key", nKeys) + newline + newline;
                    lines = traverse(data, obj);
                    text = header + join(lines, "") + newline;
                end
            end
        end

        function result = visitLeaf(~, ~, value, ~)
            result = formatLeafText(value);
        end

        function result = visitNode(obj, ~, childObj, depth)
            if depth >= obj.MaxDepth
                nKeys = numel(keys(childObj));
                result = sprintf("(%d %s)", nKeys, ...
                    matlab.io.config.internal.pluralize("key", nKeys));
            else
                childLines = traverse(childObj, obj, depth + 1);
                result = join(childLines, "");
            end
        end

        function result = visitArray(obj, ~, objArray, depth)
            dims = size(objArray);
            dimStr = join(string(dims), "x");
            if depth >= obj.MaxDepth
                allKeys = matlab.io.config.internal.collectUnionOfKeys(objArray);
                nKeys = numel(allKeys);
                result = sprintf("%s array (%d %s each)", dimStr, nKeys, ...
                    matlab.io.config.internal.pluralize("key", nKeys));
            else
                childLines = buildArrayKeysText(objArray);
                result = struct('dimStr', dimStr, 'childLines', {childLines});
            end
        end

        function result = combine(~, keys, values, depth)
            result = buildLines(keys, values, depth);
        end
    end
end

classdef DescribeTextVisitor < matlab.io.config.internal.DescribeVisitor
    %DESCRIBETEXTVISITOR Visitor that builds describe() text output
    %   Produces indented tree lines with type annotations for each key.

    methods
        function obj = DescribeTextVisitor(maxDepth)
            arguments
                maxDepth (1,1) double
            end
            obj@matlab.io.config.internal.DescribeVisitor(maxDepth);
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
            import matlab.io.config.internal.introspectArrayKeys
            import matlab.io.config.internal.collectUnionOfKeys
            import matlab.io.config.internal.pluralize

            dims = size(objArray);
            dimStr = join(string(dims), "x");
            if depth >= obj.MaxDepth
                allKeys = collectUnionOfKeys(objArray);
                nKeys = numel(allKeys);
                result = sprintf("%s array (%d %s each)", dimStr, nKeys, ...
                    pluralize("key", nKeys));
            else
                info = introspectArrayKeys(objArray);
                lines = {};
                if ~isempty(info)
                    allKeys = [info.Key];
                    maxKeyLen = max(strlength(allKeys));
                    keyColumnWidth = max(maxKeyLen + 2, 20);

                    for i = 1:numel(info)
                        entry = info(i);
                        if entry.IsNested
                            if entry.IsNestedArray
                                typeDisplay = sprintf("%s array (%d %s each)", ...
                                    entry.Size, entry.NestedKeyCount, ...
                                    pluralize("key", entry.NestedKeyCount));
                            else
                                typeDisplay = sprintf("(%d %s)", ...
                                    entry.NestedKeyCount, ...
                                    pluralize("key", entry.NestedKeyCount));
                            end
                        else
                            typeDisplay = entry.Type;
                        end
                        paddedKey = pad(entry.Key + ":", keyColumnWidth);
                        lines{end+1} = sprintf("%s%s", paddedKey, typeDisplay); %#ok<AGROW>
                    end
                end
                result = struct('dimStr', dimStr, 'childLines', {lines});
            end
        end

        function result = combine(~, keys, values, depth)
            result = buildLines(keys, values, depth);
        end
    end

    methods (Access = protected)
        function text = formatNonScalarRoot(obj, data)
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
        end

        function text = formatScalarRoot(obj, data)
            import matlab.io.config.internal.shortClassName
            import matlab.io.config.internal.pluralize

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
end

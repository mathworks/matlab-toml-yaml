classdef DescribeTableVisitor < matlab.io.config.internal.DescribeVisitor
    %DESCRIBETABLEVISITOR Visitor that builds describe() table output
    %   Each method returns a table with Path, Type, Size columns.

    methods
        function obj = DescribeTableVisitor(maxDepth)
            arguments
                maxDepth (1,1) double = Inf
            end
            obj@matlab.io.config.internal.DescribeVisitor(maxDepth);
        end

        function result = visitLeaf(~, ~, value, ~)
            result = makeRow(value);
        end

        function result = visitNode(obj, ~, childObj, depth)
            result = makeRow(childObj);
            if depth < obj.MaxDepth
                childResult = traverse(childObj, obj, depth + 1);
                result = [result; childResult];
            end
        end

        function result = visitArray(obj, ~, objArray, depth)
            import matlab.io.config.internal.introspectArrayKeys

            result = makeRow(objArray);
            if depth < obj.MaxDepth
                info = introspectArrayKeys(objArray);
                childRows = emptyDescribeTable();
                for i = 1:numel(info)
                    entry = info(i);
                    childRows = [childRows; {entry.Key, entry.Type, entry.Size}]; %#ok<AGROW>
                end
                result = [result; childRows];
            end
        end

        function result = combine(~, keys, values, ~)
            result = combineRows(keys, values);
        end
    end

    methods (Access = protected)
        function result = formatNonScalarRoot(obj, data)
            result = visitArray(obj, "", data, 1);
            result(1,:) = [];
        end

        function result = formatScalarRoot(obj, data)
            result = traverse(data, obj);
        end
    end
end

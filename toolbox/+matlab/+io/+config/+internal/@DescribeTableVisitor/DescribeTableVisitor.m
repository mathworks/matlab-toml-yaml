classdef DescribeTableVisitor < matlab.io.config.internal.ConfigurationVisitor
    %DESCRIBETABLEVISITOR Visitor that builds describe() table output
    %   Each method returns a table with Path, Type, Size columns.

    properties (Access = private)
        MaxDepth (1,1) double = Inf
    end

    methods
        function obj = DescribeTableVisitor(maxDepth)
            arguments
                maxDepth (1,1) double = Inf
            end
            obj.MaxDepth = maxDepth;
        end

        function result = describeRoot(obj, data)
            if ~isscalar(data)
                result = visitArray(obj, "", data, 1);
                result(1,:) = [];
            else
                result = traverse(data, obj);
            end
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
            result = makeRow(objArray);
            if depth < obj.MaxDepth
                childRows = collectArrayRows(objArray);
                result = [result; childRows];
            end
        end

        function result = combine(~, keys, values, ~)
            result = combineRows(keys, values);
        end
    end
end

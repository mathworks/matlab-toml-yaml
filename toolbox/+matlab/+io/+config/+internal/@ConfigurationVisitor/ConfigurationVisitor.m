classdef (Abstract) ConfigurationVisitor
    %CONFIGURATIONVISITOR Abstract interface for ConfigurationData traversal
    %   Subclass and implement visitLeaf, combine, and optionally
    %   visitNode and visitArray.
    %   Pass to traverse(configData, visitor) to walk the tree.
    %
    %   visitNode is called for scalar ConfigurationData children.
    %   visitArray is called for non-scalar ConfigurationData children.
    %   combine assembles per-key results into the final output.
    %
    %   See also ConfigurationStorage/traverse, FunctionHandleVisitor

    methods (Abstract)
        result = visitLeaf(obj, key, value, depth)
        result = combine(obj, keys, values, depth)
    end

    methods
        function result = visitNode(obj, ~, childObj, depth)
            result = traverse(childObj, obj, depth + 1);
        end

        function results = visitArray(obj, key, objArray, depth)
            results = cell(1, numel(objArray));
            for i = 1:numel(objArray)
                results{i} = visitNode(obj, key, objArray(i), depth);
            end
        end
    end
end

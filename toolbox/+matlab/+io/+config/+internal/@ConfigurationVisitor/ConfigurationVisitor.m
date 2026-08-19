classdef (Abstract) ConfigurationVisitor
    %CONFIGURATIONVISITOR Abstract interface for ConfigurationData traversal
    %   Subclass and implement visitNode, visitLeaf, and combine.
    %   Pass to traverse(configData, visitor) to walk the tree.
    %
    %   visitNode is called for ConfigurationData children. The default
    %   implementation recurses via traverse(child, obj).
    %
    %   See also ConfigurationStorage/traverse, FunctionHandleVisitor

    methods (Abstract)
        result = visitLeaf(obj, key, value, depth)
        result = combine(obj, keys, values)
    end

    methods
        function result = visitNode(obj, ~, childObj, depth)
            result = traverse(childObj, obj, depth + 1);
        end
    end
end

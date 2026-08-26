classdef FunctionHandleVisitor < matlab.io.config.internal.ConfigurationVisitor
    %FUNCTIONHANDLEVISITOR Visitor using function handles for callbacks
    %   v = FunctionHandleVisitor(leafFcn, combineFcn)
    %   v = FunctionHandleVisitor(leafFcn, combineFcn, nodeFcn)
    %
    %   leafFcn(key, value, depth)    — called for primitive values
    %   combineFcn(keys, values)      — assembles the final result
    %   nodeFcn(key, childObj, depth) — optional, overrides recursive descent

    properties (Access = private)
        LeafFcn function_handle
        CombineFcn function_handle
        NodeFcn function_handle = function_handle.empty
    end

    methods
        function obj = FunctionHandleVisitor(leafFcn, combineFcn, nodeFcn)
            arguments
                leafFcn function_handle
                combineFcn function_handle
                nodeFcn function_handle = function_handle.empty
            end
            obj.LeafFcn = leafFcn;
            obj.CombineFcn = combineFcn;
            obj.NodeFcn = nodeFcn;
        end

        function result = visitNode(obj, key, childObj, depth)
            if isempty(obj.NodeFcn)
                result = traverse(childObj, obj, depth + 1);
            else
                result = obj.NodeFcn(key, childObj, depth);
            end
        end

        function result = visitLeaf(obj, key, value, depth)
            result = obj.LeafFcn(key, value, depth);
        end

        function result = combine(obj, keys, values, depth)
            result = obj.CombineFcn(keys, values, depth);
        end
    end
end

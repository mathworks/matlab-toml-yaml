classdef (Abstract) DescribeVisitor < matlab.io.config.internal.ConfigurationVisitor
    %DESCRIBEVISITOR Base class for describe() visitors
    %   Provides MaxDepth and the describeRoot template method.
    %   Subclasses implement format-specific root handling.

    properties (Access = protected)
        MaxDepth (1,1) double = Inf
    end

    methods
        function obj = DescribeVisitor(maxDepth)
            % maxDepth is required: describe() always has a value for it,
            % from its own Depth default, so a default here would only add
            % an unreachable second one.
            arguments
                maxDepth (1,1) double
            end
            obj.MaxDepth = maxDepth;
        end

        function out = describeRoot(obj, data)
            if ~isscalar(data)
                out = formatNonScalarRoot(obj, data);
            else
                out = formatScalarRoot(obj, data);
            end
        end
    end

    methods (Abstract, Access = protected)
        out = formatNonScalarRoot(obj, data)
        out = formatScalarRoot(obj, data)
    end
end

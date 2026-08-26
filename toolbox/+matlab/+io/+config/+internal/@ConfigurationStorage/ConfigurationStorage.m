classdef (Abstract) ConfigurationStorage
    %CONFIGURATIONSTORAGE Abstract base declaring Data storage and accessors

    properties (Abstract, Access = protected)
        Data dictionary
    end

    methods (Access = protected)
        resolvedKeys = resolveKey(obj, key)

        result = tryConcatenate(obj, values, fieldName)
    end

    methods (Access = {?matlab.io.config.internal.ConfigurationStorage, ...
            ?matlab.io.config.internal.ConfigurationVisitor})
        result = traverse(obj, visitor, depth)
    end

    methods (Static, Access = protected)
        array = normalizeVectorOrientation(array)
    end
end

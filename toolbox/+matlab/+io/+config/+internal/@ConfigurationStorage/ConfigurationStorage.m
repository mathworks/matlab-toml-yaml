classdef (Abstract) ConfigurationStorage
    %CONFIGURATIONSTORAGE Abstract base declaring Data storage and accessors

    properties (Abstract, Access = protected)
        Data dictionary
    end

    methods (Access = protected)
        function obj = setData(obj, key, value)
            %SETDATA Set value in Data dictionary (wraps in cell)
            %   Validates the value type before storing.
            %   Normalizes array orientation for consistent concatenation.
            key = string(key);
            value = matlab.io.config.internal.validateValue(obj, value, key);
            value = obj.normalizeVectorOrientation(value);
            obj.Data(key) = {value};
        end

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

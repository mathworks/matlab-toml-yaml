classdef (Abstract) ConfigurationStorage
    %CONFIGURATIONSTORAGE Abstract base declaring Data storage and accessors

    properties (Abstract, Access = protected)
        % No type annotation here — R2022b errors with
        % 'PropTypeMultipleAbstractValidations' when the same typed
        % abstract property is inherited through multiple superclass paths.
        Data
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

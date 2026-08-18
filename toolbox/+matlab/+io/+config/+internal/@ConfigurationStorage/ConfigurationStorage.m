classdef (Abstract) ConfigurationStorage
    %CONFIGURATIONSTORAGE Abstract base declaring Data storage and accessors

    properties (Abstract, Access = protected)
        Data dictionary
    end

    methods (Hidden)
        function value = getData(obj, key)
            %GETDATA Get value from Data dictionary (unwraps cell)
            key = string(key);
            val = obj.Data(key);
            value = val{1};
        end

        function obj = setData(obj, key, value)
            %SETDATA Set value in Data dictionary (wraps in cell)
            %   Validates the value type before storing.
            %   Normalizes array orientation for consistent concatenation.
            key = string(key);
            value = obj.validateAndConvertValue(value, key);
            value = obj.normalizeVectorOrientation(value);
            obj.Data(key) = {value};
        end
    end

    methods (Access = protected)
        value = validateAndConvertValue(obj, value, key)

        result = tryConcatenate(obj, values, fieldName)
    end

    methods (Static, Access = protected)
        array = normalizeVectorOrientation(array)
    end
end

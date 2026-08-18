function value = convertImportValue(obj, value)
%CONVERTIMPORTVALUE Recursively convert nested structs/dicts to ConfigurationData
%   This preserves the class type (YAMLData stays YAMLData, etc.)

if isstruct(value)
    if isscalar(value)
        % Scalar struct -> ConfigurationData of same class
        nested = createArray(class(obj));
        nested = importFrom(nested, value);
        value = nested;
    else
        % Struct array -> array of ConfigurationData
        arr(numel(value)) = createArray(class(obj));
        for iVal = 1:numel(value)
            arr(iVal) = obj.convertImportValue(value(iVal));
        end
        value = arr;
    end
elseif isa(value, 'dictionary')
    % Dictionary -> ConfigurationData of same class
    nested = createArray(class(obj));
    nested = importFrom(nested, value);
    value = nested;
end
% Other types (numeric, string, etc.) pass through unchanged
% They will be validated by setData when assigned
end

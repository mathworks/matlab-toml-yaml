function obj = setData(obj, key, value)
%SETDATA Set value in Data dictionary (wraps in cell)
%   Validates the value type before storing.
%   Normalizes array orientation for consistent concatenation (Issue #77).
key = string(key);
value = obj.validateAndConvertValue(value, key);
value = obj.normalizeVectorOrientation(value);
obj.Data(key) = {value};
end

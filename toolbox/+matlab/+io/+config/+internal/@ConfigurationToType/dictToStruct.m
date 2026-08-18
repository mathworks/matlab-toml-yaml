function s = dictToStruct(obj, d)
%DICTTOSTRUCT Convert dictionary to struct recursively (private helper)
s = struct;
dictKeys = keys(d);
for i = 1:length(dictKeys)
    key = dictKeys(i);
    val = d(key);
    value = val{1};  % Unwrap from cell

    % Recursively handle nested dictionaries
    if isa(value, 'dictionary')
        value = obj.dictToStruct(value);
    end

    fieldName = matlab.lang.makeValidName(key);
    s.(fieldName) = value;
end
end

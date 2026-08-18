function s = struct(obj)
% Handle non-scalar array: convert each element
if ~isscalar(obj)
    structCell = cell(size(obj));
    for i = 1:numel(obj)
        structCell{i} = struct(obj(i));
    end
    s = reshape([structCell{:}], size(obj));
    return;
end

s = struct;
originalKeys = keys(obj.Data);
for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            value = struct(value);
        else
            % Handle array of ConfigurationData objects
            structCell = cell(1, numel(value));
            for iVal = 1:numel(value)
                structCell{iVal} = struct(value(iVal));
            end
            value = [structCell{:}];
        end
    elseif isa(value, 'dictionary')
        % Recursively convert dictionary to struct
        value = obj.dictToStruct(value);
    end

    fieldName = matlab.lang.makeValidName(key);
    s.(fieldName) = value;
end
end

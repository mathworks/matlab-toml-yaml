function m = map(obj)
%MAP Convert to containers.Map (for compatibility)
m = containers.Map('KeyType', 'char', 'ValueType', 'any');
originalKeys = keys(obj.Data);
for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        value = map(value);
    end

    m(char(key)) = value;
end
end

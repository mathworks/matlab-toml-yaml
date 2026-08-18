function m = map(obj)
%MAP Convert to containers.Map (for compatibility)
m = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:length(obj.xInternal__.OriginalKeys)
    key = obj.xInternal__.OriginalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        value = map(value);
    end

    m(char(key)) = value;
end
end

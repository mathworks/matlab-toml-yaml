function cs = toCompactStruct(obj, format, precision)
    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        precision (1,1) double {mustBeInteger, mustBePositive} = 6
    end
    cs = toCompactStruct(obj.Data, format, precision);
end

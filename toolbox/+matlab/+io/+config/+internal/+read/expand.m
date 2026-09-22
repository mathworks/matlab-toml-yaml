function obj = expand(cs, format, options)
    %expand Convert a CompactStruct to a ConfigurationData object.
    %   obj = expand(cs, format) returns a YAMLData or TOMLData object.
    %
    %   cs is a struct with fields:
    %     Keys           - (1×n string) key names
    %     Values         - (1×n cell) scalar values or nested CompactStructs
    %     NullIndices    - (1×m double) indices where value is null
    %     DatetimeIndices - (1×m double) indices where value is a datetime
    %     QuotedIndices  - (1×m double) (unused, retained for write path)
    %
    %   format is "yaml" or "toml".
    %
    %   Optional name-value:
    %     DatetimeType - "string" (default) or "datetime". When "datetime",
    %                    TOML datetime strings are parsed as datetime objects.

    arguments
        cs (1,1) struct
        format (1,1) string {mustBeMember(format, ["yaml", "toml"])}
        options.DatetimeType (1,1) string {mustBeMember(options.DatetimeType, ["string", "datetime"])} = "datetime"
    end

    store = matlab.io.config.internal.CompactStructStore.fromCompactStruct( ...
        cs, format, DatetimeType=options.DatetimeType);
    obj = matlab.io.config.ConfigurationData.fromStore(store, format);
end

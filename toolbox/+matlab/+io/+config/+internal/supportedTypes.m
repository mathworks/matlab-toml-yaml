function types = supportedTypes()
    %SUPPORTEDTYPES Return the supported type definitions for ConfigurationData
    %   types = matlab.io.config.internal.supportedTypes() returns a struct with:
    %     .storage  — types stored as-is (string list)
    %     .input    — types accepted as input, auto-converted to a storage type (string list)

    persistent cached
    if isempty(cached)
        cached.storage = ["string", "double", "single", ...
            "int8", "int16", "int32", "int64", ...
            "uint8", "uint16", "uint32", "uint64", ...
            "logical", "datetime", "missing", ...
            "cell", "matlab.io.config.ConfigurationData"];
        cached.input = ["char", "duration", "struct", "dictionary"];
    end
    types = cached;
end

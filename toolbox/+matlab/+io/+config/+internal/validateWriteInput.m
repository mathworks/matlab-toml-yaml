function tree = validateWriteInput(data, format)
    %VALIDATEWRITEINPUT Validate, normalize, and convert data for writing.
    %   Shared by writeyaml and writetoml. Converts char to string, rejects
    %   complex numbers, wraps mapping types as the appropriate
    %   ConfigurationData subclass, and returns the node tree (or
    %   passthrough primitive for YAML).

    if ischar(data)
        data = string(data);
    end

    if isnumeric(data) && ~isreal(data)
        error("write" + format + ":InvalidInput", ...
            "Complex numbers are not supported in " + upper(format) + ".");
    end

    if isa(data, "dictionary") || isstruct(data) || isa(data, "containers.Map")
        if format == "yaml"
            data = yamldata(data);
        else
            data = tomldata(data);
        end
    elseif format == "toml" && ~isa(data, "matlab.io.config.ConfigurationData")
        error("writetoml:InvalidInput", ...
            "Input must be TOMLData, struct, dictionary, or containers.Map.");
    end

    if isa(data, "matlab.io.config.ConfigurationData")
        tree = toNodeTree(data);
    else
        tree = data;
    end
end

function format = formatName(obj)
    %formatName "toml" for TOMLData, "yaml" otherwise.
    if isa(obj, "matlab.io.config.TOMLData")
        format = "toml";
    else
        format = "yaml";
    end
end

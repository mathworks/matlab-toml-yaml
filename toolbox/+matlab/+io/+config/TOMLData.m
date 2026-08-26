classdef TOMLData < matlab.io.config.ConfigurationData
    %TOMLDATA TOML configuration data with dot notation access
    %   Struct-like data type for TOML files, providing dot notation access,
    %   preservation of key order, and support for special characters in
    %   field names (like hyphens).
    %
    %   This is a value class. Assignment creates an independent copy.
    %
    %   To create a TOMLData object, use the informal wrapper function:
    %       data = tomldata();           % empty
    %       data = tomldata(myStruct);   % from struct
    %
    %   Example:
    %       data = readtoml('pyproject.toml');
    %       name = data.project.name;
    %       deps = data.("build-system").requires;
    %       show(data);  % Display as TOML
    %
    %   See also TOMLDATA, READTOML, WRITETOML

    methods
        function show(obj)
            %SHOW Display the data in TOML format
            matlab.io.config.internal.showAsFormat(obj, @writetoml, ...
                {"TableArrayStyle", "expanded"});
        end
    end

end

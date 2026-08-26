classdef YAMLData < matlab.io.config.ConfigurationData
    %YAMLDATA YAML-specific configuration data
    %   Struct-like data type for YAML files, providing dot notation access,
    %   support for special characters in keys, and value semantics.
    %   Future versions may include YAML-specific features such as:
    %   - Preserving comments
    %   - Handling YAML anchors and aliases
    %   - YAML-specific type conversions
    %
    %   This is a value class. Assignment creates an independent copy.
    %
    %   To create a YAMLData object, use the informal wrapper function:
    %       data = yamldata();           % empty
    %       data = yamldata(myStruct);   % from struct
    %
    %   See also: YAMLDATA, READYAML, WRITEYAML

    methods
        function obj = YAMLData()
            %YAMLDATA Construct empty YAML configuration data object
            %   obj = YAMLData() creates an empty YAMLData object
            %
            %   To create from existing data, use the yamldata() function:
            %       config = yamldata(myStruct);
            %
            %   See also YAMLDATA

            obj@matlab.io.config.ConfigurationData();
        end

        function show(obj)
            %SHOW Display contents as YAML
            %   show(obj) displays the YAMLData object as YAML text.
            matlab.io.config.internal.showAsFormat(obj, @writeyaml);
        end
    end
end

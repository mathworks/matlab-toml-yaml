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
            obj.SourceFormat = "yaml";
        end

        function show(obj)
            %SHOW Display contents as YAML
            %   show(obj) displays the YAMLData object as YAML text.
            %   This is useful for viewing deeply nested structures at the
            %   command line.
            %
            %   For arrays, displays each element as a YAML list item.
            %
            %   Example:
            %       show(data)
            %
            %   See also writeyaml

            tempFile = [tempname '.yaml'];
            try
                if isscalar(obj)
                    % Scalar case - write directly
                    writeyaml(obj, tempFile);
                else
                    % Array case - wrap in container and write as list
                    wrapper = matlab.io.config.YAMLData;
                    wrapper.item = obj;
                    writeyaml(wrapper, tempFile);
                end
                yamlText = fileread(tempFile);
                fprintf('%s\n', yamlText);
            catch
                % If writeyaml fails, fall back to default display
                disp(obj);
            end

            % Clean up
            if isfile(tempFile)
                delete(tempFile);
            end
        end
    end
end

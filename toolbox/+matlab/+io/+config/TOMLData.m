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
        function obj = TOMLData()
            %TOMLDATA Construct empty TOMLData object
            %   obj = TOMLData() creates an empty TOMLData object
            %
            %   To create from existing data, use the tomldata() function:
            %       config = tomldata(myStruct);
            %
            %   See also TOMLDATA

            obj@matlab.io.config.ConfigurationData();
            obj.xInternal__.SourceFormat = "toml";
        end

        function show(obj)
            %SHOW Display the data in TOML format
            %   show(data) writes the TOMLData to a temporary file and
            %   displays the TOML content in the command window.
            %
            %   For arrays, displays each element as an array of tables
            %   using [[item]] syntax.
            %
            %   This is useful for viewing the TOML representation of the data.

            if isscalar(obj)
                % Scalar case - write directly
                try
                    tempFile = tempname;
                    writetoml(obj, tempFile);
                    content = fileread(tempFile);
                    fprintf('%s\n', content);
                    delete(tempFile);
                catch
                    disp(obj);
                end
            else
                % Array case - wrap in container and write as array of tables
                try
                    wrapper = matlab.io.config.TOMLData;
                    wrapper.item = obj;
                    tempFile = tempname;
                    writetoml(wrapper, tempFile, TableArrayStyle="expanded");
                    content = fileread(tempFile);
                    fprintf('%s\n', content);
                    delete(tempFile);
                catch
                    disp(obj);
                end
            end
        end
    end

    methods (Access = protected)
        function value = validateAndConvertValue(obj, value, key)
            %VALIDATEANDCONVERTVALUE TOML-specific type validation
            %   TOML natively supports datetime, so keep it as-is.

            % TOML supports datetime natively - don't convert
            if isa(value, 'datetime')
                return;  % Keep as datetime
            end

            % For all other types, use base class validation
            value = validateAndConvertValue@matlab.io.config.ConfigurationData(obj, value, key);
        end
    end
end

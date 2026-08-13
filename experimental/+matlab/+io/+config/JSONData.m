classdef JSONData < matlab.io.config.ConfigurationData
    %JSONDATA JSON-specific configuration data
    %   Subclass of ConfigurationData with JSON-specific features.
    %
    %   JSONData provides the same interface as ConfigurationData but is
    %   specifically designed for JSON configuration files (package.json,
    %   tsconfig.json, etc.). This class is optimized for usability with
    %   configuration data and accepts lossy round-trips.
    %
    %   For strict JSON round-tripping where null values, array structure,
    %   and type distinctions must be preserved exactly, consider using
    %   jsondecode/jsonencode directly.
    %
    %   This is a value class. Assignment creates an independent copy.
    %
    %   To create a JSONData object, use the informal wrapper function:
    %       data = jsondata();           % empty
    %       data = jsondata(myStruct);   % from struct
    %
    %   See also: JSONDATA, matlab.io.config.ConfigurationData, READJSON, WRITEJSON

    methods
        function obj = JSONData()
            %JSONDATA Construct empty JSON configuration data object
            %   obj = JSONData() creates an empty JSONData object
            %
            %   To create from existing data, use the jsondata() function:
            %       config = jsondata(myStruct);
            %
            %   See also JSONDATA

            obj@matlab.io.config.ConfigurationData();
            obj.xInternal__.SourceFormat = "json";
        end

        function show(obj)
            %SHOW Display contents as JSON
            %   show(obj) displays the JSONData object as formatted JSON text.
            %   This is useful for viewing deeply nested structures at the
            %   command line.
            %
            %   For arrays, displays each element as a JSON array item.
            %
            %   Example:
            %       show(data)
            %
            %   See also writejson

            tempFile = [tempname '.json'];
            try
                if isscalar(obj)
                    % Scalar case - write directly
                    writejson(obj, tempFile);
                else
                    % Array case - wrap in container and write as list
                    wrapper = matlab.io.config.JSONData;
                    wrapper.items = obj;
                    writejson(wrapper, tempFile);
                end
                jsonText = fileread(tempFile);
                fprintf('%s\n', jsonText);
            catch
                % If writejson fails, fall back to default display
                disp(obj);
            end

            % Clean up
            if isfile(tempFile)
                delete(tempFile);
            end
        end
    end
end

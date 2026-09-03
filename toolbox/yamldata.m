function data = yamldata(input)
    %YAMLDATA Create a YAMLData object for storing YAML-style configuration
    %   data = YAMLDATA() creates an empty YAMLData object.
    %
    %   data = YAMLDATA(input) creates a YAMLData object initialized from input,
    %   which can be a struct, dictionary, or containers.Map.
    %
    %   Example:
    %       % Create empty and populate
    %       config = yamldata();
    %       config.database.host = 'localhost';
    %       config.database.port = 5432;
    %
    %       % Create from struct
    %       s.name = 'MyApp';
    %       s.version = '1.0';
    %       config = yamldata(s);
    %
    %       % Create from containers.Map
    %       m = containers.Map({'host','port'}, {'localhost',5432});
    %       config = yamldata(m);
    %
    %   See also: readyaml, writeyaml, matlab.io.config.YAMLData

    if nargin == 0
        data = matlab.io.config.YAMLData();
    else
        data = matlab.io.config.YAMLData();
        data = importFrom(data, input);
    end
end

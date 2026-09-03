function d = dictionary(obj)
    %DICTIONARY Convert to MATLAB dictionary
    %   d = dictionary(obj) converts the ConfigurationData to a
    %   dictionary with string keys and cell values.
    %
    %   Nested ConfigurationData objects are recursively converted
    %   to nested dictionaries.
    %
    %   Example:
    %       config = readyaml('config.yaml');
    %       d = dictionary(config);
    %       value = d{"keyName"};
    %
    %   See also STRUCT, MAP
    v = matlab.io.config.internal.FunctionHandleVisitor( ...
        @(~, value, ~) value, ...
        @toDictionary ...
        );
    d = traverse(obj, v);
end

function d = toDictionary(keys, values, ~)
    d = dictionary(string.empty, cell.empty);
    for i = 1:numel(keys)
        d(keys(i)) = values(i);
    end
end

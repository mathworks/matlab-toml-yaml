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

d = configureDictionary("string", "cell");
originalKeys = keys(obj.Data);
for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            value = dictionary(value);  % Recursive
        else
            % Array of ConfigurationData -> cell array of dictionaries
            tmpCell = cell(1, numel(value));
            for iVal = 1:numel(value)
                tmpCell{iVal} = dictionary(value(iVal));
            end
            value = tmpCell;
        end
    end

    d(key) = {value};
end
end

function lines = buildArrayKeysText(obj, indent)
%BUILDARRAYKEYSTEXT Build type-only display for ConfigurationData array keys
lines = {};

uniqueKeys = collectUnionOfKeys(obj);

if isempty(uniqueKeys)
    return;
end

maxKeyLen = max(strlength(uniqueKeys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:length(uniqueKeys)
    key = uniqueKeys(i);

    % Find type from first element that has this key
    typeDisplay = "";
    for j = 1:numel(obj)
        if iskey(obj(j), key)
            value = getData(obj(j), key);
            if isa(value, 'matlab.io.config.ConfigurationData')
                if isscalar(value)
                    nKeys = length(keys(value));
                    typeDisplay = sprintf("(%d %s)", nKeys, ...
                        matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                else
                    dims = size(value);
                    dimStr = join(string(dims), "x");
                    childKeys = collectUnionOfKeys(value);
                    nKeys = length(childKeys);
                    typeDisplay = sprintf("%s array (%d %s each)", dimStr, nKeys, ...
                        matlab.io.config.ConfigurationData.pluralize("key", nKeys));
                end
            else
                typeDisplay = string(class(value));
            end
            break;
        end
    end

    paddedKey = pad(key + ":", keyColumnWidth);
    lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, typeDisplay); %#ok<AGROW>
end
end

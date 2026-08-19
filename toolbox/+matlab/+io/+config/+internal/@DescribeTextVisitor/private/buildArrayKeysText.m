function lines = buildArrayKeysText(objArray)
%BUILDARRAYKEYSTEXT Build type-only lines for ConfigurationData array keys
import matlab.io.config.internal.collectUnionOfKeys
import matlab.io.config.internal.pluralize

lines = {};
uniqueKeys = collectUnionOfKeys(objArray);

if isempty(uniqueKeys)
    return;
end

maxKeyLen = max(strlength(uniqueKeys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:numel(uniqueKeys)
    key = uniqueKeys(i);
    typeDisplay = "";
    for j = 1:numel(objArray)
        if iskey(objArray(j), key)
            value = getData(objArray(j), key);
            if isa(value, 'matlab.io.config.ConfigurationData')
                if isscalar(value)
                    nKeys = numel(keys(value));
                    typeDisplay = sprintf("(%d %s)", nKeys, ...
                        pluralize("key", nKeys));
                else
                    dims = size(value);
                    dimStr = join(string(dims), "x");
                    childKeys = collectUnionOfKeys(value);
                    nKeys = numel(childKeys);
                    typeDisplay = sprintf("%s array (%d %s each)", dimStr, nKeys, ...
                        pluralize("key", nKeys));
                end
            else
                typeDisplay = string(class(value));
            end
            break;
        end
    end
    paddedKey = pad(key + ":", keyColumnWidth);
    lines{end+1} = sprintf("%s%s", paddedKey, typeDisplay); %#ok<AGROW>
end
end

function [paths, types, sizes] = collectArrayRows(obj, prefix, paths, types, sizes, ~, ~)
%COLLECTARRAYROWS Collect table rows for a ConfigurationData array
import matlab.io.config.internal.collectUnionOfKeys
import matlab.io.config.internal.shortClassName

uniqueKeys = collectUnionOfKeys(obj);

for i = 1:length(uniqueKeys)
    key = uniqueKeys(i);

    if prefix == ""
        fullPath = key;
    else
        fullPath = prefix + "." + key;
    end

    % Collect types across all elements that have this key
    foundTypes = string.empty(0,1);
    firstSize = "";
    for j = 1:numel(obj)
        if iskey(obj(j), key)
            val = obj(j).getData(key);
            typeName = string(shortClassName(class(val)));
            if ~any(foundTypes == typeName)
                foundTypes(end+1,1) = typeName; %#ok<AGROW>
            end
            if firstSize == ""
                firstSize = join(string(size(val)), "x");
            end
        end
    end

    if isscalar(foundTypes)
        displayType = foundTypes(1);
    else
        displayType = "mixed types: " + join(foundTypes, ", ");
    end

    paths(end+1,1) = fullPath; %#ok<AGROW>
    types(end+1,1) = displayType; %#ok<AGROW>
    sizes(end+1,1) = firstSize; %#ok<AGROW>
end
end

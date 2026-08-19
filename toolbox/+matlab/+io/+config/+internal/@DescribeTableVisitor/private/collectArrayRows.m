function result = collectArrayRows(objArray)
%COLLECTARRAYROWS Collect table rows for a ConfigurationData array
import matlab.io.config.internal.collectUnionOfKeys
import matlab.io.config.internal.shortClassName

result = emptyDescribeTable();
uniqueKeys = collectUnionOfKeys(objArray);

for i = 1:numel(uniqueKeys)
    key = uniqueKeys(i);

    foundTypes = string.empty(0,1);
    firstSize = "";
    for j = 1:numel(objArray)
        if iskey(objArray(j), key)
            val = getData(objArray(j), key);
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

    result = [result; {key, displayType, firstSize}]; %#ok<AGROW>
end
end

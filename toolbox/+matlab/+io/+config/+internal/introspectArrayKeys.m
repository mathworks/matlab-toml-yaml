function info = introspectArrayKeys(objArray)
    %INTROSPECTARRAYKEYS Collect type and size info for each key across a ConfigurationData array
    %   Returns a struct array with fields: Key, Type, Size, IsMixed, IsNested, NestedKeyCount
    import matlab.io.config.internal.collectUnionOfKeys
    import matlab.io.config.internal.shortClassName
    import matlab.io.config.internal.pluralize

    uniqueKeys = collectUnionOfKeys(objArray);
    nKeys = numel(uniqueKeys);

    info = struct('Key', cell(nKeys, 1), 'Type', [], 'Size', [], ...
        'IsMixed', [], 'IsNested', [], 'IsNestedArray', [], 'NestedKeyCount', []);

    for i = 1:nKeys
        key = uniqueKeys(i);
        info(i).Key = key;

        foundTypes = string.empty(0, 1);
        firstSize = "";
        isNested = false;
        isNestedArray = false;
        nestedKeyCount = 0;

        for j = 1:numel(objArray)
            if iskey(objArray(j), key)
                val = objArray(j).(key);
                typeName = string(shortClassName(class(val)));
                if ~any(foundTypes == typeName)
                    foundTypes(end+1, 1) = typeName; %#ok<AGROW>
                end
                if firstSize == ""
                    firstSize = join(string(size(val)), "x");
                    if isa(val, 'matlab.io.config.ConfigurationData')
                        isNested = true;
                        if isscalar(val)
                            nestedKeyCount = numel(keys(val));
                        else
                            isNestedArray = true;
                            childKeys = collectUnionOfKeys(val);
                            nestedKeyCount = numel(childKeys);
                        end
                    end
                end
            end
        end

        if isscalar(foundTypes)
            info(i).Type = foundTypes(1);
            info(i).IsMixed = false;
        else
            info(i).Type = "mixed types: " + join(foundTypes, ", ");
            info(i).IsMixed = true;
        end
        info(i).Size = firstSize;
        info(i).IsNested = isNested;
        info(i).IsNestedArray = isNestedArray;
        info(i).NestedKeyCount = nestedKeyCount;
    end
end

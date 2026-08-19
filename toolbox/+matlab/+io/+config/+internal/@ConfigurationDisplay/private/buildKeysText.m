function lines = buildKeysText(obj, indent, currentDepth, maxDepth, includeTypes)
%BUILDKEYSTEXT Build visual tree lines for a scalar object's keys
%   buildKeysText(obj, indent, depth, maxDepth, true)  — with type annotations (describe)
%   buildKeysText(obj, indent, depth, maxDepth, false) — without (show)
lines = {};
originalKeys = keys(obj);

if isempty(originalKeys)
    return;
end

maxKeyLen = max(strlength(originalKeys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            if currentDepth >= maxDepth
                nKeys = length(keys(value));
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                    nKeys, pluralize("key", nKeys)); %#ok<AGROW>
            else
                lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                childLines = buildKeysText(value, indent + "    ", currentDepth + 1, maxDepth, includeTypes);
                lines = [lines, childLines]; %#ok<AGROW>
            end
        else
            dims = size(value);
            dimStr = join(string(dims), "x");
            if includeTypes && currentDepth >= maxDepth
                allKeys = collectUnionOfKeys(value);
                nUniqueKeys = length(allKeys);
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s%s array (%d %s each)\n', indent, paddedKey, ...
                    dimStr, nUniqueKeys, pluralize("key", nUniqueKeys)); %#ok<AGROW>
            else
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
                if includeTypes
                    childLines = buildArrayKeysText(value, indent + "    ");
                    lines = [lines, childLines]; %#ok<AGROW>
                else
                    for j = 1:numel(value)
                        lines{end+1} = sprintf('%s%s(%d) =\n', indent, key, j); %#ok<AGROW>
                        childLines = buildKeysText(value(j), indent + "    ", currentDepth + 1, maxDepth, includeTypes);
                        lines = [lines, childLines]; %#ok<AGROW>
                    end
                end
            end
        end
    elseif isa(value, 'missing')
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
    elseif isempty(value)
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    elseif ischar(value) || (isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value)))
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            formatLeafValue(value, includeTypes)); %#ok<AGROW>
    else
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    end
end
end

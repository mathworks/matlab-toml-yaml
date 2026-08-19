function lines = buildKeysText(obj, indent, currentDepth, maxDepth)
%BUILDKEYSTEXT Build visual tree lines with type annotations
import matlab.io.config.internal.collectUnionOfKeys
import matlab.io.config.internal.pluralize

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
    paddedKey = pad(key + ":", keyColumnWidth);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            if currentDepth >= maxDepth
                nKeys = length(keys(value));
                lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                    nKeys, pluralize("key", nKeys)); %#ok<AGROW>
            else
                lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                childLines = buildKeysText(value, indent + "    ", currentDepth + 1, maxDepth);
                lines = [lines, childLines]; %#ok<AGROW>
            end
        else
            dims = size(value);
            dimStr = join(string(dims), "x");
            if currentDepth >= maxDepth
                allKeys = collectUnionOfKeys(value);
                nUniqueKeys = length(allKeys);
                lines{end+1} = sprintf('%s%s%s array (%d %s each)\n', indent, paddedKey, ...
                    dimStr, nUniqueKeys, pluralize("key", nUniqueKeys)); %#ok<AGROW>
            else
                lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
                childLines = buildArrayKeysText(value, indent + "    ");
                lines = [lines, childLines]; %#ok<AGROW>
            end
        end
    elseif isa(value, 'missing')
        lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
    elseif isempty(value)
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    elseif isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value))
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            formatLeafValue(value)); %#ok<AGROW>
    else
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    end
end
end

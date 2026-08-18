function lines = buildKeysText(obj, indent, currentDepth, maxDepth)
%BUILDKEYSTEXT Build visual tree lines for a scalar object's keys
lines = {};
originalKeys = keys(obj);

if isempty(originalKeys)
    return;
end

% Calculate key column width for alignment
maxKeyLen = max(strlength(originalKeys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            if currentDepth >= maxDepth
                % Depth-limited: show key count
                nKeys = length(keys(value));
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                    nKeys, pluralize("key", nKeys)); %#ok<AGROW>
            else
                % Expanded: show key as header, recurse
                lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                childLines = buildKeysText(value, indent + "    ", currentDepth + 1, maxDepth);
                lines = [lines, childLines]; %#ok<AGROW>
            end
        else
            % ConfigurationData array
            dims = size(value);
            dimStr = join(string(dims), "x");
            if currentDepth >= maxDepth
                % Depth-limited: show array dims and key count
                allKeys = collectUnionOfKeys(value);
                nUniqueKeys = length(allKeys);
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s%s array (%d %s each)\n', indent, paddedKey, ...
                    dimStr, nUniqueKeys, pluralize("key", nUniqueKeys)); %#ok<AGROW>
            else
                % Expanded: show array header then union of keys with types
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
                childLines = buildArrayKeysText(value, indent + "    ");
                lines = [lines, childLines]; %#ok<AGROW>
            end
        end
    elseif isa(value, 'missing')
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
    elseif ischar(value)
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            formatLeafValue(value)); %#ok<AGROW>
    elseif isempty(value)
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    elseif isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value))
        % Scalar leaf - show value with type annotation
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            formatLeafValue(value)); %#ok<AGROW>
    else
        % Non-scalar leaf - show size and type
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    end
end
end

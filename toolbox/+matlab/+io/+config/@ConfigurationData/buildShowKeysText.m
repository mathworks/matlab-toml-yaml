function lines = buildShowKeysText(obj, indent, currentDepth, maxDepth)
%BUILDSHOWKEYSTEXT Build value tree lines for show() — no type annotations,
%   arrays expanded with ND-array style key(i) = headers
lines = {};
originalKeys = obj.xInternal__.OriginalKeys;

if isempty(originalKeys)
    return;
end

maxKeyLen = max(strlength(originalKeys));
keyColumnWidth = max(maxKeyLen + 2, 20);

for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = getData(obj, key);

    if isa(value, 'matlab.io.config.ConfigurationData')
        if isscalar(value)
            if currentDepth >= maxDepth
                nKeys = length(keys(value));
                paddedKey = pad(key + ":", keyColumnWidth);
                lines{end+1} = sprintf('%s%s(%d %s)\n', indent, paddedKey, ...
                    nKeys, matlab.io.config.ConfigurationData.pluralize("key", nKeys)); %#ok<AGROW>
            else
                lines{end+1} = sprintf('%s%s:\n', indent, key); %#ok<AGROW>
                childLines = buildShowKeysText(value, indent + "    ", currentDepth + 1, maxDepth);
                lines = [lines, childLines]; %#ok<AGROW>
            end
        else
            % ConfigurationData array: ND-array style, one element per block
            dims = size(value);
            dimStr = join(string(dims), "x");
            paddedKey = pad(key + ":", keyColumnWidth);
            lines{end+1} = sprintf('%s%s%s array\n', indent, paddedKey, dimStr); %#ok<AGROW>
            for j = 1:numel(value)
                lines{end+1} = sprintf('%s%s(%d) =\n', indent, key, j); %#ok<AGROW>
                childLines = buildShowKeysText(value(j), indent + "    ", currentDepth + 1, maxDepth);
                lines = [lines, childLines]; %#ok<AGROW>
            end
        end
    elseif isa(value, 'missing')
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%smissing\n', indent, paddedKey); %#ok<AGROW>
    elseif isempty(value)
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    elseif ischar(value)
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            matlab.io.config.ConfigurationData.formatShowLeafValue(value)); %#ok<AGROW>
    elseif isscalar(value) && (isstring(value) || isnumeric(value) || islogical(value))
        paddedKey = pad(key + ":", keyColumnWidth);
        lines{end+1} = sprintf('%s%s%s\n', indent, paddedKey, ...
            matlab.io.config.ConfigurationData.formatShowLeafValue(value)); %#ok<AGROW>
    else
        % Non-scalar leaf: show size and type
        paddedKey = pad(key + ":", keyColumnWidth);
        sizeStr = join(string(size(value)), "x");
        lines{end+1} = sprintf('%s%s%s %s\n', indent, paddedKey, sizeStr, class(value)); %#ok<AGROW>
    end
end
end

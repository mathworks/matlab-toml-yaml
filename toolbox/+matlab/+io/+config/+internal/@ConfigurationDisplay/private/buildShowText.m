function text = buildShowText(obj, varName)
%BUILDSHOWTEXT Build value-focused display string for show()
lines = {};

if ~isscalar(obj)
    % Top-level array: ND array style (like X(:,:,k) = )
    for i = 1:numel(obj)
        lines{end+1} = sprintf('%s(%d) =\n', varName, i); %#ok<AGROW>
        lines{end+1} = newline; %#ok<AGROW>
        childLines = buildShowKeysText(obj(i), "    ", 1, Inf);
        lines = [lines, childLines]; %#ok<AGROW>
        lines{end+1} = newline; %#ok<AGROW>
        lines{end+1} = newline; %#ok<AGROW>
    end
else
    % Scalar: header then indented key-value tree
    className = shortClassName(class(obj));
    nKeys = numel(keys(obj));
    if nKeys == 0
        lines{end+1} = sprintf('\n  %s with no keys\n\n', className);
    else
        lines{end+1} = sprintf('\n  %s with %d %s\n\n', className, nKeys, ...
            pluralize("key", nKeys));
        lines = [lines, buildShowKeysText(obj, "    ", 1, Inf)];
        lines{end+1} = newline;
    end
end

text = strjoin(lines, '');
end

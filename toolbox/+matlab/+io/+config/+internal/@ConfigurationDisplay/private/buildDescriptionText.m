function text = buildDescriptionText(obj, maxDepth, includeTypes, varName)
%BUILDDESCRIPTIONTEXT Build visual tree string
%   buildDescriptionText(obj, maxDepth, true)      — for describe() (with types)
%   buildDescriptionText(obj, maxDepth, false, name) — for show() (values only)
lines = {};

if ~isscalar(obj)
    dims = size(obj);
    dimStr = join(string(dims), "x");
    if includeTypes
        lines{end+1} = sprintf('\n  %s array\n\n', dimStr);
        lines = [lines, buildArrayKeysText(obj, "    ")];
    else
        for i = 1:numel(obj)
            lines{end+1} = sprintf('%s(%d) =\n', varName, i); %#ok<AGROW>
            lines{end+1} = newline; %#ok<AGROW>
            childLines = buildKeysText(obj(i), "    ", 1, Inf, false);
            lines = [lines, childLines]; %#ok<AGROW>
            lines{end+1} = newline; %#ok<AGROW>
            lines{end+1} = newline; %#ok<AGROW>
        end
    end
else
    className = shortClassName(class(obj));
    nKeys = numel(keys(obj));
    if nKeys == 0
        lines{end+1} = sprintf('\n  %s with no keys\n\n', className);
    else
        lines{end+1} = sprintf('\n  %s with %d %s\n\n', className, nKeys, ...
            pluralize("key", nKeys));
        lines = [lines, buildKeysText(obj, "    ", 1, maxDepth, includeTypes)];
        lines{end+1} = newline;
    end
end

text = strjoin(lines, '');
end

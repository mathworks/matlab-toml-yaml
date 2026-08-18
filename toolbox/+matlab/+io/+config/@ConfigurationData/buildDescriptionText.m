function text = buildDescriptionText(obj, maxDepth)
%BUILDDESCRIPTIONTEXT Build visual tree string for describe()
lines = {};

if ~isscalar(obj)
    % Non-scalar array header
    dims = size(obj);
    dimStr = join(string(dims), "x");
    lines{end+1} = sprintf('\n  %s array\n\n', dimStr);
    lines = [lines, buildArrayKeysText(obj, "    ")];
    lines{end+1} = newline;
else
    % Scalar object header
    className = matlab.io.config.ConfigurationData.shortClassName(class(obj));
    nKeys = numEntries(obj.Data);
    if nKeys == 0
        lines{end+1} = sprintf('\n  %s with no keys\n\n', className);
    else
        lines{end+1} = sprintf('\n  %s with %d %s\n\n', className, nKeys, ...
            matlab.io.config.ConfigurationData.pluralize("key", nKeys));
        lines = [lines, buildKeysText(obj, "    ", 1, maxDepth)];
        lines{end+1} = newline;
    end
end

text = strjoin(lines, '');
end

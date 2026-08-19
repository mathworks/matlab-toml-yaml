function rep = compactRepresentationForSingleLine(obj, displayConfiguration, ~)
%COMPACTREPRESENTATIONFORSINGLELINE Compact display when nested in another object
%   Shows "[1x1 YAMLData with 3 keys]" instead of "[1×1 matlab.io.config.YAMLData]"

className = shortClassName(class(obj));

if isscalar(obj)
    nKeys = numel(keys(obj));
    text = sprintf("[1%s1 %s with %d %s]", char(215), className, nKeys, pluralize("key", nKeys));
else
    dims = size(obj);
    dimStr = join(string(dims), char(215));
    text = sprintf("[%s %s]", dimStr, className);
end

rep = matlab.display.PlainTextRepresentation(obj, text, displayConfiguration);
end

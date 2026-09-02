function result = getformat(obj, keyPath)
%GETFORMAT Query format metadata for configuration data keys
%   meta = getformat(obj, key) returns the resolved metadata for key.
%   meta = getformat(obj, [key1, key2]) returns an array of metadata.
%   meta = getformat(obj, "a.b.c") navigates nested key paths.
%   tbl = getformat(obj) returns a summary table of all top-level keys.
%   getformat(obj) with no output displays the summary table.
%
%   Resolved values reflect inheritance — the metadata the writer would
%   actually use. Keys with no explicit metadata inherit from the parent.
%
%   See also: setformat, resetformat, NodeMetadata

if nargin < 2
    result = buildSummaryTable(obj);
    if nargout == 0
        disp(result);
        clear result;
    end
    return;
end

keyPath = string(keyPath);
if isscalar(keyPath)
    result = getOneKey(obj, keyPath);
else
    result = arrayfun(@(k) getOneKey(obj, k), keyPath);
end
end

function meta = getOneKey(obj, keyPath)
parts = split(keyPath, ".");
currentObj = obj;
for i = 1:numel(parts)-1
    resolved = resolveKey(currentObj, parts(i));
    if ismissing(resolved)
        meta = makeDefaultMetadata(obj);
        return;
    end
    val = currentObj.Data{resolved};
    if ~isa(val, 'matlab.io.config.ConfigurationData')
        meta = makeDefaultMetadata(obj);
        return;
    end
    currentObj = val;
end

leafKey = parts(end);
resolved = resolveKey(currentObj, leafKey);
if ismissing(resolved)
    meta = makeDefaultMetadata(obj);
    return;
end

val = currentObj.Data{resolved};
if isa(val, 'matlab.io.config.ConfigurationData') && ~isempty(val.Metadata)
    meta = val.Metadata;
    return;
end

if ~isempty(currentObj.Metadata) && isConfigured(currentObj.Metadata.Keys) ...
        && isKey(currentObj.Metadata.Keys, resolved)
    meta = currentObj.Metadata.Keys{resolved};
    return;
end

if ~isempty(currentObj.Metadata)
    meta = copyInherited(currentObj.Metadata, obj);
    return;
end

meta = makeDefaultMetadata(obj);
end

function meta = makeDefaultMetadata(obj)
if isa(obj, 'matlab.io.config.TOMLData')
    meta = matlab.io.config.TOMLMetadata();
else
    meta = matlab.io.config.YAMLMetadata();
end
end

function meta = copyInherited(parentMeta, obj)
if isa(obj, 'matlab.io.config.TOMLData')
    meta = matlab.io.config.TOMLMetadata( ...
        ContainerStyle=parentMeta.ContainerStyle, ...
        ScalarStyle=parentMeta.ScalarStyle);
else
    meta = matlab.io.config.YAMLMetadata( ...
        ContainerStyle=parentMeta.ContainerStyle, ...
        ScalarStyle=parentMeta.ScalarStyle);
end
end

function tbl = buildSummaryTable(obj)
k = keys(obj);
n = numel(k);
containerStyles = strings(n, 1);
scalarStyles = strings(n, 1);
isArrayFlags = false(n, 1);

for i = 1:n
    meta = getformat(obj, k(i));
    containerStyles(i) = meta.ContainerStyle;
    scalarStyles(i) = meta.ScalarStyle;
    isArrayFlags(i) = meta.IsArray;
end

tbl = table(k(:), containerStyles, scalarStyles, isArrayFlags, ...
    VariableNames=["Key", "ContainerStyle", "ScalarStyle", "IsArray"]);
end

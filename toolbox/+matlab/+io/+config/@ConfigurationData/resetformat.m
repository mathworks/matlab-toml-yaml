function obj = resetformat(obj, keyPath)
%RESETFORMAT Reset format metadata to defaults
%   obj = resetformat(obj, key) removes metadata for the specified key.
%   obj = resetformat(obj, [key1, key2]) removes metadata for multiple keys.
%   obj = resetformat(obj) clears all metadata on this node.
%
%   Returns a modified copy (value class semantics).
%
%   See also: getformat, setformat, NodeMetadata

if nargin < 2
    obj.Metadata = [];
    return;
end

keyPath = string(keyPath);
for i = 1:numel(keyPath)
    obj = resetOneKey(obj, keyPath(i));
end
end

function obj = resetOneKey(obj, keyPath)
parts = split(keyPath, ".");
if numel(parts) > 1
    obj = resetNestedKey(obj, parts);
    return;
end

leafKey = parts(1);
resolved = resolveKey(obj, leafKey);
if ismissing(resolved)
    return;
end

val = obj.Data{resolved};
if isa(val, 'matlab.io.config.ConfigurationData')
    val.Metadata = [];
    obj.Data{resolved} = val;
    return;
end

if ~isempty(obj.Metadata) && isConfigured(obj.Metadata.Keys) ...
        && isKey(obj.Metadata.Keys, resolved)
    obj.Metadata.Keys = remove(obj.Metadata.Keys, resolved);
end
end

function obj = resetNestedKey(obj, parts)
resolved = resolveKey(obj, parts(1));
if ismissing(resolved)
    return;
end
val = obj.Data{resolved};
if ~isa(val, 'matlab.io.config.ConfigurationData')
    return;
end
remainingPath = join(parts(2:end), ".");
val = resetformat(val, remainingPath);
obj.Data{resolved} = val;
end

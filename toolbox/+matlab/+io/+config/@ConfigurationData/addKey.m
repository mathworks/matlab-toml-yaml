function obj = addKey(obj, key)
%ADDKEY Add a key to the key order tracking if not already present
%   Used by parsers when directly manipulating data.
key = string(key);
if ~any(obj.xInternal__.OriginalKeys == key)
    obj.xInternal__.OriginalKeys(end+1) = key;
end
end

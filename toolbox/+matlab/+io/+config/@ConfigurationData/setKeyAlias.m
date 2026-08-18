function obj = setKeyAlias(obj, alias, originalKey)
%SETKEYALIAS Set a key alias mapping
%   Used by parsers when key names need valid MATLAB identifiers.
alias = string(alias);
originalKey = string(originalKey);
obj.xInternal__.KeyAliases(alias) = originalKey;
end

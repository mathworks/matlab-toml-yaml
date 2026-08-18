function target = copySourceFormat(obj, target)
%COPYSOURCEFORMAT Copy SourceFormat to another ConfigurationData object
%   Uses builtin to bypass overloaded dot methods, preventing
%   SourceFormat from being added as a user data key.
s = substruct('.', 'xInternal__');
internal = builtin('subsref', target, s);
internal.SourceFormat = obj.xInternal__.SourceFormat;
target = builtin('subsasgn', target, s, internal);
end

function target = copySourceFormat(obj, target)
%COPYSOURCEFORMAT Copy SourceFormat to another ConfigurationData object
%   Uses builtin to bypass overloaded dot methods.
s = substruct('.', 'SourceFormat');
target = builtin('subsasgn', target, s, obj.SourceFormat);
end

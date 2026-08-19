function show(obj)
%SHOW Display all values as an indented tree
%   For format-specific subclasses (YAMLData, TOMLData), show()
%   displays in the native file format.
%
%   Arrays are displayed using the same style as MATLAB's ND array
%   display, with each element labeled varname(i) =
%
%   See also describe
varName = inputname(1);
if isempty(varName)
    varName = 'ans';
end
text = buildDescriptionText(obj, Inf, false, varName);
fprintf('%s', text);
end

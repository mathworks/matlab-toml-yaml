function s = struct(obj)
%STRUCT Convert to MATLAB struct
%   s = struct(obj) converts the ConfigurationData to a struct.
%   Nested ConfigurationData objects are recursively converted.
%   ConfigurationData arrays become struct arrays.
%   Keys are converted to valid MATLAB identifiers.

% Handle non-scalar: convert each element, concatenate into struct array
if ~isscalar(obj)
    structCell = cell(size(obj));
    for i = 1:numel(obj)
        structCell{i} = struct(obj(i));
    end
    s = reshape([structCell{:}], size(obj));
    return;
end

v = matlab.io.config.internal.FunctionHandleVisitor( ...
    @(~, value, ~) value, ...
    @toStruct, ...
    @(~, child, ~) struct(child) ...
);
s = traverse(obj, v);
end

function s = toStruct(keys, values, ~)
s = struct();
for i = 1:numel(keys)
    fieldName = matlab.lang.makeValidName(keys(i));
    value = values{i};
    if iscell(value) && ~isempty(value) && isstruct(value{1})
        value = [value{:}];
    end
    s.(fieldName) = value;
end
end

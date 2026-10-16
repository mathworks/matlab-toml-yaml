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
        structCell = reconcileFields(structCell);
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
            value = reconcileFields(value);
            value = [value{:}];
        end
        s.(fieldName) = value;
    end
end

function structCell = reconcileFields(structCell)
    allFields = string.empty(1, 0);
    for i = 1:numel(structCell)
        allFields = union(allFields, string(fieldnames(structCell{i}))', 'stable');
    end
    for i = 1:numel(structCell)
        for f = allFields
            if ~isfield(structCell{i}, f)
                structCell{i}.(f) = missing;
            end
        end
        structCell{i} = orderfields(structCell{i}, cellstr(allFields));
    end
end

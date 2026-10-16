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
    fieldNames = matlab.lang.makeUniqueStrings( ...
        matlab.lang.makeValidName(keys), {}, namelengthmax);
    s = struct();
    for i = 1:numel(keys)
        value = values{i};
        if iscell(value) && ~isempty(value) && any(cellfun(@isstruct, value))
            value = wrapNonStructElements(value);
            value = reconcileFields(value);
            value = [value{:}];
        end
        s.(fieldNames(i)) = value;
    end
end

function c = wrapNonStructElements(c)
    for i = 1:numel(c)
        if ~isstruct(c{i})
            c{i} = struct("Element", c{i});
        end
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

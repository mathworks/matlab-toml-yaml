function result = traverse(obj, visitor, depth)
%TRAVERSE Walk the key-value tree, delegating to a visitor
%   result = traverse(obj, visitor) recursively visits all keys.
%   The visitor must implement visitNode, visitLeaf, and combine.
%
%   Descends into:
%     - ConfigurationData values (scalar and array)
%     - Cell arrays (checking each element for nested ConfigurationData)
%
%   See also ConfigurationVisitor, FunctionHandleVisitor
arguments
    obj (1,1) matlab.io.config.ConfigurationData
    visitor (1,1) matlab.io.config.internal.ConfigurationVisitor
    depth (1,1) double = 1
end

k = keys(obj);
transformedValues = cell(size(k));

for i = 1:numel(k)
    value = obj.getData(k(i));
    transformedValues{i} = applyVisitor(obj, visitor, k(i), value, depth);
end

result = combine(visitor, k, transformedValues);
end

function result = applyVisitor(obj, visitor, key, value, depth)
if isa(value, 'matlab.io.config.ConfigurationData')
    if isscalar(value)
        result = visitNode(visitor, key, value, depth);
    else
        results = cell(size(value));
        for i = 1:numel(value)
            results{i} = visitNode(visitor, key, value(i), depth);
        end
        result = results;
    end
elseif iscell(value)
    result = cell(size(value));
    for i = 1:numel(value)
        result{i} = applyVisitor(obj, visitor, key, value{i}, depth);
    end
else
    result = visitLeaf(visitor, key, value, depth);
end
end

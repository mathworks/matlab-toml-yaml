function m = map(obj)
%MAP Convert to containers.Map (for compatibility)
v = matlab.io.config.internal.FunctionHandleVisitor( ...
    @(~, value, ~) value, ...
    @toMap ...
);
m = traverse(obj, v);
end

function m = toMap(keys, values)
m = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:numel(keys)
    m(char(keys(i))) = values{i};
end
end

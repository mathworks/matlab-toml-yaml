function varargout = dotReference(obj, indexOp, ~)
% With OverridesPublicDotMethodCall, ALL dot notation from outside
% the class comes here first. Data keys take priority over methods.

% Non-scalar: arr.field(idx)... — paren selects array elements
if ~isscalar(obj) && numel(indexOp) > 1 ...
        && indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
    [varargout{1:nargout}] = dotReference(obj(indexOp(2).Indices{:}), indexOp([1 3:end]));
    return;
end

% Resolve the first dot to a value
fieldName = indexOp(1).Name;
if isscalar(obj)
    resolvedKey = matlab.io.config.internal.resolveKey(obj.Data, fieldName);
    if isempty(resolvedKey)
        error('ConfigurationData:InvalidKey', 'Key "%s" does not exist.', fieldName);
    end
    value = obj.getData(resolvedKey);
else
    hasKey = iskey(obj, fieldName);
    if ~any(hasKey)
        error('ConfigurationData:InvalidKey', 'Key "%s" does not exist.', fieldName);
    end
    values = cell(size(obj));
    for i = 1:numel(obj)
        if hasKey(i)
            resolvedKey = matlab.io.config.internal.resolveKey(obj(i).Data, fieldName);
            values{i} = obj(i).getData(resolvedKey);
        else
            values{i} = missing;
        end
    end
    value = tryConcatenate(obj, values, fieldName);
end

% Forward remaining indexing to the resolved value
if numel(indexOp) > 1
    [varargout{1:nargout}] = value.(indexOp(2:end));
else
    varargout{1} = value;
end
end

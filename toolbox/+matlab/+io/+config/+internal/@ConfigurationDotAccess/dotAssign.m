function obj = dotAssign(obj, indexOp, varargin)

% Non-scalar: arr.field(idx)... = value — paren selects array elements
if ~isscalar(obj) && numel(indexOp) > 1 ...
        && indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
    idx = indexOp(2).Indices{:};
    selected = obj(idx);
    selected = dotAssign(selected, indexOp([1 3:end]), varargin{:});
    obj(idx) = selected;
    return;
end

key = indexOp(1).Name;

% Non-scalar: delegate to each element
if ~isscalar(obj)
    value = varargin{end};
    numElements = numel(obj);

    % Simple assign with element-wise distribution
    if numel(indexOp) == 1 && numel(value) == numElements
        for i = 1:numElements
            obj(i) = dotAssign(obj(i), indexOp, value(i));
        end
    elseif numel(indexOp) == 1 && ~(isscalar(value) || numel(value) == 1)
        error('ConfigurationData:SizeMismatch', ...
            'Value size (%d) does not match array size (%d).', ...
            numel(value), numElements);
    else
        for i = 1:numElements
            obj(i) = dotAssign(obj(i), indexOp, varargin{:});
        end
    end
    return;
end

% Scalar: simple assignment
if numel(indexOp) == 1
    obj = storeValue(obj, key, varargin{end});
    return;
end

% Scalar: chained assignment — get or create, forward, store back
if isKey(obj.Data, key)
    value = obj.Data{key};
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot ...
            && ~isa(value, 'matlab.io.config.ConfigurationData')
        value = createArray(class(obj));
    end
else
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        error('ConfigurationData:InvalidIndex', ...
            'Cannot index into non-existent field ''%s''', key);
    end
    value = createArray(class(obj));
end

[value.(indexOp(2:end))] = varargin{:};
obj = storeValue(obj, key, value);
end

function obj = storeValue(obj, key, value)
value = matlab.io.config.internal.validateValue(obj, value, key);
value = obj.normalizeVectorOrientation(value);
obj.Data(key) = {value};
end

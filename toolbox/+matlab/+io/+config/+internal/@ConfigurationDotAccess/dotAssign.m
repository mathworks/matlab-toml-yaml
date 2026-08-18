function obj = dotAssign(obj, indexOp, varargin)
key = indexOp(1).Name;

% Handle non-scalar array assignment
if ~isscalar(obj)
    value = varargin{end};
    numElements = numel(obj);

    % Case 1: arr.field = value (assign to ALL elements)
    if numel(indexOp) == 1
        if isscalar(value) || (numel(value) == 1)
            for i = 1:numElements
                obj(i) = dotAssign(obj(i), indexOp, value);
            end
        elseif numel(value) == numElements
            for i = 1:numElements
                obj(i) = dotAssign(obj(i), indexOp, value(i));
            end
        else
            error('ConfigurationData:SizeMismatch', ...
                'Value size (%d) does not match array size (%d).', ...
                numel(value), numElements);
        end
        return;
    end

    % Case 2: arr.field(idx)... = value — paren selects array elements
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        idx = indexOp(2).Indices{:};
        selected = obj(idx);
        % Apply arr.field = value (and any remaining chain) to selected subset
        selected = dotAssign(selected, indexOp([1 3:end]), varargin{:});
        obj(idx) = selected;
        return;
    end

    % Case 3: arr.field.sub... = value — delegate to each element
    for i = 1:numElements
        obj(i) = dotAssign(obj(i), indexOp, varargin{:});
    end
    return;
end

% Scalar case
if numel(indexOp) == 1
    % Simple assignment: obj.key = value
    obj = obj.setData(key, varargin{end});
else
    % Chained assignment: obj.key.sub = value, obj.key(idx) = value, etc.
    % Get or create the value at the first key
    if isKey(obj.Data, key)
        value = obj.getData(key);
        if numel(indexOp) > 1 && indexOp(2).Type == matlab.indexing.IndexingOperationType.Dot ...
                && ~isa(value, 'matlab.io.config.ConfigurationData')
            % Dot-chaining into a non-ConfigurationData value: auto-create
            value = feval(class(obj));
        end
    else
        if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
            error('ConfigurationData:InvalidIndex', ...
                'Cannot index into non-existent field ''%s''', key);
        end
        % Auto-create nested object for dot-chaining
        value = feval(class(obj));
    end

    % Forward remaining indexing operations to the value
    [value.(indexOp(2:end))] = varargin{:};

    % Store the modified value back
    obj = obj.setData(key, value);
end
end

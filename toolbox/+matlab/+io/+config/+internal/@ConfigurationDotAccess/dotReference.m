function varargout = dotReference(obj, indexOp, ~)
% Handle dot notation (.) for data key access
%
% With OverridesPublicDotMethodCall, ALL dot notation from outside
% the class comes here first. We prioritize data keys over methods,
% so users can have keys named "keys", "isfield", etc.
% To call methods, use function syntax: keys(obj), isfield(obj, key)

% Handle array dot reference: arr.field returns concatenated values
if ~isscalar(obj)
    fieldName = indexOp(1).Name;

    % Check if next operation is Paren - pre-filter array by any valid index
    % This enables patterns: arr.field(1), arr.field(1:5), arr.field(logicalMask)
    remainingIndexOp = indexOp(2:end);
    if numel(indexOp) > 1 && indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        indices = indexOp(2).Indices;
        if numel(indices) == 1
            idx = indices{1};
            obj = obj(idx);
            if isnumeric(idx)
                obj = reshape(obj, size(idx));
            elseif islogical(idx)
                if isrow(idx)
                    obj = reshape(obj, 1, []);
                elseif iscolumn(idx)
                    obj = reshape(obj, [], 1);
                end
            end
            remainingIndexOp = indexOp(3:end);
        end
    end

    % Check which elements have the key (on potentially pre-filtered array)
    hasKey = iskey(obj, fieldName);

    if ~any(hasKey)
        error('ConfigurationData:InvalidKey', ...
            'Key "%s" does not exist.', fieldName);
    end

    % Collect values from all elements
    values = cell(size(obj));
    for i = 1:numel(obj)
        if hasKey(i)
            resolvedKey = matlab.io.config.internal.resolveKey(obj(i).Data, fieldName);
            values{i} = obj(i).getData(resolvedKey);
        else
            values{i} = missing;
        end
    end

    result = tryConcatenate(obj, values, fieldName);

    % Forward remaining indexing to the concatenated result
    if ~isempty(remainingIndexOp)
        [varargout{1:nargout}] = result.(remainingIndexOp);
    else
        varargout{1} = result;
    end
    return;
end

key = indexOp(1).Name;

resolvedKey = matlab.io.config.internal.resolveKey(obj.Data, key);
if ~isempty(resolvedKey)
    value = obj.getData(resolvedKey);

    % Forward remaining indexing operations to the retrieved value
    if numel(indexOp) > 1
        [varargout{1:nargout}] = value.(indexOp(2:end));
    else
        varargout{1} = value;
    end
    return;
end

% Key doesn't exist - error
error('ConfigurationData:InvalidKey', ...
    'Key "%s" does not exist.', key);
end

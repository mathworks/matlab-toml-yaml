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
            % Pre-filter the array by any valid index (numeric, logical, range, etc.)
            obj = obj(idx);
            % Preserve index shape: reshape result to match idx shape
            % For numeric idx, use idx shape; for logical, use sum(idx) with idx orientation
            if isnumeric(idx)
                obj = reshape(obj, size(idx));
            elseif islogical(idx)
                % Logical index: result count is sum(idx), preserve row/column orientation
                if isrow(idx)
                    obj = reshape(obj, 1, []);
                elseif iscolumn(idx)
                    obj = reshape(obj, [], 1);
                end
                % Otherwise keep whatever MATLAB gave us
            end
            remainingIndexOp = indexOp(3:end);  % Skip the Paren we just consumed
        end
    end

    % Check which elements have the key (on potentially pre-filtered array)
    hasKey = iskey(obj, fieldName);

    % If NO elements have the key, error (key doesn't exist on this array)
    if ~any(hasKey)
        error('ConfigurationData:InvalidKey', ...
            'Key "%s" does not exist.', fieldName);
    end

    % Collect values from all elements
    % For elements lacking the key, insert missing (read-only convenience)
    values = cell(size(obj));
    for i = 1:numel(obj)
        if hasKey(i)
            resolvedKey = matlab.io.config.internal.resolveKey(obj(i).Data, fieldName);
            values{i} = obj(i).getData(resolvedKey);
        else
            values{i} = missing;
        end
    end

    % Try to concatenate homogeneously
    result = tryConcatenate(obj, values, fieldName);

    % Handle chained indexing on the result
    if ~isempty(remainingIndexOp)
        if isa(result, 'matlab.io.config.ConfigurationData') && ~isscalar(result)
            % Recursive array dot reference
            result = dotReference(result, remainingIndexOp);
        elseif isa(result, 'matlab.io.config.ConfigurationData') && isscalar(result)
            result = dotReference(result, remainingIndexOp);
        else
            % Can't chain into non-ConfigurationData
            error('ConfigurationData:InvalidChain', ...
                'Cannot chain into non-ConfigurationData value');
        end
    end

    varargout{1} = result;
    return;
end

if indexOp(1).Type == "Dot"
    % Dot notation: obj.key
    key = indexOp(1).Name;

    % PRIORITY 1: Check if key exists in data (allows "keys", "isfield", etc.)
    resolvedKey = matlab.io.config.internal.resolveKey(obj.Data, key);
    if ~isempty(resolvedKey)
        value = obj.getData(resolvedKey);

        % Handle chained indexing
        if length(indexOp) > 1
            if indexOp(2).Type == "Paren"
                % Array indexing: obj.key(indices)
                indices = indexOp(2).Indices{:};
                value = value(indices);

                % Handle further chaining: obj.key(1).field
                if length(indexOp) > 2
                    if isa(value, 'matlab.io.config.ConfigurationData')
                        value = dotReference(value, indexOp(3:end));
                    else
                        error('ConfigurationData:InvalidChain', ...
                            'Cannot chain into non-ConfigurationData value');
                    end
                end
            elseif indexOp(2).Type == "Brace"
                % Cell array indexing: obj.key{indices}
                indices = indexOp(2).Indices{:};
                value = value{indices};

                % Handle further chaining: obj.key{1}.field
                if length(indexOp) > 2
                    if isa(value, 'matlab.io.config.ConfigurationData')
                        value = dotReference(value, indexOp(3:end));
                    else
                        error('ConfigurationData:InvalidChain', ...
                            'Cannot chain into non-ConfigurationData value');
                    end
                end
            elseif indexOp(2).Type == "Dot"
                % Nested dot: obj.key.field
                if isa(value, 'matlab.io.config.ConfigurationData')
                    value = dotReference(value, indexOp(2:end));
                else
                    error('ConfigurationData:InvalidChain', ...
                        'Cannot chain into non-ConfigurationData value');
                end
            end
        end

        varargout{1} = value;
        return;
    end

    % Key doesn't exist - error
    error('ConfigurationData:InvalidKey', ...
        'Key "%s" does not exist.', key);

elseif indexOp(1).Type == "Paren"
    % Direct array indexing on obj: should not happen
    error('ConfigurationData:UnsupportedIndexing', ...
        'Direct parenthesis indexing not supported');
else
    error('ConfigurationData:UnsupportedIndexing', ...
        'Unsupported indexing type: %s', indexOp(1).Type);
end
end

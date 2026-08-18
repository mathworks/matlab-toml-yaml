function obj = dotAssign(obj, indexOp, varargin)
key = indexOp(1).Name;

% Handle non-scalar array assignment
if ~isscalar(obj)
    value = varargin{end};
    numElements = numel(obj);

    % Case 1: arr.field = value (assign to ALL elements)
    if numel(indexOp) == 1
        if isscalar(value) || (numel(value) == 1)
            % Broadcast scalar to all elements
            for i = 1:numElements
                obj(i) = dotAssign(obj(i), indexOp, value);
            end
        elseif numel(value) == numElements
            % Element-wise assignment
            for i = 1:numElements
                obj(i) = dotAssign(obj(i), indexOp, value(i));
            end
        else
            error('ConfigurationData:SizeMismatch', ...
                ['Value size (%d) does not match array size (%d).'], ...
                numel(value), numElements);
        end
        return;
    end

    % Case 2: arr.field(idx) = value (assign to indexed elements)
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        indices = indexOp(2).Indices;
        if numel(indices) == 1
            idx = indices{1};

            % Convert any index type to linear indices
            if islogical(idx)
                selectedIndices = find(idx);
            elseif isnumeric(idx)
                selectedIndices = idx(:)';  % Ensure row vector
            elseif ischar(idx) && idx == ':'
                selectedIndices = 1:numel(obj);
            else
                selectedIndices = idx;  % Let MATLAB handle other types
            end
            numSelected = numel(selectedIndices);

            % Get field name for Case 2
            fieldName = indexOp(1).Name;
            hasMoreChain = numel(indexOp) > 2;
            remainingChain = indexOp(3:end);

            % Determine if value should be broadcast or indexed
            if isscalar(value) || (numel(value) == 1)
                % Scalar value - broadcast to all filtered elements
                for i = 1:numSelected
                    objIdx = selectedIndices(i);
                    elem = obj(objIdx);
                    if hasMoreChain
                        % More chaining: arr.field(idx).subfield = value
                        % Get nested, apply chain, write back
                        nested = elem.getData(fieldName);
                        nested = dotAssign(nested, remainingChain, value);
                        elem = elem.setData(fieldName, nested);
                    else
                        % Direct: arr.field(idx) = value
                        elem = elem.setData(fieldName, value);
                    end
                    obj(objIdx) = elem;
                end
            elseif numel(value) == numSelected
                % Array value matching filtered size - assign element-wise
                for i = 1:numSelected
                    objIdx = selectedIndices(i);
                    elem = obj(objIdx);
                    elemValue = value(i);
                    if hasMoreChain
                        nested = elem.getData(fieldName);
                        nested = dotAssign(nested, remainingChain, elemValue);
                        elem = elem.setData(fieldName, nested);
                    else
                        elem = elem.setData(fieldName, elemValue);
                    end
                    obj(objIdx) = elem;
                end
            else
                error('ConfigurationData:SizeMismatch', ...
                    ['Value size (%d) does not match number of ' ...
                    'selected elements (%d).'], numel(value), numSelected);
            end
            return;
        end
    end
end

% Handle chained assignment: obj.a.b.c = value or obj.a(idx).b = value
if length(indexOp) > 1
    % Check if next operation is Paren (array indexing)
    if indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        % Pattern: obj.field(idx)... = value
        % Get the array
        if ~isKey(obj.Data, key)
            error('ConfigurationData:InvalidIndex', ...
                'Cannot index into non-existent field ''%s''', key);
        end
        arr = obj.getData(key);

        % Extract index
        idx = indexOp(2).Indices{:};

        % Get the element
        elem = arr(idx);

        % Apply remaining chain to element
        if length(indexOp) > 2
            % More operations after the paren: obj.field(idx).subfield = value
            elem = dotAssign(elem, indexOp(3:end), varargin{:});
        else
            % Direct element replacement: obj.field(idx) = value
            elem = varargin{end};
        end

        % Write element back to array
        arr(idx) = elem;

        % Store array back
        obj = obj.setData(key, arr);
    else
        % Pattern: obj.field.subfield = value (next op is Dot)
        % Get or create the nested object
        if isKey(obj.Data, key)
            nested = obj.getData(key);
            if ~isa(nested, 'matlab.io.config.ConfigurationData')
                % Scalar value exists - replace with same class as parent
                nested = feval(class(obj));
                nested = copySourceFormat(obj, nested);
            end
        else
            % Create new nested object of same class as parent
            nested = feval(class(obj));
            nested = copySourceFormat(obj, nested);
        end

        % Recursively assign to nested object
        nested = dotAssign(nested, indexOp(2:end), varargin{:});

        % Store the nested ConfigurationData directly (preserve order)
        obj = obj.setData(key, nested);
    end

else
    % Simple assignment: obj.key = value
    value = varargin{end};
    obj = obj.setData(key, value);
end
end

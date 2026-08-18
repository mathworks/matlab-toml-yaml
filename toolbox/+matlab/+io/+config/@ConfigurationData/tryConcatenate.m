function result = tryConcatenate(~, values, fieldName)
%TRYCONCATENATE Attempt to concatenate cell array of values into typed array
%   Returns typed array if all values have same type, otherwise errors.
%   This implements the "strict homogeneous" policy: no surprise cells.
%
%   Handles missing values: if an element lacks the key, missing is inserted.
%   MATLAB's concatenation coerces missing to NaN for double/single, keeps it
%   for string, but errors for integer/logical types.
%
%   The shape of the result matches the shape of the values cell array.
%   If values is Nx1, result is Nx1. If values is 1xN, result is 1xN.

if isempty(values)
    % Return empty double array (MATLAB-idiomatic "nothing")
    % This occurs when pre-filtering selects no elements
    result = [];
    return;
end

% Remember input shape to preserve it
inputShape = size(values);

% Get types of all values
types = cellfun(@class, values, 'UniformOutput', false);

% Check for missing values
isMissingValue = strcmp(types, 'missing');

if all(isMissingValue)
    % All values are missing - return missing array with correct shape
    result = repmat(missing, inputShape);
    return;
end

% Filter out missing when checking type homogeneity
nonMissingTypes = types(~isMissingValue);
uniqueTypes = unique(nonMissingTypes);

if numel(uniqueTypes) > 1
    % Find first mismatch to report helpful error (ignoring missing)
    firstType = nonMissingTypes{1};
    firstIdx = find(~isMissingValue, 1, 'first');
    for i = 1:numel(types)
        if ~isMissingValue(i) && ~strcmp(types{i}, firstType)
            error('ConfigurationData:TypeMismatch', ...
                ['Cannot concatenate values for key "%s": types differ.\n' ...
                'Element %d is %s, element %d is %s.\n' ...
                'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for heterogeneous values.'], ...
                fieldName, firstIdx, firstType, i, types{i}, fieldName);
        end
    end
end

% All non-missing values have same type
theType = uniqueTypes{1};

% Check for integer or logical types with missing values
if any(isMissingValue) && ...
        (startsWith(theType, 'int') || startsWith(theType, 'uint') || strcmp(theType, 'logical'))
    error('ConfigurationData:MissingNotSupported', ...
        ['Cannot concatenate values for key "%s": field has missing values.\n' ...
        'Type %s cannot represent missing in MATLAB.\n' ...
        'Use iskey(arr, ''%s'') to filter elements before accessing, or\n' ...
        'use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
        fieldName, theType, fieldName, fieldName);
end

% Handle different types appropriately
if strcmp(theType, 'char')
    % char arrays -> convert to string array, preserve shape
    result = reshape(string(values), inputShape);
elseif contains(theType, 'ConfigurationData') || ...
        startsWith(theType, 'matlab.io.config.')
    % ConfigurationData objects -> concatenate into array
    try
        result = reshape([values{:}], inputShape);
    catch
        % Different sizes or incompatible - error
        error('ConfigurationData:ConcatenationFailed', ...
            ['Cannot concatenate ConfigurationData values for key "%s".\n' ...
            'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
            fieldName, fieldName);
    end
elseif isnumeric(values{1}) || islogical(values{1}) || isstring(values{1})
    % Numeric, logical, string - try direct concatenation
    try
        % Check if all values are scalars
        allScalars = all(cellfun(@isscalar, values));
        if allScalars
            result = reshape([values{:}], inputShape);
        else
            % Non-scalar values - need to verify compatibility
            % Check all have same size
            sizes = cellfun(@size, values, 'UniformOutput', false);
            if all(cellfun(@(s) isequal(s, sizes{1}), sizes))
                % Same size - concatenate based on input shape
                % For 1xN inputs (row vectors), use horizontal cat (cat(2, ...))
                % For Nx1 inputs (column vectors), use vertical cat (cat(1, ...))
                % This enables natural concatenation: 1xN arrays with column values -> MxN result
                if inputShape(1) == 1 && inputShape(2) > 1
                    % Row input -> horizontal concatenation
                    result = cat(2, values{:});
                else
                    % Column or other shape -> vertical concatenation
                    result = cat(1, values{:});
                end
            else
                error('ConfigurationData:SizeMismatch', ...
                    ['Cannot concatenate values for key "%s": sizes differ.\n' ...
                    'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
                    fieldName, fieldName);
            end
        end
    catch ME
        if contains(ME.identifier, 'ConfigurationData:')
            rethrow(ME);
        end
        error('ConfigurationData:ConcatenationFailed', ...
            ['Cannot concatenate values for key "%s".\n' ...
            'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
            fieldName, fieldName);
    end
else
    % Other types - try generic concatenation
    try
        result = reshape([values{:}], inputShape);
    catch
        error('ConfigurationData:ConcatenationFailed', ...
            ['Cannot concatenate values for key "%s" of type %s.\n' ...
            'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
            fieldName, theType, fieldName);
    end
end
end

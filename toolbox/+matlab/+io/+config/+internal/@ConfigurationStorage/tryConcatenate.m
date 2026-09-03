function result = tryConcatenate(~, values, fieldName)
    %TRYCONCATENATE Concatenate per-element values into a typed array
    %   Returns typed array if all values have same type, otherwise errors.
    %   Missing values coerce to NaN (double/single) or <missing> (string).

    if isempty(values)
        result = [];
        return;
    end

    inputShape = size(values);

    % Identify missing values
    isMissing = cellfun(@(v) isa(v, 'missing'), values);

    if all(isMissing)
        result = repmat(missing, inputShape);
        return;
    end

    % Check type homogeneity (ignoring missing)
    nonMissingIdx = reshape(find(~isMissing), 1, []);
    firstValue = values{nonMissingIdx(1)};
    theType = class(firstValue);

    for i = nonMissingIdx(2:end)
        if ~strcmp(class(values{i}), theType)
            error('ConfigurationData:TypeMismatch', ...
                ['Cannot concatenate values for key "%s": types differ.\n' ...
                'Element %d is %s, element %d is %s.\n' ...
                'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for heterogeneous values.'], ...
                fieldName, nonMissingIdx(1), theType, i, class(values{i}), fieldName);
        end
    end

    % Integer/logical cannot represent missing
    if any(isMissing) && (isinteger(firstValue) || islogical(firstValue))
        error('ConfigurationData:MissingNotSupported', ...
            ['Cannot concatenate values for key "%s": field has missing values.\n' ...
            'Type %s cannot represent missing in MATLAB.\n' ...
            'Use iskey(arr, ''%s'') to filter elements before accessing, or\n' ...
            'use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
            fieldName, theType, fieldName, fieldName);
    end

    % ConfigurationData or scalar values → reshape([values{:}])
    if isa(firstValue, 'matlab.io.config.ConfigurationData') ...
            || all(cellfun(@isscalar, values))
        result = reshape([values{:}], inputShape);
        return;
    end

    % Non-scalar values: verify size compatibility then directional cat
    sizes = cellfun(@size, values, 'UniformOutput', false);
    if ~all(cellfun(@(s) isequal(s, sizes{1}), sizes))
        error('ConfigurationData:SizeMismatch', ...
            ['Cannot concatenate values for key "%s": sizes differ.\n' ...
            'Use arrayfun(@(x) x.%s, arr, ''UniformOutput'', false) for cell output.'], ...
            fieldName, fieldName);
    end

    if inputShape(1) == 1 && inputShape(2) > 1
        result = cat(2, values{:});
    else
        result = cat(1, values{:});
    end
end

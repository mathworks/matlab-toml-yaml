function value = validateValue(obj, value, key)
    %VALIDATEVALUE Validate and optionally convert a value for storage
    %   value = matlab.io.config.internal.validateValue(obj, value, key)
    %   Returns the (possibly converted) value, or throws an error.
    %   obj is used for class-preserving conversion (importFrom) and
    %   format-specific behavior (SourceFormat).

    import matlab.io.config.internal.supportedTypes
    import matlab.io.config.internal.validateValue

    types = supportedTypes();

    % --- Containers: recurse into elements ---

    if iscell(value)
        for i = 1:numel(value)
            value{i} = validateValue(obj, value{i}, key);
        end
        return;
    end

    % --- Converted types: accepted as input, auto-converted to storage type ---

    if isstruct(value)
        value = importFrom(obj, value);
        return;
    end

    if ischar(value)
        value = string(value);
        return;
    end

    if isa(value, 'duration')
        value = seconds(value);
        return;
    end

    if isa(value, 'dictionary')
        value = importFrom(obj, value);
        return;
    end

    % --- Rejected types: custom error messages ---

    if isnumeric(value) && ~isreal(value)
        error('ConfigurationData:InvalidType', ...
            ['Cannot assign complex numbers to key "%s".\n' ...
            'Configuration files do not support imaginary numbers.'], key);
    end

    if isa(value, 'function_handle')
        error('ConfigurationData:InvalidType', ...
            ['Cannot assign function_handle to key "%s".\n' ...
            'Function handles cannot be serialized to configuration files.'], key);
    end

    if isa(value, 'table') || isa(value, 'timetable')
        error('ConfigurationData:InvalidType', ...
            ['Cannot assign %s to key "%s".\n' ...
            'Convert to struct first: struct(yourTable)'], class(value), key);
    end

    if isa(value, 'categorical')
        error('ConfigurationData:InvalidType', ...
            ['Cannot assign categorical to key "%s".\n' ...
            'Convert to string first: string(yourCategorical)'], key);
    end

    % --- Storage types: must pass mustBeA ---

    try
        mustBeA(value, types.storage);
    catch
        allTypes = [types.storage, types.input];
        error('ConfigurationData:InvalidType', ...
            'Cannot assign %s to key "%s".\nSupported types: %s.', ...
            class(value), key, join(allTypes, ", "));
    end
end

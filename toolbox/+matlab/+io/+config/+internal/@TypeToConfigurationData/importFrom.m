function obj = importFrom(obj, inputData)
    %IMPORTFROM Import data from struct, dictionary, or containers.Map
    %   Converts a struct, dictionary, or containers.Map into a
    %   ConfigurationData object, preserving the subclass type.
    %
    %   For struct arrays, returns an array of ConfigurationData objects
    %   with the same shape as the input struct array.

    if isstruct(inputData)
        if ~isscalar(inputData)
            arr(numel(inputData)) = matlab.io.config.internal.createArray(obj);
            for i = 1:numel(inputData)
                arr(i) = importFrom(matlab.io.config.internal.createArray(obj), inputData(i));
            end
            obj = reshape(arr, size(inputData));
            return;
        end

        fields = fieldnames(inputData);
        for i = 1:numel(fields)
            key = fields{i};
            obj.(key) = inputData.(key);
        end
    elseif isa(inputData, 'dictionary')
        keyList = keys(inputData);
        for i = 1:numel(keyList)
            key = keyList(i);
            val = inputData(key);
            if iscell(val)
                val = val{1};
            end
            obj.(key) = val;
        end
    elseif isa(inputData, 'containers.Map')
        keyList = keys(inputData);
        for i = 1:numel(keyList)
            key = string(keyList{i});
            obj.(key) = inputData(keyList{i});
        end
    else
        error('ConfigurationData:InvalidInput', ...
            'Input must be struct, dictionary, or containers.Map. Got %s.', class(inputData));
    end
end

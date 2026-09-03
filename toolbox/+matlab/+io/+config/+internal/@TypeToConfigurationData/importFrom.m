function obj = importFrom(obj, inputData)
%IMPORTFROM Import data from struct or dictionary
%   Converts a struct or dictionary into a ConfigurationData object,
%   preserving the subclass type (YAMLData stays YAMLData, etc.).
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
else
    error('ConfigurationData:InvalidInput', ...
        'Input must be struct or dictionary. Got %s.', class(inputData));
end
end

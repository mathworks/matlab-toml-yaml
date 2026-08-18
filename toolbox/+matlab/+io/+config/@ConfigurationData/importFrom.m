function obj = importFrom(obj, inputData)
%IMPORTFROM Import data from struct or dictionary
%   This method handles conversion from external data types.
%   It preserves the class type for nested objects.
%
%   For struct arrays, returns an array of ConfigurationData objects
%   with the same shape as the input struct array.
%
%   Example:
%       obj = tomldata();
%       obj = importFrom(obj, myStruct);
%
%       % Struct array creates ConfigurationData array
%       s = struct(A={1 2 3});  % 1x3 struct array
%       arr = importFrom(yamldata(), s);  % 1x3 YAMLData array

if isstruct(inputData)
    if ~isscalar(inputData)
        % Struct array -> array of ConfigurationData
        % Create array with same size as input
        arr(numel(inputData)) = feval(class(obj));
        for i = 1:numel(inputData)
            arr(i) = importFrom(feval(class(obj)), inputData(i));
        end
        obj = reshape(arr, size(inputData));
        return;
    end

    % Scalar struct handling
    fields = fieldnames(inputData);
    for i = 1:numel(fields)
        key = fields{i};
        value = inputData.(key);
        value = obj.convertImportValue(value);
        obj.(key) = value;
    end
elseif isa(inputData, 'dictionary')
    keyList = keys(inputData);
    for i = 1:numel(keyList)
        key = keyList(i);
        val = inputData(key);
        value = val{1};  % Unwrap from cell
        value = obj.convertImportValue(value);
        obj.(key) = value;
    end
else
    error('ConfigurationData:InvalidInput', ...
        'Input must be struct or dictionary. Got %s.', class(inputData));
end
end

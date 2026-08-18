function displayNonScalarObject(obj)
% Display for object arrays
dims = size(obj);
dimStr = sprintf('%dx', dims);
dimStr = dimStr(1:end-1); % Remove trailing 'x'

% Collect all keys from array elements
allKeys = string.empty(0,1); % String array to hold all unique keys
keySets = cell(numel(obj), 1);

for i = 1:numel(obj)
    keySets{i} = keys(obj(i)); % Use keys() method
    % Ensure column vector for concatenation
    allKeys = [allKeys; reshape(keySets{i}, [], 1)];
end

% Get unique keys while preserving order from first occurrence
[uniqueKeys, ~] = unique(allKeys, 'stable');

% Check if all elements have identical keys
isHomogeneous = true;
if numel(obj) > 1
    firstKeySet = keySets{1};
    for i = 2:numel(obj)
        if ~isequal(sort(firstKeySet), sort(keySets{i}))
            isHomogeneous = false;
            break;
        end
    end
end

% Display header
shortName = shortClassName(class(obj));
fprintf('  %s <a href="matlab:helpPopup %s">%s</a> array with keys:\n\n', ...
    dimStr, class(obj), shortName);

% Display keys
for i = 1:length(uniqueKeys)
    fprintf('    %s\n', uniqueKeys(i));
end

% Add heterogeneous note if needed
if ~isHomogeneous && numel(obj) > 1
    fprintf('\n    (keys vary by element)\n');
end

% Add show link for arrays (they always have potential hierarchy)
fprintf('\n    <a href="matlab:show(%s)">Show all values</a>\n\n', inputname(1));
end

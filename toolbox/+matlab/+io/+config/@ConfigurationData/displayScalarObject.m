function displayScalarObject(obj)
header = getHeader(obj);
disp(header);

originalKeys = keys(obj.Data);
if isempty(originalKeys)
    return;
end

% Check if there's nested hierarchy
hasHierarchy = false;
for i = 1:length(originalKeys)
    value = obj.getData(originalKeys(i));
    if isa(value, 'matlab.io.config.ConfigurationData') || isa(value, 'dictionary')
        hasHierarchy = true;
        break;
    end
end

% Display each field
for i = 1:length(originalKeys)
    key = originalKeys(i);
    value = obj.getData(key);

    % Format the value for display
    valueStr = obj.formatValue(value);

    fprintf('    %s: %s\n', key, valueStr);
end

% Add footer with show link if there's hierarchy
if hasHierarchy
    fprintf('\n    <a href="matlab:show(%s)">Show all values</a>\n', inputname(1));
end

fprintf('\n');
end

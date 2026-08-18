function displayScalarObject(obj)
header = getHeader(obj);
disp(header);

if length(obj.xInternal__.OriginalKeys) == 0
    return;
end

% Check if there's nested hierarchy
hasHierarchy = false;
for i = 1:length(obj.xInternal__.OriginalKeys)
    value = obj.getData(obj.xInternal__.OriginalKeys(i));
    if isa(value, 'matlab.io.config.ConfigurationData') || isa(value, 'dictionary')
        hasHierarchy = true;
        break;
    end
end

% Display each field
for i = 1:length(obj.xInternal__.OriginalKeys)
    key = obj.xInternal__.OriginalKeys(i);
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

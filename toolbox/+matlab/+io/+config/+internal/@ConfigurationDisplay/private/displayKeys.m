function displayKeys(obj, originalKeys)
%DISPLAYKEYS Build PropertyGroup, render via displayPropertyGroups, fix key names

if isscalar(obj)
    % Struct form: provide keys with values
    s = struct();
    for i = 1:numel(originalKeys)
        fieldName = char(matlab.lang.makeValidName(originalKeys(i)));
        s.(fieldName) = getData(obj, originalKeys(i));
    end
    groups = matlab.mixin.util.PropertyGroup(s);
else
    % Name-only form: just list key names
    groups = matlab.mixin.util.PropertyGroup(cellstr(originalKeys));
end

% Capture output, restore original key names where aliased
output = evalc('matlab.mixin.CustomDisplay.displayPropertyGroups(obj, groups)');
for i = 1:numel(originalKeys)
    validName = char(matlab.lang.makeValidName(originalKeys(i)));
    if ~strcmp(validName, char(originalKeys(i)))
        output = strrep(output, validName, char(originalKeys(i)));
    end
end
fprintf('%s', output);
end

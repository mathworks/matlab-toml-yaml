function displayScalarObject(obj)
fprintf('%s', getHeader(obj));

k = keys(obj);
if isempty(k)
    return;
end

displayKeys(obj, k);

% Show link if there's nested hierarchy
hasHierarchy = false;
for i = 1:numel(k)
    if isa(matlab.io.config.internal.lookupCellDictionaryKey(obj.Data, k(i)), 'matlab.io.config.ConfigurationData')
        hasHierarchy = true;
        break;
    end
end
if hasHierarchy
    showAllValuesLink(inputname(1));
else
    fprintf('\n');
end
end

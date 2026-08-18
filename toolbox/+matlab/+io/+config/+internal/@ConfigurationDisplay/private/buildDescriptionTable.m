function text = buildDescriptionTable(obj, maxDepth)
%BUILDDESCRIPTIONTABLE Build flat table for programmatic use
paths = string.empty(0,1);
types = string.empty(0,1);
sizes = string.empty(0,1);

if ~isscalar(obj)
    % Non-scalar array at root
    [paths, types, sizes] = collectArrayRows(obj, "", paths, types, sizes, 1, maxDepth);
else
    [paths, types, sizes] = collectRows(obj, "", paths, types, sizes, 1, maxDepth);
end

text = table(paths, types, sizes, 'VariableNames', ["Path", "Type", "Size"]);
end

function result = combineRows(keys, values)
%COMBINEROWS Prefix paths with key names and concatenate all rows
result = emptyDescribeTable();

for i = 1:numel(keys)
    row = values{i};
    row.Path(1) = keys(i);
    for j = 2:height(row)
        row.Path(j) = keys(i) + "." + row.Path(j);
    end
    result = [result; row]; %#ok<AGROW>
end
end

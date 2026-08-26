function t = emptyDescribeTable()
%EMPTYDESCRIBETABLE Create an empty table with Path, Type, Size columns
t = table(string.empty(0,1), string.empty(0,1), string.empty(0,1), ...
    'VariableNames', ["Path", "Type", "Size"]);
end

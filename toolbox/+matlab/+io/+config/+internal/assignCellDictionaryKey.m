function d = assignCellDictionaryKey(d, key, value)
    %ASSIGNCELLDICTIONARYKEY Assign a value into a string-to-cell dictionary.
    %   R2022b dictionaries lack brace indexing; this provides a compatible wrap-and-assign.
    d(key) = {value};
end

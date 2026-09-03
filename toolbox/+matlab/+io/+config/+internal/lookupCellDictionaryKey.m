function value = lookupCellDictionaryKey(d, key)
    %LOOKUPCELDICTIONARYKEY Retrieve unwrapped value from a string-to-cell dictionary.
    %   R2022b dictionaries lack brace indexing; this provides a compatible unwrap.
    c = d(key);
    value = c{1};
end

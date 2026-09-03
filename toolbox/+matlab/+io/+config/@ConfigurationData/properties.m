function p = properties(obj)
    %PROPERTIES Return list of dynamic properties (keys)
    %   Returns cell array of char for MATLAB IDE tab completion.
    p = cellstr(keys(obj.Data));
end

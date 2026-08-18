function p = properties(obj)
%PROPERTIES Return list of dynamic properties (keys)
%   Returns cell array of char for MATLAB IDE tab completion.
p = cellstr(obj.xInternal__.OriginalKeys);
end

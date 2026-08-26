function new = createArray(obj)
%CREATEARRAY Construct empty object of the same class (R2022b-compatible shim)
%   Forwards to builtin createArray when available (R2026b+), otherwise
%   falls back to feval.
    className = class(obj);
    if exist('createArray', 'builtin')
        new = builtin('createArray', className);
    else
        new = feval(className);
    end
end

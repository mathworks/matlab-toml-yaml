function tf = isfield(obj, key)
    %ISFIELD Check if key exists (delegates to iskey)
    tf = iskey(obj, key);
end

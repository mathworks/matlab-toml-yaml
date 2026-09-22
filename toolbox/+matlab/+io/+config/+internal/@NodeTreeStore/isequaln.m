function tf = isequaln(a, b)
    tf = false;
    if ~isa(b, "matlab.io.config.internal.NodeTreeStore")
        return
    end
    ka = allKeys(a);
    kb = allKeys(b);
    if ~isequal(ka, kb)
        return
    end
    for i = 1:numel(ka)
        if ~isequaln(getValue(a, ka(i)), getValue(b, ka(i)))
            return
        end
    end
    tf = true;
end

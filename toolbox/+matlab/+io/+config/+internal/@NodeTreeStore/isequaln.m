function tf = isequaln(a, b)
    tf = false;
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

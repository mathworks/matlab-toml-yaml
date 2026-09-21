function tf = isequaln(a, b, varargin)
    tf = false;
    if ~strcmp(class(a), class(b))
        return
    end
    if ~isequal(size(a), size(b))
        return
    end
    if isscalar(a)
        if ~isequaln(a.Data, b.Data)
            return
        end
    else
        for i = 1:numel(a)
            if ~isequaln(a(i), b(i))
                return
            end
        end
    end
    tf = true;
    if ~isempty(varargin)
        tf = tf && isequaln(b, varargin{:});
    end
end

function obj = parenDotAssign(obj, indexOp, varargin)
% Handle patterns:
%   1. obj(idx).field = value  (array element assignment)
%   2. obj.methodName = value  (method name conflicts)
%
% For pattern 1, indexOp(1) is Paren, indexOp(2) is Dot
% For pattern 2, indexOp(1) is Dot (method name)

value = varargin{end};

if indexOp(1).Type == matlab.indexing.IndexingOperationType.Paren
    % Pattern: obj(idx).field = value (or obj(idx).field.subfield = ...)
    idx = indexOp(1).Indices{:};

    % Get the indexed element
    elem = obj(idx);

    % Apply the remaining dot operations
    if length(indexOp) > 1
        elem = dotAssign(elem, indexOp(2:end), varargin{:});
    else
        % Shouldn't happen for parenDot, but handle it
        elem = value;
    end

    % Write element back
    obj(idx) = elem;
else
    % Pattern: obj.methodName = value (method name conflict)
    key = indexOp(1).Name;

    % Block assignment to reserved internal property name
    if key == "xInternal__"
        error('ConfigurationData:ReservedKey', ...
            'Key "xInternal__" is reserved for internal use.');
    end

    % Store directly using setData to bypass method resolution
    obj = obj.setData(key, value);

    % Track order
    if ~any(obj.xInternal__.OriginalKeys == key)
        obj.xInternal__.OriginalKeys(end+1) = key;
    end

    % Create alias if needed
    validKey = matlab.lang.makeValidName(key);
    if ~strcmp(validKey, key)
        obj.xInternal__.KeyAliases(validKey) = key;
    end
end
end

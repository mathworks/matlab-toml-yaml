function varargout = dotReference(obj, indexOp, ~)
    % With OverridesPublicDotMethodCall, ALL dot notation from outside
    % the class comes here first. Data keys take priority over methods.

    % Non-scalar: arr.field(idx)... — paren selects array elements
    if ~isscalar(obj) && numel(indexOp) > 1 ...
            && indexOp(2).Type == matlab.indexing.IndexingOperationType.Paren
        [varargout{1:nargout}] = dotReference(obj(indexOp(2).Indices{:}), indexOp([1 3:end]));
        return;
    end

    % Resolve the first dot to a value
    fieldName = indexOp(1).Name;
    resolvedKeys = resolveKey(obj, fieldName);
    found = ~ismissing(resolvedKeys);
    if ~any(found)
        error('ConfigurationData:InvalidKey', 'Key "%s" does not exist.', fieldName);
    end

    if isscalar(obj)
        value = matlab.io.config.internal.lookupCellDictionaryKey(obj.Data, resolvedKeys);
    else
        values = cell(size(obj));
        for i = 1:numel(obj)
            if found(i)
                values{i} = matlab.io.config.internal.lookupCellDictionaryKey(obj(i).Data, resolvedKeys(i));
            else
                values{i} = missing;
            end
        end
        value = tryConcatenate(obj, values, fieldName);
    end

    % Forward remaining indexing to the resolved value
    if numel(indexOp) > 1
        [varargout{1:nargout}] = value.(indexOp(2:end));
    else
        varargout{1} = value;
    end
end

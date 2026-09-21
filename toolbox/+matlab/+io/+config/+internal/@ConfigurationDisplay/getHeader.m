function header = getHeader(obj)
    %GETHEADER Customize header to use "keys" instead of "properties"
    className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
    if isscalar(obj)
        nKeys = numKeys(obj.Data);
        if nKeys == 0
            header = sprintf('  %s with no keys\n', className);
        else
            header = sprintf('  %s with keys:\n', className);
        end
    else
        dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj);
        header = sprintf('  %s %s array with keys:\n', dimStr, className);
    end
end

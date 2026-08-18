function header = getHeader(obj)
%GETHEADER Customize header to use "keys" instead of "properties"
if isscalar(obj)
    className = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
    nKeys = numEntries(obj.Data);
    if nKeys == 0
        header = sprintf('  %s with no keys\n', className);
    else
        header = sprintf('  %s with keys:\n', className);
    end
else
    % Non-scalar handled by displayNonScalarObject
    header = getHeader@matlab.mixin.CustomDisplay(obj);
end
end

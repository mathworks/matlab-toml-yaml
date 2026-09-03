function showAsFormat(obj, writeFcn, writerArgs)
%SHOWASFORMAT Display ConfigurationData by writing to temp file
%   Shared logic for YAMLData.show() and TOMLData.show().
arguments
    obj
    writeFcn function_handle
    writerArgs cell = {}
end

tempFile = tempname;
try
    if isscalar(obj)
        writeFcn(obj, tempFile, writerArgs{:});
    else
        wrapper = matlab.io.config.internal.createArray(obj);
        wrapper.item = obj;
        writeFcn(wrapper, tempFile, writerArgs{:});
    end
    content = fileread(tempFile);
    fprintf('%s\n', content);
catch
    disp(obj);
end
if isfile(tempFile)
    delete(tempFile);
end
end

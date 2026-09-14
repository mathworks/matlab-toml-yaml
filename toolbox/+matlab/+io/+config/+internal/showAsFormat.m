function showAsFormat(obj, writeFcn, varargin)
    %SHOWASFORMAT Display ConfigurationData by writing to temp file
    %   Shared logic for YAMLData.show() and TOMLData.show().
    arguments
        obj
        writeFcn function_handle
    end
    arguments (Repeating)
        varargin
    end

    tempFile = tempname;
    try
        if isscalar(obj)
            writeFcn(obj, tempFile, varargin{:});
        else
            wrapper = matlab.io.config.internal.createArray(obj);
            wrapper.item = obj;
            writeFcn(wrapper, tempFile, varargin{:});
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

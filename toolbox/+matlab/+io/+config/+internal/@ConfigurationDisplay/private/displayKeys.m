function displayKeys(obj, originalKeys)
    %DISPLAYKEYS Build PropertyGroup, render via displayPropertyGroups

    if isscalar(obj)
        s = struct();
        for i = 1:numel(originalKeys)
            fieldName = char(matlab.lang.makeValidName(originalKeys(i)));
            s.(fieldName) = getValue(obj.Data, originalKeys(i));
        end
        groups = matlab.mixin.util.PropertyGroup(s); %#ok<NASGU> used in evalc below
    else
        groups = matlab.mixin.util.PropertyGroup(cellstr(originalKeys)); %#ok<NASGU> used in evalc below
    end

    % PropertyGroup requires valid MATLAB names; restore original key names
    output = evalc('matlab.mixin.CustomDisplay.displayPropertyGroups(obj, groups)');
    for i = 1:numel(originalKeys)
        validName = char(matlab.lang.makeValidName(originalKeys(i)));
        origName = char(originalKeys(i));
        if ~strcmp(validName, origName)
            lenDiff = length(validName) - length(origName);
            if lenDiff > 0
                output = strrep(output, validName, [repmat(' ', 1, lenDiff) origName]);
            elseif lenDiff < 0
                output = strrep(output, [repmat(' ', 1, -lenDiff) validName], origName);
            else
                output = strrep(output, validName, origName);
            end
        end
    end
    fprintf('%s', output);
end

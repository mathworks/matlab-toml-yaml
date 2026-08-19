function displayNonScalarObject(obj)
import matlab.io.config.internal.collectUnionOfKeys

fprintf('%s', getHeader(obj));

displayKeys(obj, collectUnionOfKeys(obj));

% Check if keys vary by element
if numel(obj) > 1
    firstKeys = sort(keys(obj(1)));
    for i = 2:numel(obj)
        if ~isequal(firstKeys, sort(keys(obj(i))))
            fprintf('    (keys vary by element)\n');
            break;
        end
    end
end

showAllValuesLink(inputname(1));
end

function result = parseYAMLSequence(values, datetimeType)
    parsed = cell(numel(values), 1);
    for j = 1:numel(values)
        parsed{j} = matlab.io.config.internal.read.parseYAMLScalar( ...
            values(j), false, datetimeType);
    end
    firstClass = class(parsed{1});
    if all(cellfun(@(x) isa(x, firstClass), parsed))
        result = vertcat(parsed{:});
    else
        result = parsed;
    end
end

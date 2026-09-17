function [texts, quoted] = formatYAMLSequence(arr, precision)
    %formatYAMLSequence Batch-format all elements of a typed array.
    %   Called by writeyamlMex to avoid per-element feval overhead.

    arguments
        arr
        precision (1,1) double
    end

    n = numel(arr);
    texts = strings(n, 1);
    quoted = false(n, 1);
    for i = 1:n
        [texts(i), quoted(i)] = ...
            matlab.io.config.internal.write.formatYAMLScalar(arr(i), precision);
    end
end

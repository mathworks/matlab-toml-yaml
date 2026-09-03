function [keyNames, texts, quoted, kinds, values] = formatYAMLMap(obj, precision)
    %formatYAMLMap Batch-format all values in a ConfigurationData map.
    %   Called by writeyamlMex to avoid per-scalar feval overhead.

    arguments
        obj
        precision (1,1) double = 6
    end

    k = keys(obj);
    n = numel(k);
    texts = strings(n, 1);
    quoted = false(n, 1);
    kinds = strings(n, 1);
    values = cell(n, 1);

    for i = 1:n
        val = obj.(k(i));
        values{i} = val;

        if isa(val, 'matlab.io.config.ConfigurationData')
            if isempty(val)
                kinds(i) = "null";
                texts(i) = "null";
            elseif isscalar(val)
                kinds(i) = "map";
            else
                kinds(i) = "object_seq";
            end
        elseif isa(val, 'missing') || isempty(val)
            kinds(i) = "null";
            texts(i) = "null";
        elseif iscell(val)
            kinds(i) = "cell_seq";
        elseif numel(val) > 1
            kinds(i) = "typed_seq";
        else
            kinds(i) = "scalar";
            [texts(i), quoted(i)] = ...
                matlab.io.config.internal.write.formatYAMLScalar(val, precision);
        end
    end

    keyNames = k;
end

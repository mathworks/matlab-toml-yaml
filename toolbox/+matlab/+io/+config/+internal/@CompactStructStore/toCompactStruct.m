function cs = toCompactStruct(store, format, precision)
    if ~any(store.Expanded) && store.Format == format
        cs = expandDatetimes(store.Struct);
        return
    end
    obj = matlab.io.config.ConfigurationData.fromStore(store, format);
    cs = matlab.io.config.internal.write.compact(obj, format, precision);
end

function cs = expandDatetimes(cs)
    for idx = cs.DatetimeIndices
        cs.Values{idx} = matlab.io.config.internal.read.parseTOMLDatetime(cs.Values{idx});
    end
    for i = 1:numel(cs.Values)
        v = cs.Values{i};
        if isstruct(v) && isfield(v, 'Keys')
            cs.Values{i} = expandDatetimes(v);
        elseif iscell(v)
            for j = 1:numel(v)
                if isstruct(v{j}) && isfield(v{j}, 'Keys')
                    v{j} = expandDatetimes(v{j});
                end
            end
            cs.Values{i} = v;
        end
    end
end

function result = select(obj, selectedKeys)
%SELECT Return a new object containing only the specified keys
%   result = SELECT(obj, keys) returns a new object of the same class as
%   obj containing only the keys listed in selectedKeys.
%   Key order in the result matches the order in selectedKeys.
%
%   This is a non-destructive operation — obj is not modified.
%   For the inverse (removing keys), use rmfield.
%
%   selectedKeys can be a string array, cell array of char, or a single key.
%
%   Example:
%       config = readyaml("server.yaml");
%       % config has keys: host, port, timeout, debug, logging, tls
%
%       % Keep only network settings:
%       network = select(config, ["host", "port", "tls"]);
%       keys(network)   % ["host", "port", "tls"]
%
%       % Extract just one key (returns single-key object, not the value):
%       hostOnly = select(config, "host");
%
%   See also: rmfield, merge, keys

    arguments
        obj (1,1) matlab.io.config.ConfigurationData
        selectedKeys
    end

    selectedKeys = string(selectedKeys);
    selectedKeys = selectedKeys(:)';  % ensure row vector for iteration

    % Validate all requested keys exist
    for i = 1:numel(selectedKeys)
        if ~iskey(obj, selectedKeys(i))
            error('ConfigurationData:InvalidKey', ...
                'Key "%s" does not exist in the object.', selectedKeys(i));
        end
    end

    % Build result with same class as input
    result = matlab.io.config.internal.createArray(obj);

    for i = 1:numel(selectedKeys)
        k = selectedKeys(i);
        canonicalKey = resolveKey(obj, k);
        result.(canonicalKey) = obj.(k);
    end
end

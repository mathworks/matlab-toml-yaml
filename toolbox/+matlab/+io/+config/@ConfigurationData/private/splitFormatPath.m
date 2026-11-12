function [head, rest] = splitFormatPath(store, keyPath)
    %splitFormatPath Split a key path into the first key and the remainder.
    %   An exact key match wins, so keys that contain "." can be addressed
    %   directly. Otherwise the path is split at the first ".".
    if hasKey(store, keyPath)
        head = keyPath;
        rest = "";
        return
    end
    if contains(keyPath, ".")
        head = extractBefore(keyPath, ".");
        rest = extractAfter(keyPath, ".");
        if hasKey(store, head)
            return
        end
    end
    error("setformat:InvalidKey", "Key '%s' not found.", keyPath);
end

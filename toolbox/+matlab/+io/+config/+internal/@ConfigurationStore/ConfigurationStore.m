classdef (Abstract) ConfigurationStore
    %CONFIGURATIONSTORE Abstract storage interface for ConfigurationData.
    %   Defines primitives for key management, value access, and
    %   serialization. All mutating methods return the modified store
    %   (value semantics).

    methods (Abstract)
        k       = allKeys(store)
        n       = numKeys(store)
        tf      = hasKey(store, key)
        val     = getValue(store, key)
        store   = setValue(store, key, value)
        store   = removeKey(store, key)
        cs      = toCompactStruct(store, format, precision)
    end

    methods (Abstract, Static)
        store   = fromCompactStruct(cs)
    end
end

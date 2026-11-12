classdef (Abstract) ConfigurationStore
    %CONFIGURATIONSTORE Abstract storage interface for ConfigurationData.
    %   Defines primitives for key management, value access, and
    %   serialization. All mutating methods return the modified store
    %   (value semantics).

    methods (Abstract)
        k       = allKeys(store)  % (1×n string) row vector, insertion order
        n       = numKeys(store)
        tf      = hasKey(store, key)
        val     = getValue(store, key)
        store   = setValue(store, key, value)
        store   = removeKey(store, key)
        tree    = toNodeTree(store)

        % Format metadata (struct, or [] when none)
        meta    = getKeyMetadata(store, key)       % the key entry
        store   = setKeyMetadata(store, key, meta)
        meta    = getNodeMetadata(store, key)      % the value at key
        store   = setNodeMetadata(store, key, meta)
        meta    = getTableMetadata(store)          % this table
        store   = setTableMetadata(store, meta)
    end

    methods (Abstract, Static)
        store   = empty()
    end
end

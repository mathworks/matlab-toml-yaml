function tf = hasKey(store, key)
    tf = any(store.Struct.Keys == key);
end

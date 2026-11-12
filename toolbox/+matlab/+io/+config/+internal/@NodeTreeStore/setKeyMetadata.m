function store = setKeyMetadata(store, key, meta)
    %setKeyMetadata Set metadata of the key entry. Empty meta clears it.
    idx = find(store.Tree.Keys == key, 1);
    if ~isfield(store.Tree, "KeyMetadata")
        if isEmptyMetadata(meta)
            return
        end
        store.Tree.KeyMetadata = cell(size(store.Tree.Keys));
    end
    if isEmptyMetadata(meta)
        meta = [];
    end
    store.Tree.KeyMetadata{idx} = meta;
end

function tf = isEmptyMetadata(meta)
    tf = isempty(meta) || (isstruct(meta) && isempty(fieldnames(meta)));
end

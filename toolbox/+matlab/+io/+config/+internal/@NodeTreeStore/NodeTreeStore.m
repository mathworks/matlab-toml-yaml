classdef NodeTreeStore < matlab.io.config.internal.ConfigurationStore
    %NODETREESTORE ConfigurationStore backed by a node tree.
    %   Stores data as a tree of TableNode/ArrayNode/ValueNode structs
    %   where each node carries its own metadata inline. Eliminates the
    %   parallel metadata dictionary that causes data/metadata drift.
    %
    %   Node types (discriminated by struct field names):
    %     TableNode  — struct(Keys, Values, [TableMetadata], [KeyMetadata])
    %     ArrayNode  — struct(Elements, [Metadata])
    %     ValueNode  — struct(Data, [Type], [Metadata])
    %     Bare value — anything that is not one of the above structs
    %
    %   No Expanded flag is needed. User-set values (ConfigurationData,
    %   datetime, missing) are structurally distinct from node tree nodes
    %   because validateValue converts all user structs to
    %   ConfigurationData before they reach storage.

    properties (Access = private)
        Tree struct
        Format (1,1) string = "toml"
        DatetimeType (1,1) string = "datetime"
    end

    methods
        function store = NodeTreeStore()
            store.Tree = struct("Keys", string.empty(1, 0), "Values", {{}});
        end
    end

    methods (Hidden)
        tf = isequaln(a, b)
    end

    methods (Static)
        store = fromCompactStruct(cs, format, options)
        store = fromNodeTree(tree, format, options)
        store = empty()
    end
end

classdef CompactStructStore < matlab.io.config.internal.ConfigurationStore
    %COMPACTSTRUCTSTORE ConfigurationStore backed by a raw CompactStruct.
    %   Stores the CompactStruct produced by the MEX reader directly.
    %   Values are expanded lazily in getValue; user-set values bypass
    %   expansion via the Expanded flag array.

    properties (Access = private)
        Struct
        Format (1,1) string = "toml"
        DatetimeType (1,1) string = "datetime"
        Expanded (1,:) logical = logical.empty(1, 0)
    end

    methods
        function store = CompactStructStore()
            cs.Keys = string.empty(1, 0);
            cs.Values = {};
            cs.NullIndices = [];
            cs.DatetimeIndices = [];
            cs.QuotedIndices = [];
            store.Struct = cs;
        end
    end

    methods (Hidden)
        tf = isequaln(a, b)
    end

    methods (Static)
        store = fromCompactStruct(cs, format, options)
        store = empty()
    end
end

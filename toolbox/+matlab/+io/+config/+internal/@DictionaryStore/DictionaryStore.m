classdef DictionaryStore < matlab.io.config.internal.ConfigurationStore
    %DICTIONARYSTORE ConfigurationStore backed by dictionary<string, cell>.

    properties (Access = private)
        Dictionary = dictionary(string.empty, cell.empty)
    end

    methods
        function store = DictionaryStore(d)
            if nargin > 0
                store.Dictionary = d;
            end
        end
    end

    methods (Static)
        store   = fromCompactStruct(cs, format, options)
        store   = empty()
    end
end

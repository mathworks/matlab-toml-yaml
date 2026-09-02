classdef NodeMetadata
    %NODEMETADATA Per-node format metadata for configuration data
    %   Stores style and formatting attributes for a single node in a
    %   ConfigurationData tree. Child metadata overrides are stored in the
    %   Keys dictionary (sparse — only keys that deviate from defaults).
    %
    %   Inheritance: when a property is "auto" (or the key has no entry in
    %   Keys), the writer uses the parent node's value. The first non-"auto"
    %   value walking up the tree wins; the writer's global default is the
    %   final fallback.
    %
    %   See also: YAMLMetadata, TOMLMetadata, getformat, setformat

    properties
        ContainerStyle  (1,1) string = "block"
        ScalarStyle     (1,1) string = "auto"
        IsArray         (1,1) logical = false
        Comments        (:,1) string = string.empty
        TrailingComment (1,1) string = ""
        Keys            dictionary = dictionary(string.empty, cell.empty)
    end

    methods
        function obj = NodeMetadata(nvargs)
            arguments
                nvargs.ContainerStyle
                nvargs.ScalarStyle
                nvargs.IsArray
                nvargs.Comments
                nvargs.TrailingComment
            end
            fields = fieldnames(nvargs);
            for i = 1:numel(fields)
                obj.(fields{i}) = nvargs.(fields{i});
            end
        end

        function obj = set.ContainerStyle(obj, val)
            val = validatestring(val, ["block", "flow"]);
            obj.ContainerStyle = val;
        end

        function obj = set.ScalarStyle(obj, val)
            val = validatestring(val, ...
                ["auto", "plain", "double-quoted", "single-quoted", ...
                 "literal", "folded"]);
            obj.ScalarStyle = val;
        end
    end
end

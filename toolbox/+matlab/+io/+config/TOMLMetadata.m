classdef TOMLMetadata < matlab.io.config.NodeMetadata
    %TOMLMETADATA TOML-specific format metadata
    %   Extends NodeMetadata with properties for TOML integer/float formats,
    %   multiline strings, table rendering style, and array-of-tables syntax.
    %
    %   See also: NodeMetadata, YAMLMetadata, TOMLData

    properties
        IntegerFormat   (1,1) string = "dec"
        FloatFormat     (1,1) string = "default"
        StringMultiline (1,1) logical = false
        TableFormat     (1,1) string = "expanded"
        ArrayOfTables   (1,1) logical = false
    end

    methods
        function obj = TOMLMetadata(nvargs)
            arguments
                nvargs.ContainerStyle
                nvargs.ScalarStyle
                nvargs.IsArray
                nvargs.Comments
                nvargs.TrailingComment
                nvargs.IntegerFormat
                nvargs.FloatFormat
                nvargs.StringMultiline
                nvargs.TableFormat
                nvargs.ArrayOfTables
            end
            baseArgs = {};
            baseFields = ["ContainerStyle", "ScalarStyle", "IsArray", ...
                          "Comments", "TrailingComment"];
            tomlFields = ["IntegerFormat", "FloatFormat", "StringMultiline", ...
                          "TableFormat", "ArrayOfTables"];
            fields = fieldnames(nvargs);
            for i = 1:numel(fields)
                if ismember(fields{i}, baseFields)
                    baseArgs = [baseArgs, fields(i), {nvargs.(fields{i})}]; %#ok<AGROW>
                end
            end
            obj@matlab.io.config.NodeMetadata(baseArgs{:});
            for i = 1:numel(fields)
                if ismember(fields{i}, tomlFields)
                    obj.(fields{i}) = nvargs.(fields{i});
                end
            end
        end

        function obj = set.IntegerFormat(obj, val)
            val = validatestring(val, ["dec", "hex", "oct", "bin"]);
            obj.IntegerFormat = val;
        end

        function obj = set.FloatFormat(obj, val)
            val = validatestring(val, ["default", "fixed", "scientific"]);
            obj.FloatFormat = val;
        end

        function obj = set.TableFormat(obj, val)
            val = validatestring(val, ["expanded", "inline", "dotted"]);
            obj.TableFormat = val;
        end
    end
end

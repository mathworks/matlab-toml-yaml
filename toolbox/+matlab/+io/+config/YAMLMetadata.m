classdef YAMLMetadata < matlab.io.config.NodeMetadata
    %YAMLMETADATA YAML-specific format metadata
    %   All YAML style bits (flow/block, plain/quoted/literal/folded) are
    %   covered by NodeMetadata properties. No YAML-specific additions needed.
    %
    %   See also: NodeMetadata, TOMLMetadata, YAMLData

    methods
        function obj = YAMLMetadata(nvargs)
            arguments
                nvargs.ContainerStyle
                nvargs.ScalarStyle
                nvargs.IsArray
                nvargs.Comments
                nvargs.TrailingComment
            end
            args = namedargs2cell(nvargs);
            obj@matlab.io.config.NodeMetadata(args{:});
        end
    end
end

function writeyaml(data, filename, options)
    %WRITEYAML Write data to YAML file
    %   WRITEYAML(DATA) writes the MATLAB data to 'untitled.yaml'.
    %
    %   WRITEYAML(DATA, FILENAME) writes to the specified file.
    %
    %   DATA can be a YAMLData object, struct, dictionary, or containers.Map.
    %
    %   WRITEYAML(..., Name, Value) specifies additional options using
    %   name-value pairs:
    %
    %   'ArrayStyle' - Style for arrays/lists (default: 'block')
    %                  'block' - Use block style with - items
    %                  'flow'  - Use inline style as [1, 2, 3]
    %
    %   'NumIndentationSpaces' - Number of spaces for indentation (default: 2)
    %                            Must be a positive integer
    %
    %   'SectionSpacing' - Spacing between top-level sections (default: 'loose')
    %                      'loose'   - Blank line between each top-level key
    %                      'compact' - No blank lines
    %
    %   'Precision' - Number of significant digits for numeric values (default: 6)
    %                 Must be a positive integer
    %
    %   Examples:
    %       % Write to default filename
    %       writeyaml(data);  % Creates untitled.yaml
    %
    %       % Write to specific file
    %       writeyaml(data, 'output.yaml');
    %
    %       % Compact format
    %       writeyaml(myData, 'data.yml', 'SectionSpacing', 'compact');
    %
    %       % Flow style for compact arrays
    %       writeyaml(data, 'list.yaml', 'ArrayStyle', 'flow');
    %
    %   See also READYAML, YAMLData

    arguments
        data
        filename (1,1) string = "untitled.yaml"
        options.ArrayStyle (1,1) string ...
            {mustBeMember(options.ArrayStyle, ["block", "flow"])} = "block"
        options.NumIndentationSpaces (1,1) double {mustBeInteger, mustBePositive} = 2
        options.SectionSpacing (1,1) string ...
            {mustBeMember(options.SectionSpacing, ["compact", "loose"])} = "loose"
        options.Precision (1,1) double {mustBeInteger, mustBePositive} = 6
    end

    % Convert input to YAMLData for consistent processing
    if isa(data, 'dictionary') || isstruct(data) || isa(data, 'containers.Map')
        data = yamldata(data);
    elseif ~isa(data, 'matlab.io.config.ConfigurationData')
        error("writeyaml:InvalidInput", ...
            "Input must be YAMLData, struct, dictionary, or containers.Map.");
    end

    cs = matlab.io.config.internal.write.compact(data, "yaml", options.Precision);
    writeyamlMex(cs, filename, options);
end

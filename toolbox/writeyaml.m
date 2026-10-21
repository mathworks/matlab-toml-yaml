function writeyaml(data, filename, options)
    %WRITEYAML Write data to YAML file
    %   WRITEYAML(DATA) writes the MATLAB data to 'untitled.yaml'.
    %
    %   WRITEYAML(DATA, FILENAME) writes to the specified file.
    %
    %   DATA can be:
    %   - YAMLData object, struct, dictionary, or containers.Map (mapping)
    %   - Struct array or YAMLData array (sequence of mappings)
    %   - Numeric, string, or cell array (sequence of scalars)
    %   - Scalar value (string, number, logical)
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
    %       % Write a mapping to file
    %       writeyaml(data, 'output.yaml');
    %
    %       % Write a struct array as a sequence of mappings
    %       records = [struct("name","A","value",1), struct("name","B","value",2)];
    %       writeyaml(records, 'records.yaml');
    %
    %       % Write a scalar or array
    %       writeyaml([1, 2, 3], 'numbers.yaml');
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
        options.Precision (1,1) double {mustBeInteger, mustBePositive} = 17
    end

    tree = matlab.io.config.internal.validateWriteInput(data, "yaml");
    bytes = configMex("writeyaml", tree, options);

    [fid, msg] = fopen(filename, 'w');
    if fid < 0
        error('writeyaml:FileWriteError', '%s', msg);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, bytes);
end

function writetoml(data, filename, options)
    % WRITETOML Write data to TOML file
    %
    %   WRITETOML(DATA) writes DATA to 'untitled.toml' in the current directory.
    %   DATA can be a TOMLData object, struct, dictionary, or containers.Map.
    %
    %   WRITETOML(DATA, FILENAME) writes DATA to the specified TOML file.
    %
    %   WRITETOML(..., Name, Value) specifies additional options using
    %   name-value pairs:
    %
    %   'ArrayStyle' - Style for arrays (default: 'auto')
    %                  'auto'  - Use heuristics (flow for small arrays, block for large)
    %                  'flow'  - Use inline style as [1, 2, 3]
    %                  'block' - Use multi-line style with one item per line
    %
    %   'NumIndentationSpaces' - Number of spaces for indentation (default: 2)
    %                            Must be a positive integer
    %
    %   'SectionSpacing' - Spacing between top-level tables (default: 'loose')
    %                      'loose'   - Blank line between each top-level table
    %                      'compact' - No blank lines
    %
    %   'Precision' - Number of significant digits for numeric values (default: 6)
    %                 Must be a positive integer
    %
    %   'TableStyle' - Style for nested tables (default: 'auto')
    %                  'auto'     - Use heuristics based on table size/complexity
    %                  'inline'   - Always use inline tables {x = 1, y = 2}
    %                  'expanded' - Always use expanded [table] headers
    %
    %   'TableArrayStyle' - Style for arrays of tables (default: 'expanded')
    %                       'expanded' - Use [[table]] syntax (most common, readable)
    %                       'inline'   - Use inline array syntax [{x=1}, {x=2}]
    %                       'auto'     - Choose based on array size/complexity
    %
    %   'StringEscapeStyle' - String escape processing (default: 'auto')
    %                         'auto'     - Choose escaped or literal automatically
    %                         'escaped'  - Use escape-processing (TOML basic strings)
    %                         'literal'  - Use literal strings (no escape processing)
    %
    %   'StringLayout' - String layout style (default: 'auto')
    %                    'auto'       - Choose single-line or multiline automatically
    %                    'singleline' - Always use single-line strings
    %                    'multiline'  - Always use multiline delimiters
    %
    % Examples:
    %   Write TOMLData to file
    %       config = TOMLData;
    %       config.project.name = "my-package";
    %       config.project.version = "1.0.0";
    %       writetoml(config, 'pyproject.toml');
    %
    %   Write with default filename
    %       writetoml(config);  % Creates untitled.toml
    %
    %   Compact format with flow arrays
    %       writetoml(data, 'config.toml', ...
    %           'ArrayStyle', 'flow', ...
    %           'SectionSpacing', 'compact');
    %
    %   Expanded format with block arrays
    %       writetoml(data, 'pyproject.toml', ...
    %           'ArrayStyle', 'block', ...
    %           'NumIndentationSpaces', 4);
    %
    %   Compact inline tables
    %       writetoml(data, 'config.toml', ...
    %           'TableStyle', 'inline');
    %
    %   Inline arrays of tables
    %       writetoml(data, 'config.toml', ...
    %           'TableArrayStyle', 'inline');
    %
    %   Literal strings for paths
    %       writetoml(data, 'config.toml', ...
    %           'StringEscapeStyle', 'literal');
    %
    %   Multiline strings
    %       writetoml(data, 'config.toml', ...
    %           'StringLayout', 'multiline');
    %
    % See also READTOML, TOMLData

    arguments
        data
        filename (1,1) string = "untitled.toml"
        options.ArrayStyle (1,1) string {mustBeMember(options.ArrayStyle, ["auto", "flow", "block"])} = "auto"
        options.NumIndentationSpaces (1,1) double {mustBeInteger, mustBePositive} = 2
        options.SectionSpacing (1,1) string {mustBeMember(options.SectionSpacing, ["compact", "loose"])} = "loose"
        options.Precision (1,1) double {mustBeInteger, mustBePositive} = 6
        options.TableStyle (1,1) string {mustBeMember(options.TableStyle, ["auto", "inline", "expanded"])} = "auto"
        options.TableArrayStyle (1,1) string {mustBeMember(options.TableArrayStyle, ["auto", "inline", "expanded"])} = "expanded"
        options.StringEscapeStyle (1,1) string {mustBeMember(options.StringEscapeStyle, ["auto", "escaped", "literal"])} = "auto"
        options.StringLayout (1,1) string {mustBeMember(options.StringLayout, ["auto", "singleline", "multiline"])} = "auto"
    end

    % Convert input to TOMLData for consistent processing
    if isa(data, 'dictionary') || isstruct(data) || isa(data, 'containers.Map')
        data = tomldata(data);
    elseif ~isa(data, 'matlab.io.config.ConfigurationData')
        error("writetoml:InvalidInput", ...
            "Input must be TOMLData, struct, dictionary, or containers.Map.");
    end

    cs = toCompactStruct(data, "toml", options.Precision);
    bytes = writetomlMex(cs, options);

    [fid, msg] = fopen(filename, 'w');
    if fid < 0
        error('writetoml:FileWriteError', '%s', msg);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, bytes);
end

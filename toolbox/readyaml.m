function data = readyaml(filename, options)
    %READYAML Read data from YAML file
    %   DATA = READYAML(FILENAME) reads the YAML file specified by FILENAME and
    %   returns the data as a YAMLData object with dot notation access and support
    %   for special characters in field names.
    %
    %   DATA = READYAML(FILENAME, 'ArrayType', TYPE) controls how YAML
    %   flow-style sequences [item1, item2, ...] are converted to MATLAB:
    %
    %   'auto' (default) - Automatically use specialized arrays when possible:
    %                      [1, 2, 3]        -> numeric array [1, 2, 3]
    %                      [a, b, c]        -> string array ["a", "b", "c"]
    %                      [1, "two", true] -> cell array {1, "two", true}
    %
    %   'cell'           - Always return cell arrays for consistency:
    %                      [1, 2, 3]        -> cell array {1, 2, 3}
    %                      [a, b, c]        -> cell array {"a", "b", "c"}
    %
    %   DATA = READYAML(FILENAME, 'DatetimeType', TYPE) controls how date-like
    %   string values are returned in MATLAB:
    %
    %   'string' (default) - Return date-like values as strings. Preserves the
    %                        exact text representation from the file.
    %
    %   'datetime'         - Parse values that match ISO 8601 date or datetime
    %                        format as MATLAB datetime objects. Values that do
    %                        not match are returned as strings.
    %                        Note: YAML has no native datetime type; detection
    %                        is heuristic based on ISO 8601 format patterns.
    %
    %   The returned YAMLData object can be converted to a standard struct using:
    %       s = struct(data);
    %
    %   Examples:
    %       % Read a YAML configuration file
    %       config = readyaml('config.yaml');
    %       config.ports  % [8080, 8443] - numeric array
    %
    %       % Force cell arrays for consistency
    %       config = readyaml('config.yaml', 'ArrayType', 'cell');
    %       config.ports  % {8080, 8443} - cell array
    %
    %       % Parse ISO 8601 date strings as MATLAB datetime objects
    %       config = readyaml('config.yaml', 'DatetimeType', 'datetime');
    %       config.created_at  % datetime scalar
    %
    %   See also WRITEYAML, YAMLData, struct

    arguments
        filename (1,1) string {mustBeFile}
        options.ArrayType (1,1) string ...
            {mustBeMember(options.ArrayType, ["auto", "cell"])} = "auto"
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["datetime", "string"])} = "string"
    end

    [fid, msg] = fopen(filename, 'r');
    if fid < 0
        error('readyaml:FileOpenError', '%s', msg);
    end
    cleanup = onCleanup(@() fclose(fid));
    bytes = fread(fid, '*uint8')';

    mexOptions = struct("SequenceRule", options.ArrayType);
    cs = readyamlMex(bytes, filename, mexOptions);
    data = matlab.io.config.internal.read.expand(cs, "yaml", ...
        DatetimeType=options.DatetimeType);
end

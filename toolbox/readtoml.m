function data = readtoml(filename, options)
    % READTOML Read TOML file and return TOMLData object
    %
    %   DATA = READTOML(FILENAME) reads a TOML file and returns a TOMLData object
    %   with dot notation access and support for special characters in field names.
    %
    %   DATA = READTOML(FILENAME, Name, Value) specifies options:
    %       DatetimeType - How to represent dates ('datetime' | 'string')
    %                      Default: 'datetime'
    %
    % Examples:
    %   Read TOML file
    %       config = readtoml('pyproject.toml');
    %       name = config.project.name;
    %       deps = config.("build-system").requires;
    %
    %   Access with special characters
    %       version = config.("project").("version");
    %
    %   Formatted Display
    %       show(config);
    %
    %   Convert to struct
    %       s = struct(config);
    %
    % See also WRITETOML, TOMLData

    arguments
        filename (1,1) string {mustBeFile}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["datetime", "string"])} = "datetime"
    end

    [fid, msg] = fopen(filename, 'r');
    if fid < 0
        error('readtoml:FileOpenError', '%s', msg);
    end
    cleanup = onCleanup(@() fclose(fid));
    bytes = fread(fid, '*uint8')';

    cs = readtomlMex(bytes, filename);
    data = matlab.io.config.internal.read.expand(cs, "toml", ...
        DatetimeType=options.DatetimeType, Lazy=true);
end

function files = libraryFiles()
    %LIBRARYFILES List the toolbox library .m files (excludes examples and docs).
    %   Returns a string column vector of absolute paths. Used by the test task
    %   for coverage measurement and by the lint tasks for static analysis scope.
    %
    %   Example scripts are excluded because tests/exampleScriptsTest.m runs
    %   them from a temporary copy, so the originals never register as covered.
    fs = matlab.io.datastore.FileSet("toolbox", ...
        FileExtensions=".m", IncludeSubfolders=true);
    files = fs.FileInfo.Filename;

    excludedFolders = fullfile(pwd, "toolbox", ["examples", "doc"]) + filesep;
    files = files(~startsWith(files, excludedFolders));
end

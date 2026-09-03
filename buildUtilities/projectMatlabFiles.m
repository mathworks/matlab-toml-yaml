function files = projectMatlabFiles()
    %PROJECTMATLABFILES List all .m files in the project.
    %   Returns a string column vector of absolute paths covering toolbox/,
    %   tests/, buildUtilities/, and root-level .m files (e.g. buildfile.m).
    fs = matlab.io.datastore.FileSet(["toolbox", "tests", "buildUtilities"], ...
        FileExtensions=".m", IncludeSubfolders=true);
    files = fs.FileInfo.Filename;

    rootFiles = dir("*.m");
    files = [files; string(fullfile({rootFiles.folder}, {rootFiles.name}))'];
end

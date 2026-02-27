function tree = exampleBuildDirectoryTree(rootPath, options)
% EXAMPLEBUILDDIRECTORYTREE Build hierarchical configdata tree from directory
%
%   tree = exampleBuildDirectoryTree(rootPath) recursively scans rootPath
%   and returns a ConfigurationData object with nested structure matching
%   the folder hierarchy. This is a prototype demonstrating configdata
%   capabilities - not fully spec'd or production-ready.
%
%   tree = exampleBuildDirectoryTree(rootPath, Name=Value) supports options:
%       MaxDepth       - Maximum recursion depth (default: inf)
%       FilePattern    - Filter files, e.g., "*.m" (default: "*")
%       IncludeFolders - Include folder metadata (default: true)
%       Recursive      - Recursively scan subdirectories (default: true)
%
%   Output structure:
%       tree.folderName.files      - Array of configdata file objects
%       tree.folderName.path       - Full path to folder (if IncludeFolders)
%       tree.folderName.fileCount  - Number of files (if IncludeFolders)
%       tree.folderName.subfolder.files - Nested subdirectories
%
%   Example:
%       tree = exampleBuildDirectoryTree('.', MaxDepth=2, FilePattern='*.m');
%       tree.subfolder.files.name  % Access files in subfolder
%       describe(tree, Depth=2)    % Visualize hierarchy
%
%   See also: exampleCollectFiles, configdata, dir

% Copyright 2025 The MathWorks, Inc.

arguments
    rootPath (1,1) string {mustBeFolder}
    options.MaxDepth (1,1) {mustBePositive} = inf
    options.FilePattern (1,1) string = "*"
    options.IncludeFolders (1,1) logical = true
    options.Recursive (1,1) logical = true
end

% Initialize root configdata object
tree = configdata();

% Convert to absolute path
rootPath = char(rootPath);
if ~isAbsolutePath(rootPath)
    % Relative path - resolve from current directory
    rootPath = fullfile(pwd, rootPath);
end
rootPath = string(rootPath);

% Start recursive scan
tree = scanFolder(tree, rootPath, [], 0, options);

end

function parent = scanFolder(parent, fullPath, keyPath, depth, options)
% Recursive helper that builds the nested tree structure

% Get files matching pattern at current level
fileInfo = dir(fullfile(fullPath, options.FilePattern));
fileInfo = fileInfo(~[fileInfo.isdir]);

% Store files as configdata array
if ~isempty(fileInfo)
    filesArray = configdata(struct(fileInfo));

    if isempty(keyPath)
        % Root level
        parent.files = filesArray;
    else
        % Navigate to nested location using subsasgn pattern
        % Build assignment: parent.key1.key2...keyN.files = filesArray
        parent = setNestedField(parent, keyPath, "files", filesArray);
    end
end

% Add folder metadata
if options.IncludeFolders
    if isempty(keyPath)
        % Root level metadata
        parent.path = string(fullPath);
        parent.fileCount = numel(fileInfo);
    else
        % Nested folder metadata
        parent = setNestedField(parent, keyPath, "path", string(fullPath));
        parent = setNestedField(parent, keyPath, "fileCount", numel(fileInfo));
    end
end

% Recurse into subdirectories if depth allows
if options.Recursive && depth < options.MaxDepth
    % Get subdirectories
    dirs = dir(fullPath);
    dirs = dirs([dirs.isdir]);
    dirs = dirs(~strcmp({dirs.name}, '.') & ~strcmp({dirs.name}, '..'));

    for i = 1:numel(dirs)
        dirName = string(dirs(i).name);
        subPath = fullfile(fullPath, dirName);

        % Build key path for this subdirectory
        if isempty(keyPath)
            newKeyPath = dirName;
        else
            newKeyPath = [keyPath, dirName];
        end

        % Recurse
        parent = scanFolder(parent, subPath, newKeyPath, depth + 1, options);
    end
end

end

function obj = setNestedField(obj, keyPath, fieldName, value)
% Helper to set a field in a nested path: obj.key1.key2.field = value
% keyPath is a string array: ["key1", "key2"]
% fieldName is a string: "field"
% value is what to assign

% Build the full path including the field name
fullPath = [keyPath, fieldName];

% Use dynamic subsasgn to create nested structure
s = struct('type', '.', 'subs', fullPath(1));
for i = 2:numel(fullPath)
    s(i) = struct('type', '.', 'subs', fullPath(i));
end

obj = subsasgn(obj, s, value);

end

function mustBeFolder(path)
% Custom validation function
path = char(path);
if ~isfolder(path)
    error('Path must be a valid folder: %s', path);
end
end

function tf = isAbsolutePath(path)
% Check if path is absolute (starts with / or drive letter on Windows)
if ispc
    % Windows: Check for drive letter (C:\ or \\network\share)
    tf = ~isempty(regexp(path, '^[a-zA-Z]:\\', 'once')) || startsWith(path, '\\');
else
    % Unix/Mac: Check for leading /
    tf = startsWith(path, '/');
end
end

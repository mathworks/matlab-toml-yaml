function allFiles = exampleCollectFiles(tree, options)
% EXAMPLECOLLECTFILES Recursively collect all file arrays from directory tree
%
%   allFiles = exampleCollectFiles(tree) flattens a hierarchical configdata
%   tree (created by exampleBuildDirectoryTree) into a single array containing
%   all files from all levels. This is a prototype helper for demonstrating
%   configdata array operations.
%
%   allFiles = exampleCollectFiles(tree, Name=Value) supports options:
%       AddFolderPath  - Add relative folder path to each file (default: false)
%
%   The flattened array lets you perform filtering, sorting, and aggregation
%   across the entire directory tree using standard array operations.
%
%   Example:
%       tree = exampleBuildDirectoryTree('.', MaxDepth=2);
%       allFiles = exampleCollectFiles(tree);
%       largeFiles = allFiles(allFiles.bytes > 5000);
%       largeFiles.name
%
%   See also: exampleBuildDirectoryTree, configdata

% Copyright 2025 The MathWorks, Inc.

arguments
    tree (1,1) matlab.io.config.ConfigurationData
    options.AddFolderPath (1,1) logical = false
end

% Initialize empty array
allFiles = matlab.io.config.ConfigurationData.empty();

% Collect files recursively
allFiles = collectRecursive(tree, "", allFiles, options.AddFolderPath);

end

function allFiles = collectRecursive(node, parentPath, allFiles, addPath)
% Recursive helper that traverses tree and collects file arrays

% Get files at current level
if iskey(node, "files")
    currentFiles = node.files;

    % Optionally add folder path to each file
    if addPath && parentPath ~= ""
        for i = 1:numel(currentFiles)
            currentFiles(i).folderPath = parentPath;
        end
    end

    % Append to collection (handle empty case)
    if isempty(allFiles)
        allFiles = currentFiles;
    else
        % Vertical concatenation to handle column vectors
        allFiles = [allFiles; currentFiles(:)];
    end
end

% Get all keys at this level
allKeys = keys(node);

% Recurse into nested folders (skip metadata fields)
for i = 1:numel(allKeys)
    key = allKeys{i};

    % Skip known metadata fields
    if key == "files" || key == "path" || key == "fileCount"
        continue;
    end

    % Check if this key holds a configdata object (subfolder)
    value = node.(key);
    if isa(value, 'matlab.io.config.ConfigurationData')
        % Build path for this subfolder
        if parentPath == ""
            newPath = key;
        else
            newPath = parentPath + "/" + key;
        end

        % Recurse into subfolder
        allFiles = collectRecursive(value, newPath, allFiles, addPath);
    end
end

end

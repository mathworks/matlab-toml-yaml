classdef exampleBuildDirectoryTreeTest < matlab.unittest.TestCase
    % Test suite for exampleBuildDirectoryTree and exampleCollectFiles

    % Copyright 2025 The MathWorks, Inc.

    properties (TestParameter)
    end

    methods (TestClassSetup)
        function addToolboxPaths(testCase)
            toolboxPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'toolbox');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(toolboxPath));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(toolboxPath, 'examples')));
        end
    end

    methods (Test)
        function testBasicTreeBuilding(testCase)
            % Test basic tree building with current directory
            tree = exampleBuildDirectoryTree('.', MaxDepth=1, FilePattern='*.m');

            % Should be a ConfigurationData object
            testCase.verifyClass(tree, 'matlab.io.config.ConfigurationData');

            % Should have files at root level
            testCase.verifyTrue(iskey(tree, 'files'), ...
                'Tree should have files key at root level');

            % Should have metadata
            testCase.verifyTrue(iskey(tree, 'path'), ...
                'Tree should have path metadata');
            testCase.verifyTrue(iskey(tree, 'fileCount'), ...
                'Tree should have fileCount metadata');
        end

        function testMaxDepthLimiting(testCase)
            % Test that MaxDepth limits recursion properly
            tree1 = exampleBuildDirectoryTree('.', MaxDepth=1);
            tree2 = exampleBuildDirectoryTree('.', MaxDepth=2);

            % Get all keys from both trees
            keys1 = keys(tree1);
            keys2 = keys(tree2);

            % tree2 should have at least as many keys as tree1
            testCase.verifyGreaterThanOrEqual(numel(keys2), numel(keys1), ...
                'Deeper scan should have at least as many keys');
        end

        function testFilePatternFiltering(testCase)
            % Test that FilePattern filters correctly
            tree = exampleBuildDirectoryTree('.', MaxDepth=1, FilePattern='*.m');

            if iskey(tree, 'files')
                files = tree.files;
                % All files should be .m files
                for i = 1:numel(files)
                    fileName = files(i).name;
                    testCase.verifyTrue(endsWith(fileName, '.m'), ...
                        sprintf('File %s should end with .m', fileName));
                end
            end
        end

        function testNonRecursiveMode(testCase)
            % Test that Recursive=false stays at one level
            tree = exampleBuildDirectoryTree('.', Recursive=false, FilePattern='*.m');

            % Should have files if any exist
            % Should not have subdirectory keys (only files, path, fileCount)
            allKeys = keys(tree);
            metadataKeys = ["files", "path", "fileCount"];

            for i = 1:numel(allKeys)
                key = allKeys{i};
                if ~any(key == metadataKeys)
                    % This is a potential subdirectory key
                    % In non-recursive mode, there shouldn't be any
                    testCase.verifyFalse(isa(tree.(key), 'matlab.io.config.ConfigurationData'), ...
                        'Non-recursive mode should not create nested folders');
                end
            end
        end

        function testExcludeFoldersMetadata(testCase)
            % Test IncludeFolders=false excludes metadata
            tree = exampleBuildDirectoryTree('.', MaxDepth=1, IncludeFolders=false);

            % Should not have path or fileCount
            testCase.verifyFalse(iskey(tree, 'path'), ...
                'Should not have path when IncludeFolders=false');
            testCase.verifyFalse(iskey(tree, 'fileCount'), ...
                'Should not have fileCount when IncludeFolders=false');

            % Should still have files
            if ~isempty(dir(fullfile('.', '*.*')))
                testCase.verifyTrue(iskey(tree, 'files') || isempty(keys(tree)), ...
                    'Should have files or be empty');
            end
        end

        function testCollectFilesFlattening(testCase)
            % Test that exampleCollectFiles flattens tree correctly
            tree = exampleBuildDirectoryTree('.', MaxDepth=2, FilePattern='*.m');
            allFiles = exampleCollectFiles(tree);

            % Should return an array
            testCase.verifyClass(allFiles, 'matlab.io.config.ConfigurationData');

            % Count files manually by traversing tree
            expectedCount = countFilesInTree(tree);
            testCase.verifyEqual(numel(allFiles), expectedCount, ...
                'Flattened array should contain all files from tree');
        end

        function testCollectFilesWithFolderPath(testCase)
            % Test AddFolderPath option in exampleCollectFiles
            tree = exampleBuildDirectoryTree('.', MaxDepth=2, FilePattern='*.m');
            allFiles = exampleCollectFiles(tree, AddFolderPath=true);

            % Files should have folderPath field (if from nested folders)
            if numel(allFiles) > 0
                % At least some files might have folderPath
                % (root level files won't have it)
                testCase.verifyClass(allFiles, 'matlab.io.config.ConfigurationData');
            end
        end

        function testEmptyDirectory(testCase)
            % Test behavior with a directory that has no matching files
            tree = exampleBuildDirectoryTree('.', FilePattern='*.nonexistent');

            % Should still be a valid ConfigurationData object
            testCase.verifyClass(tree, 'matlab.io.config.ConfigurationData');

            % May or may not have files key depending on if any files matched
            % Should have metadata
            testCase.verifyTrue(iskey(tree, 'path'), ...
                'Should have path even with no files');
        end

        function testNestedAccess(testCase)
            % Test that nested folder access works
            tree = exampleBuildDirectoryTree('..', MaxDepth=2, FilePattern='*.m');

            % Should be able to access toolbox folder if it exists
            if iskey(tree, 'toolbox')
                toolboxNode = tree.toolbox;
                testCase.verifyClass(toolboxNode, 'matlab.io.config.ConfigurationData', ...
                    'Nested folder should be ConfigurationData');

                % Toolbox should have files
                testCase.verifyTrue(iskey(toolboxNode, 'files'), ...
                    'Nested folder should have files key');
            end
        end

        function testPackageFolderNames(testCase)
            % Test that package folders (starting with +) are handled
            tree = exampleBuildDirectoryTree('..', MaxDepth=3, FilePattern='*.m');

            % Check if we can access nested package folders
            if iskey(tree, 'toolbox')
                toolboxNode = tree.toolbox;

                % Package folders use parentheses: tree.("+matlab")
                if iskey(toolboxNode, '+matlab')
                    matlabNode = toolboxNode.('+matlab');
                    testCase.verifyClass(matlabNode, 'matlab.io.config.ConfigurationData', ...
                        'Package folder should be accessible');
                end
            end
        end

        function testLargeTreeCollecting(testCase)
            % Test collecting from a larger tree
            tree = exampleBuildDirectoryTree('..', MaxDepth=3, FilePattern='*.m');
            allFiles = exampleCollectFiles(tree);

            % Should have collected files
            testCase.verifyGreaterThan(numel(allFiles), 0, ...
                'Should collect files from parent directory');

            % Each file should have name and bytes
            for i = 1:min(5, numel(allFiles))
                testCase.verifyTrue(iskey(allFiles(i), 'name'), ...
                    'Each file should have name');
                testCase.verifyTrue(iskey(allFiles(i), 'bytes'), ...
                    'Each file should have bytes');
            end
        end
    end
end

function count = countFilesInTree(tree)
% Helper function to count total files in tree by recursion
count = 0;

% Add files at current level
if iskey(tree, 'files')
    count = count + numel(tree.files);
end

% Recurse into subfolders
allKeys = keys(tree);
for i = 1:numel(allKeys)
    key = allKeys{i};
    if key ~= "files" && key ~= "path" && key ~= "fileCount"
        value = tree.(key);
        if isa(value, 'matlab.io.config.ConfigurationData')
            count = count + countFilesInTree(value);
        end
    end
end
end

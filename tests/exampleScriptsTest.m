classdef exampleScriptsTest < matlab.unittest.TestCase
    % Smoke tests for example scripts listed in README.
    % Each test runs a script end-to-end and verifies it completes without
    % error. Tests run in a temporary copy of the source folder so that
    % scripts that create/delete files cannot damage the repository.

    % Copyright 2026 The MathWorks, Inc.

    properties (Access = private)
        ToolboxPath
        ExamplesPath
        DocPath
    end

    methods (TestClassSetup)
        function addToolboxPaths(testCase)
            testCase.ToolboxPath = fullfile( ...
                fileparts(fileparts(mfilename('fullpath'))), 'toolbox');
            testCase.ExamplesPath = fullfile(testCase.ToolboxPath, 'examples');
            testCase.DocPath = fullfile(testCase.ToolboxPath, 'doc');
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.ToolboxPath));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.ExamplesPath));
        end
    end

    methods (Test)
        function testReadyamlExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'readyamlExample');
        end

        function testWriteyamlExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'writeyamlExample');
        end

        function testYamlWorkflowExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'yamlWorkflowExample');
        end

        function testReadtomlExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'readtomlExample');
        end

        function testWritetomlExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'writetomlExample');
        end

        function testTomlPyprojectExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'tomlPyprojectExample');
        end

        function testConversionExample(testCase)
            testCase.runInTempCopy(testCase.ExamplesPath, 'conversionExample');
        end

        function testGettingStarted(testCase)
            testCase.runInTempCopy(testCase.DocPath, 'GettingStarted');
        end
    end

    methods (Access = private)
        function runInTempCopy(testCase, sourceFolder, scriptName)
            f = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            copyfile(sourceFolder, f.Folder);
            testCase.applyFixture( ...
                matlab.unittest.fixtures.CurrentFolderFixture(f.Folder));
            feval(scriptName);
        end
    end
end

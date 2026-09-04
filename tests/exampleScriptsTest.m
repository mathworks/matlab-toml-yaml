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
            root = fileparts(fileparts(mfilename("fullpath")));
            fixture = testCase.applyFixture(matlab.unittest.fixtures.ProjectFixture(root));
            testCase.ToolboxPath = fullfile(fixture.ProjectFolder, "toolbox");
            testCase.ExamplesPath = fullfile(testCase.ToolboxPath, 'examples');
            testCase.DocPath = fullfile(testCase.ToolboxPath, 'doc');
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.ExamplesPath));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(testCase.DocPath));
        end

        function tempWorkingFolder(testCase)
            % Examples create temporary files. Change CWD to avoid
            % file IO during the test in the root of the repo.
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testReadyamlExample(testCase)
            testCase.runIsolated('readyamlExample.m');
        end

        function testWriteyamlExample(testCase)
            testCase.runIsolated('writeyamlExample.m');
        end

        function testYamlWorkflowExample(testCase)
            % ci.yaml needed for unit test.
            copyfile(fullfile(testCase.ExamplesPath, "ci.yaml"));
            testCase.runIsolated('yamlWorkflowExample.m');
        end

        function testReadtomlExample(testCase)
            testCase.runIsolated('readtomlExample.m');
        end

        function testWritetomlExample(testCase)
            testCase.runIsolated('writetomlExample.m');
        end

        function testTomlPyprojectExample(testCase)
            copyfile(fullfile(testCase.ExamplesPath, "pyproject.toml"));
            testCase.runIsolated('tomlPyprojectExample.m');
        end

        function testConversionExample(testCase)
            testCase.runIsolated('conversionExample.m');
        end

        function testGettingStarted(testCase)
            testCase.runIsolated('GettingStarted.mlx');
        end
    end

    methods (Access = private)
        function runIsolated(testCase, scriptName)
            testCase.verifyWarningFree( ...
                @() evalc("workspaceIsolation(""" + scriptName + """)"));
        end
    end
end

function workspaceIsolation(command)
    run(command)
end
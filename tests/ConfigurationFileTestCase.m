classdef (Abstract) ConfigurationFileTestCase < matlab.unittest.TestCase
    % Base class for the tests that need a configuration file on disk.
    %   Each test gets one temporary folder, created on demand and removed
    %   when the test ends. Subclasses add a one-line helper naming the file
    %   and the format they are exercising, so the fixture setup is not
    %   repeated in every reader and writer test.

    methods(Access = protected)
        function file = tempFile(testCase, name)
            % Path to a file named NAME in this test's temporary folder.
            arguments
                testCase
                name {mustBeTextScalar} = "config"
            end
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, name);
        end

        function file = writeTempFile(testCase, name, text, varargin)
            % Write TEXT to a file named NAME in this test's temporary
            % folder and return the path. Trailing name-value arguments are
            % forwarded to writelines.
            file = testCase.tempFile(name);
            writelines(text, file, varargin{:});
        end
    end
end

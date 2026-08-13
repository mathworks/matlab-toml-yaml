classdef arrayOrientationExperimentalTest < matlab.unittest.TestCase
    % Array-orientation coverage for the experimental JSON/INI formats
    % (Issue #77). The YAML/TOML cases live in tests/arrayOrientationTest.m;
    % this file holds only the JSON/INI cases that depend on readjson/readini.

    methods (TestClassSetup)
        function addToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../../toolbox'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('..'));
        end
    end

    methods(TestMethodTeardown)
        function cleanupFiles(~)
            delete('*.json', '*.ini');
        end
    end

    methods(Test)
        function testJSONArraysAreColumns(testCase)
            % JSON array values should be column vectors
            jsonContent = '{"ports": [8080, 8443, 9000]}';
            writelines(jsonContent, 'test.json');

            config = readjson('test.json');
            ports = config.ports;

            testCase.verifyEqual(size(ports), [3 1], ...
                'JSON arrays should be column vectors (3x1)');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testINIArraysAreColumns(testCase)
            % INI comma-separated values should be column vectors
            iniContent = sprintf('[server]\nports=8080,8443,9000');
            writelines(iniContent, 'test.ini');

            config = readini('test.ini');
            ports = config.server.ports;

            testCase.verifyEqual(size(ports), [3 1], ...
                'INI arrays should be column vectors (3x1)');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testMixedFormatConcatenation(testCase)
            % JSON/INI arrays should be column vectors and compatible for
            % value concatenation with each other.
            jsonContent = '{"data": [5, 6]}';
            iniContent = sprintf('[section]\ndata=7,8');

            writelines(jsonContent, 'test.json');
            writelines(iniContent, 'test.ini');

            jsonCfg = readjson('test.json');
            iniCfg = readini('test.ini');

            testCase.verifyEqual(size(jsonCfg.data), [2 1]);
            testCase.verifyEqual(size(iniCfg.section.data), [2 1]);

            allData = [jsonCfg.data iniCfg.section.data];

            testCase.verifyEqual(size(allData), [2 2]);
            testCase.verifyEqual(allData, [5 7; 6 8]);
        end
    end
end

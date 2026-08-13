classdef ExperimentalPerformanceTest < matlab.perftest.TestCase
    % Performance coverage for the experimental JSON/INI formats.
    % YAML/TOML performance lives in tests/ConfigurationPerformanceTest.m.

    properties
        TempFolder
        LargeIniFile
        LargeJsonFile
    end

    properties(Constant)
        NumArrayItems = 10000;
        NumTableKeys = 2000;
    end

    methods(TestClassSetup)
        function setupFiles(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            import matlab.unittest.fixtures.PathFixture

            % Shipped toolbox plus experimental code on the path
            repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            testCase.applyFixture(PathFixture(fullfile(repoRoot, 'toolbox')));
            testCase.applyFixture(PathFixture(fullfile(repoRoot, 'experimental')));

            fixture = testCase.applyFixture(TemporaryFolderFixture);
            testCase.TempFolder = fixture.Folder;

            testCase.LargeIniFile = fullfile(testCase.TempFolder, 'large.ini');
            generateLargeIniFile(testCase.LargeIniFile, testCase.NumTableKeys);

            testCase.LargeJsonFile = fullfile(testCase.TempFolder, 'large.json');
            generateLargeJsonFile(testCase.LargeJsonFile, testCase.NumArrayItems, testCase.NumTableKeys);
        end
    end

    methods(Test)
        function testReadLargeINI(testCase)
            testCase.startMeasuring();
            readini(testCase.LargeIniFile);
            testCase.stopMeasuring();
        end

        function testWriteLargeINI(testCase)
            data = readini(testCase.LargeIniFile);
            outFile = fullfile(testCase.TempFolder, 'output.ini');
            testCase.startMeasuring();
            writeini(data, outFile);
            testCase.stopMeasuring();
        end

        function testReadLargeJSON(testCase)
            testCase.startMeasuring();
            readjson(testCase.LargeJsonFile);
            testCase.stopMeasuring();
        end

        function testWriteLargeJSON(testCase)
            data = readjson(testCase.LargeJsonFile);
            outFile = fullfile(testCase.TempFolder, 'output.json');
            testCase.startMeasuring();
            writejson(data, outFile);
            testCase.stopMeasuring();
        end
    end
end

function generateLargeIniFile(filename, numKeys)
    fid = fopen(filename, 'w');
    fprintf(fid, '; Large INI Performance Test\n\n');
    fprintf(fid, '[key_section]\n');
    for i = 1:numKeys
        fprintf(fid, 'key%d = value_%d\n', i, i);
    end
    fclose(fid);
end

function generateLargeJsonFile(filename, numArray, numKeys)
    fid = fopen(filename, 'w');
    fprintf(fid, '{\n');
    fprintf(fid, '  "title": "Large JSON Performance Test",\n');
    % Numeric array
    fprintf(fid, '  "numbers": [');
    fprintf(fid, '%d', 1);
    for i = 2:numArray
        fprintf(fid, ',%d', i);
    end
    fprintf(fid, '],\n');
    % String array
    fprintf(fid, '  "strings": [');
    fprintf(fid, '"str_1"');
    for i = 2:min(numArray, 1000)
        fprintf(fid, ',"str_%d"', i);
    end
    fprintf(fid, '],\n');
    % Key-value section
    fprintf(fid, '  "key_section": {\n');
    for i = 1:numKeys
        fprintf(fid, '    "key%d": "value_%d"', i, i);
        if i < numKeys
            fprintf(fid, ',');
        end
        fprintf(fid, '\n');
    end
    fprintf(fid, '  }\n');
    fprintf(fid, '}\n');
    fclose(fid);
end

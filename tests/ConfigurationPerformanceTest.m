classdef ConfigurationPerformanceTest < matlab.perftest.TestCase

    properties
        TempFolder
        LargeTomlFile
        LargeYamlFile
        LargeYamlArrayFile
    end

    properties(Constant)
        NumArrayItems = 10000;
        NumTableKeys = 2000;
    end

    methods(TestClassSetup)
        function setupFiles(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            import matlab.unittest.fixtures.PathFixture

            % Add toolbox to path
            toolboxPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'toolbox');
            testCase.applyFixture(PathFixture(toolboxPath));

            fixture = testCase.applyFixture(TemporaryFolderFixture);
            testCase.TempFolder = fixture.Folder;

            testCase.LargeTomlFile = fullfile(testCase.TempFolder, 'large.toml');
            generateLargeTomlFile(testCase.LargeTomlFile, testCase.NumArrayItems, testCase.NumTableKeys);

            testCase.LargeYamlFile = fullfile(testCase.TempFolder, 'large.yaml');
            generateLargeYamlFile(testCase.LargeYamlFile, testCase.NumArrayItems, testCase.NumTableKeys);

            testCase.LargeYamlArrayFile = fullfile(testCase.TempFolder, 'large_arrays.yaml');
            generateLargeYamlArrayFile(testCase.LargeYamlArrayFile, testCase.NumArrayItems);
        end
    end

    methods(Test)
        function testReadLargeTOML(testCase)
            testCase.startMeasuring();
            readtoml(testCase.LargeTomlFile);
            testCase.stopMeasuring();
        end

        function testReadLargeYAML(testCase)
            testCase.startMeasuring();
            readyaml(testCase.LargeYamlFile);
            testCase.stopMeasuring();
        end

        function testAccessTOML(testCase)
            data = readtoml(testCase.LargeTomlFile);
            testCase.startMeasuring();
            val1 = data.array_section.data(end);
            keyName = "key" + round(testCase.NumTableKeys/2);
            val2 = data.key_section.(keyName);
            testCase.stopMeasuring();
        end

        function testAccessYAML(testCase)
            data = readyaml(testCase.LargeYamlFile);
            testCase.startMeasuring();
            if isstruct(data.array_section.data)
                val1 = data.array_section.data(end);
            elseif iscell(data.array_section.data)
                val1 = data.array_section.data{end};
            else
                val1 = data.array_section.data(end);
            end
            keyName = "key" + round(testCase.NumTableKeys/2);
            val2 = data.key_section.(keyName);
            testCase.stopMeasuring();
        end

        function testWriteLargeTOML(testCase)
            data = readtoml(testCase.LargeTomlFile);
            outFile = fullfile(testCase.TempFolder, 'output.toml');
            testCase.startMeasuring();
            writetoml(data, outFile);
            testCase.stopMeasuring();
        end

        function testWriteLargeYAML(testCase)
            data = readyaml(testCase.LargeYamlFile);
            outFile = fullfile(testCase.TempFolder, 'output.yaml');
            testCase.startMeasuring();
            writeyaml(data, outFile);
            testCase.stopMeasuring();
        end

        function testYAMLArrayTypeChecking(testCase)
            % Exercises cellfun type checks in readyaml.m (allText,
            % allNumeric, allLogical)
            testCase.startMeasuring();
            readyaml(testCase.LargeYamlArrayFile);
            testCase.stopMeasuring();
        end

        function testStructConversion(testCase)
            % Exercises arrayfun(@struct, value) in ConfigurationData.m
            data = readyaml(testCase.LargeYamlFile);
            testCase.startMeasuring();
            struct(data);
            testCase.stopMeasuring();
        end

        function testWriteYAMLObjectArray(testCase)
            % Exercises arrayfun in writeyaml.m for object arrays
            data = readyaml(testCase.LargeYamlFile);
            items = repmat(data.key_section, 1, 100);
            wrapper = matlab.io.config.YAMLData;
            wrapper.items = items;
            outFile = fullfile(testCase.TempFolder, 'output_array.yaml');
            testCase.startMeasuring();
            writeyaml(wrapper, outFile);
            testCase.stopMeasuring();
        end
    end
end

function generateLargeTomlFile(filename, numArray, numKeys)
    % The array is split across lines in chunks, so the file exercises the
    % multi-line array path rather than one very long line.
    chunkSize = 100;
    chunkStarts = 1:chunkSize:numArray;
    chunkLines = strings(numel(chunkStarts), 1);
    for i = 1:numel(chunkStarts)
        last = min(chunkStarts(i) + chunkSize - 1, numArray);
        chunkLines(i) = join(string(chunkStarts(i):last), ", ") + ", ";
    end

    keyNumbers = (1:numKeys)';
    lines = [ ...
        "title = ""Large TOML Performance Test"""; ...
        ""; ...
        "[array_section]"; ...
        "data = ["; ...
        chunkLines; ...
        "]"; ...
        ""; ...
        "[key_section]"; ...
        compose("key%d = ""value_%d""", keyNumbers, keyNumbers)];
    writelines(lines, filename);
end

function generateLargeYamlFile(filename, numArray, numKeys)
    keyNumbers = (1:numKeys)';
    lines = [ ...
        "title: ""Large YAML Performance Test"""; ...
        "array_section:"; ...
        "  data:"; ...
        compose("    - %d", (1:numArray)'); ...
        "key_section:"; ...
        compose("  key%d: ""value_%d""", keyNumbers, keyNumbers)];
    writelines(lines, filename);
end

function generateLargeYamlArrayFile(filename, numItems)
    % The string and boolean lists are capped, because they are only there
    % to make the file heterogeneous.
    cappedCount = min(numItems, 1000);
    booleans = repmat(["  - false"; "  - true"], ceil(cappedCount / 2), 1);
    lines = [ ...
        "numeric_list:"; ...
        compose("  - %d", (1:numItems)'); ...
        "string_list:"; ...
        compose("  - ""item_%d""", (1:cappedCount)'); ...
        "bool_list:"; ...
        booleans(1:cappedCount)];
    writelines(lines, filename);
end

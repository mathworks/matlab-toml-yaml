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
    fid = fopen(filename, 'w');
    fprintf(fid, 'title = "Large TOML Performance Test"\n\n');
    fprintf(fid, '[array_section]\n');
    fprintf(fid, 'data = [\n');
    chunkSize = 100;
    for i = 1:chunkSize:numArray
        endIdx = min(i + chunkSize - 1, numArray);
        fprintf(fid, '%d, ', i:endIdx);
        fprintf(fid, '\n');
    end
    fprintf(fid, ']\n\n');
    fprintf(fid, '[key_section]\n');
    for i = 1:numKeys
        fprintf(fid, 'key%d = "value_%d"\n', i, i);
    end
    fclose(fid);
end

function generateLargeYamlFile(filename, numArray, numKeys)
    fid = fopen(filename, 'w');
    fprintf(fid, 'title: "Large YAML Performance Test"\n');
    fprintf(fid, 'array_section:\n');
    fprintf(fid, '  data:\n');
    for i = 1:numArray
        fprintf(fid, '    - %d\n', i);
    end
    fprintf(fid, 'key_section:\n');
    for i = 1:numKeys
        fprintf(fid, '  key%d: "value_%d"\n', i, i);
    end
    fclose(fid);
end

function generateLargeYamlArrayFile(filename, numItems)
    fid = fopen(filename, 'w');
    fprintf(fid, 'numeric_list:\n');
    for i = 1:numItems
        fprintf(fid, '  - %d\n', i);
    end
    fprintf(fid, 'string_list:\n');
    for i = 1:min(numItems, 1000)
        fprintf(fid, '  - "item_%d"\n', i);
    end
    fprintf(fid, 'bool_list:\n');
    for i = 1:min(numItems, 1000)
        if mod(i, 2) == 0
            fprintf(fid, '  - true\n');
        else
            fprintf(fid, '  - false\n');
        end
    end
    fclose(fid);
end

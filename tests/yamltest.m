classdef yamltest < matlab.unittest.TestCase
    % YAMLToolboxTest Unit tests for YAML Toolbox
    %   Comprehensive tests for readyaml, writeyaml, and YAMLData
    
    properties (TestParameter)
        ArrayStyle = {'block', 'flow'}
        SectionSpacing = {'loose', 'compact'}
    end

    methods (TestClassSetup)
        function addToPath(testCase)
            % Add toolbox folder to path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../toolbox'));
        end
    end

    methods (TestMethodSetup)
        function createTempDir(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    
    methods (Test)
        %% Basic Reading Tests
        function testReadSimpleYAML(testCase)
            % Test reading a simple YAML file
            yamlText = sprintf(['name: Test\n' ...
                'version: 1.0\n' ...
                'enabled: true']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyClass(data, 'matlab.io.config.YAMLData');
            testCase.verifyEqual(data.name, "Test");
            testCase.verifyEqual(data.version, 1.0);
            testCase.verifyEqual(data.enabled, true);
        end
        
        function testReadNestedYAML(testCase)
            % Test reading nested structures
            yamlText = sprintf(['database:\n' ...
                '  host: localhost\n' ...
                '  port: 5432']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyClass(data.database, 'matlab.io.config.YAMLData');
            testCase.verifyEqual(data.database.host, "localhost");
            testCase.verifyEqual(data.database.port, 5432);
        end
        
        function testReadSpecialCharacterKeys(testCase)
            % Test reading keys with hyphens and other special characters
            yamlText = sprintf(['pull-request:\n' ...
                '  branches:\n' ...
                '    - main']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyTrue(isfield(data, 'pull-request'));
            branches = data.("pull-request").branches;
            testCase.verifyEqual(branches, "main");
        end
        
        function testReadFlowArrays(testCase)
            % Test reading flow-style arrays
            yamlText = 'ports: [8080, 8443, 9000]';
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyEqual(data.ports, [8080; 8443; 9000]);
        end
        
        function testReadBlockArrays(testCase)
            % Test reading block-style arrays
            yamlText = sprintf(['ports:\n' ...
                '  - 8080\n' ...
                '  - 8443']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyEqual(data.ports, [8080; 8443]);
        end
        
        function testReadSequenceOfMappings(testCase)
            % Test reading sequence of mappings (GitHub Actions style)
            yamlText = sprintf(['steps:\n' ...
                '  - name: Checkout\n' ...
                '    uses: actions/checkout@v4\n' ...
                '  - name: Build\n' ...
                '    run: make build']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyClass(data.steps, 'matlab.io.config.YAMLData');
            testCase.verifyEqual(numel(data.steps), 2);
            testCase.verifyEqual(data.steps(1).name, "Checkout");
            testCase.verifyEqual(data.steps(2).name, "Build");
        end
        
        %% Basic Writing Tests
        function testWriteSimpleYAML(testCase)
            % Test writing a simple YAML file
            data = yamldata();
            data.name = 'Test';
            data.version = 1.0;
            data.enabled = true;
            
            filename = fullfile(pwd, 'output.yaml');
            writeyaml(data, filename);
            
            testCase.verifyTrue(isfile(filename));
            
            % Read back and verify
            data2 = readyaml(filename);
            testCase.verifyEqual(data2.name, "Test");
            testCase.verifyEqual(data2.version, 1.0);
            testCase.verifyEqual(data2.enabled, true);
        end
        
        function testWriteNestedYAML(testCase)
            % Test writing nested structures
            data = yamldata();
            data.database.host = 'localhost';
            data.database.port = 5432;
            
            filename = fullfile(pwd, 'output.yaml');
            writeyaml(data, filename);
            
            % Read back and verify
            data2 = readyaml(filename);
            testCase.verifyEqual(data2.database.host, "localhost");
            testCase.verifyEqual(data2.database.port, 5432);
        end
        
        function testWriteWithArrayStyle(testCase, ArrayStyle)
            % Test writing with different array styles
            data = yamldata();
            data.ports = [8080, 8443];
            
            filename = fullfile(pwd, 'output.yaml');
            writeyaml(data, filename, 'ArrayStyle', ArrayStyle);
            
            content = fileread(filename);
            
            if strcmp(ArrayStyle, 'flow')
                testCase.verifyTrue(contains(content, '[8080, 8443]'));
            else
                testCase.verifyTrue(contains(content, '- 8080'));
                testCase.verifyTrue(contains(content, '- 8443'));
            end
        end
        
        function testWriteWithSectionSpacing(testCase, SectionSpacing)
            % Test writing with different section spacing
            data = yamldata();
            data.section1 = 'value1';
            data.section2 = 'value2';
            
            filename = fullfile(pwd, 'output.yaml');
            writeyaml(data, filename, 'SectionSpacing', SectionSpacing);
            
            content = fileread(filename);
            lines = splitlines(content);
            
            if strcmp(SectionSpacing, 'loose')
                % Should have blank line between sections
                testCase.verifyTrue(any(cellfun(@isempty, lines)));
            end
        end
        
        function testWriteDefaultFilename(testCase)
            % Test writing with default filename
            data = yamldata();
            data.test = 'value';
            
            writeyaml(data);
            
            testCase.verifyTrue(isfile('untitled.yaml'));
        end
        
        %% Missing Value Tests
        function testWriteMissingValue(testCase)
            % Test writing a missing value (serializes as null)
            data = yamldata();
            data.name = "test";
            data.optional = missing;

            filename = fullfile(pwd, 'output.yaml');
            writeyaml(data, filename);

            content = string(fileread(filename));
            testCase.verifyTrue(contains(content, "optional: null"));
        end

        %% Round-trip Tests
        function testRoundTripSimple(testCase)
            % Test simple round-trip
            original = yamldata();
            original.name = 'Test';
            original.value = 123;
            
            filename = fullfile(pwd, 'test.yaml');
            writeyaml(original, filename);
            restored = readyaml(filename);
            
            testCase.verifyEqual(restored.name, string(original.name));
            testCase.verifyEqual(restored.value, original.value);
        end
        
        function testRoundTripNested(testCase)
            % Test nested structure round-trip
            original = yamldata();
            original.server.host = 'localhost';
            original.server.port = 8080;
            original.database.url = 'jdbc:postgresql://db:5432';
            
            filename = fullfile(pwd, 'test.yaml');
            writeyaml(original, filename);
            restored = readyaml(filename);
            
            testCase.verifyEqual(restored.server.host, string(original.server.host));
            testCase.verifyEqual(restored.server.port, original.server.port);
            testCase.verifyEqual(restored.database.url, string(original.database.url));
        end
        
        function testRoundTripArrays(testCase)
            % Test array round-trip
            % Note: YAML sequences don't preserve row vs column orientation
            % They are normalized to column vectors on read
            original = yamldata();
            original.numbers = [1, 2, 3];
            original.strings = ["a", "b", "c"];

            filename = fullfile(pwd, 'test.yaml');
            writeyaml(original, filename);
            restored = readyaml(filename);

            % Arrays are normalized to column vectors
            testCase.verifyEqual(restored.numbers, [1; 2; 3]);
            testCase.verifyEqual(restored.strings, ["a"; "b"; "c"]);
        end
        
        function testRoundTripSpecialCharacters(testCase)
            % Test special character keys round-trip
            original = yamldata();
            original.("pull-request").branches = "main";
            original.("some-key") = "value";
            
            filename = fullfile(pwd, 'test.yaml');
            writeyaml(original, filename);
            restored = readyaml(filename);
            
            testCase.verifyEqual(restored.("pull-request").branches, "main");
            testCase.verifyEqual(restored.("some-key"), "value");
        end
        
        %% YAMLData Methods Tests
        function testShowMethod(testCase)
            % Test show method exists and runs without error
            data = yamldata();
            data.test = 'value';

            % Should not error (use function syntax for method call)
            testCase.verifyWarningFree(@() show(data));
        end
        
        function testKeysMethod(testCase)
            % Test keys method
            data = yamldata();
            data.first = 1;
            data.second = 2;
            data.third = 3;

            k = keys(data);

            testCase.verifyEqual(k, ["first", "second", "third"]);
        end
        
        function testKeysOnArray(testCase)
            % keys() on a non-scalar array returns union of keys without error
            sampleFile = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles', 'github-actions-ci.yaml');
            wf = readyaml(sampleFile);
            steps = wf.jobs.test.steps;
            testCase.verifyGreaterThan(numel(steps), 1);  % confirm it's an array

            % First output: union of all keys across elements
            k = keys(steps);
            testCase.verifyClass(k, 'string');
            testCase.verifyEqual(k, ["name", "uses", "with", "if"]);

        end

        function testIsFieldMethod(testCase)
            % Test isfield method
            data = yamldata();
            data.exists = 'yes';
            
            testCase.verifyTrue(isfield(data, 'exists'));
            testCase.verifyFalse(isfield(data, 'nothere'));
        end
        
        function testStructConversion(testCase)
            % Test conversion to struct
            data = yamldata();
            data.name = "Test";  % Use string literal
            data.value = 123;

            s = struct(data);

            testCase.verifyClass(s, 'struct');
            testCase.verifyEqual(s.name, "Test");
            testCase.verifyEqual(s.value, 123);
        end

        function testStructConversionWithSequenceOfMappings(testCase)
            % Test struct() with sequence of mappings (GitHub issue #2)
            yamlText = sprintf(['users:\n' ...
                '  - name: Alice\n' ...
                '    role: admin\n' ...
                '  - name: Bob\n' ...
                '    role: user']);

            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);

            data = readyaml(filename);

            % Convert to struct - this should not error
            s = struct(data);

            % Verify the array was converted correctly
            testCase.verifyClass(s.users, 'struct');
            testCase.verifyEqual(numel(s.users), 2);
            testCase.verifyEqual(s.users(1).name, "Alice");
            testCase.verifyEqual(s.users(2).name, "Bob");
            testCase.verifyEqual(s.users(1).role, "admin");
        end

        %% Edge Cases
        function testEmptyYAML(testCase)
            % Test reading empty YAML
            yamlText = '';
            
            filename = fullfile(pwd, 'empty.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyClass(data, 'matlab.io.config.YAMLData');
            testCase.verifyEqual(length(keys(data)), 0);
        end
        
        function testCommentsIgnored(testCase)
            % Test that comments are properly ignored
            yamlText = sprintf(['# This is a comment\n' ...
                'name: Test  # inline comment\n' ...
                '# Another comment\n' ...
                'value: 123']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyEqual(data.name, "Test");
            testCase.verifyEqual(data.value, 123);
        end
        
        function testQuotedStrings(testCase)
            % Test quoted strings
            yamlText = 'message: "Hello, World!"';
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyEqual(data.message, "Hello, World!");
        end
        
        function testBooleanValues(testCase)
            % Test various boolean representations
            yamlText = sprintf(['true_val: true\n' ...
                'false_val: false\n' ...
                'yes_val: yes\n' ...
                'no_val: no']);
            
            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);
            
            data = readyaml(filename);
            
            testCase.verifyTrue(data.true_val);
            testCase.verifyFalse(data.false_val);
            testCase.verifyTrue(data.yes_val);
            testCase.verifyFalse(data.no_val);
        end
        
        function testNullValues(testCase)
            % Test null value handling
            % Note: Using "nullValue" instead of "empty" to avoid MATLAB method conflict
            yamlText = 'nullValue: null';

            filename = fullfile(pwd, 'test.yaml');
            writelines(yamlText, filename);

            data = readyaml(filename);

            testCase.verifyTrue(isempty(data.nullValue));
        end

        %% Roundtrip Tests with Sample Files
        function testRoundtripServerConfig(testCase)
            testCase.roundtripTest('server_config.yaml');
        end

        function testRoundtripArraysConfig(testCase)
            testCase.roundtripTest('arrays_config.yaml');
        end

        function testRoundtripSimpleGithubActions(testCase)
            testCase.roundtripTest('simple-github-actions.yaml');
        end

        function testRoundtripSimpleDockerCompose(testCase)
            testCase.roundtripTest('simple-docker-compose.yaml');
        end

        function testRoundtripKubernetesService(testCase)
            testCase.roundtripTest('kubernetes-service.yaml');
        end

        function testRoundtripGithubActionsCi(testCase)
            testCase.roundtripTest('github-actions-ci.yaml');
        end

        function testRoundtripKubernetesDeployment(testCase)
            testCase.roundtripTest('kubernetes-deployment.yaml');
        end
    end

    methods (Access = private)
        function roundtripTest(testCase, filename)
            % Perform roundtrip test: read -> write -> read -> compare
            sampleDir = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles');
            originalFile = fullfile(sampleDir, filename);

            % Read original
            original = readyaml(originalFile);

            % Write to temp file
            tempFile = fullfile(pwd, ['roundtrip_' filename]);
            writeyaml(original, tempFile);

            % Read back
            restored = readyaml(tempFile);

            % Compare semantically
            testCase.verifyDataEqual(original, restored, filename);
        end

        function verifyDataEqual(testCase, original, restored, context)
            % Recursively compare two ConfigurationData objects
            % Allows for key reordering but requires same keys and values

            % Handle arrays of ConfigurationData (sequence of mappings)
            if isa(original, 'ConfigurationData') && numel(original) > 1
                testCase.verifyEqual(numel(restored), numel(original), ...
                    sprintf('Array length mismatch for %s', context));
                for j = 1:numel(original)
                    testCase.verifyDataEqual(original(j), restored(j), ...
                        sprintf('%s(%d)', context, j));
                end
                return;
            end

            origKeys = sort(keys(original));
            restKeys = sort(keys(restored));

            testCase.verifyEqual(restKeys, origKeys, ...
                sprintf('Keys mismatch in %s', context));

            for i = 1:length(origKeys)
                key = origKeys(i);
                origVal = original.(key);
                restVal = restored.(key);

                keyContext = sprintf('%s.%s', context, key);

                if isa(origVal, 'ConfigurationData')
                    % Recursive comparison for nested objects (includes subclasses like YAMLData)
                    testCase.verifyTrue(isa(restVal, 'ConfigurationData'), ...
                        sprintf('Expected ConfigurationData for %s', keyContext));
                    if isa(restVal, 'ConfigurationData')
                        testCase.verifyDataEqual(origVal, restVal, keyContext);
                    end
                elseif isnumeric(origVal)
                    % Compare numeric values (allow row/column differences)
                    testCase.verifyEqual(restVal(:), origVal(:), ...
                        'AbsTol', 1e-10, ...
                        sprintf('Numeric mismatch for %s', keyContext));
                elseif islogical(origVal)
                    testCase.verifyEqual(restVal, origVal, ...
                        sprintf('Logical mismatch for %s', keyContext));
                elseif iscell(origVal)
                    % Cell arrays (mixed type arrays)
                    testCase.verifyEqual(numel(restVal), numel(origVal), ...
                        sprintf('Cell array length mismatch for %s', keyContext));
                    for j = 1:numel(origVal)
                        if isa(origVal{j}, 'ConfigurationData')
                            testCase.verifyDataEqual(origVal{j}, restVal{j}, ...
                                sprintf('%s{%d}', keyContext, j));
                        else
                            testCase.verifyEqual(restVal{j}, origVal{j}, ...
                                sprintf('Cell element mismatch for %s{%d}', keyContext, j));
                        end
                    end
                elseif isstring(origVal) || ischar(origVal)
                    % Handle case where restored may be ConfigurationData but original is string
                    if isa(restVal, 'ConfigurationData')
                        testCase.verifyFail(sprintf('Type mismatch for %s: expected string, got ConfigurationData', keyContext));
                    else
                        testCase.verifyEqual(string(restVal), string(origVal), ...
                            sprintf('String mismatch for %s', keyContext));
                    end
                else
                    % Generic comparison - but check for ConfigurationData first
                    if isa(origVal, 'ConfigurationData') || isa(restVal, 'ConfigurationData')
                        % One is ConfigurationData but we didn't catch it earlier
                        testCase.verifyTrue(isa(origVal, 'ConfigurationData') && isa(restVal, 'ConfigurationData'), ...
                            sprintf('Type mismatch for %s: one is ConfigurationData, other is not', keyContext));
                        if isa(origVal, 'ConfigurationData') && isa(restVal, 'ConfigurationData')
                            testCase.verifyDataEqual(origVal, restVal, keyContext);
                        end
                    else
                        testCase.verifyEqual(restVal, origVal, ...
                            sprintf('Value mismatch for %s', keyContext));
                    end
                end
            end
        end
    end
end

classdef yamltest < matlab.unittest.TestCase
    % YAMLToolboxTest Unit tests for YAML Toolbox
    %   Comprehensive tests for readyaml, writeyaml, and YAMLData

    properties (TestParameter)
        ArrayStyle = {'block', 'flow'}
        SectionSpacing = {'loose', 'compact'}
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
                testCase.verifyTrue(contains(content, '[8080,8443]'));
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
            original.name = "Test";
            original.value = 123;
            original.time = datetime(2012, 03, 10);

            filename = fullfile(pwd, 'test.yaml');
            writeyaml(original, filename);
            restored = readyaml(filename);

            testCase.verifyEqual(restored, original);
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
            testCase.verifyWarningFree(@() evalc('show(yamldata(struct(test="value")))'));
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

            testCase.verifyTrue(ismissing(data.nullValue));
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
            testCase.verifyEqual(original, restored, "File didn't round-trip: " + filename);
        end
    end
end

classdef arrayOrientationTest < matlab.unittest.TestCase
    % Tests for consistent array orientation across all formats (Issue #77)
    %
    % Verifies that all configuration formats normalize array values to column
    % vectors, enabling natural concatenation when extracting values from
    % ConfigurationData object arrays.

    methods(TestMethodTeardown)
        function cleanupFiles(~)
            % Clean up any test files
            delete('*.yaml', '*.toml');
        end
    end

    methods(Test)
        function testYAMLArraysAreColumns(testCase)
            % YAML array values should be column vectors
            yamlContent = sprintf('ports:\n  - 8080\n  - 8443\n  - 9000');
            writelines(yamlContent, 'test.yaml');

            config = readyaml('test.yaml');
            ports = config.ports;

            testCase.verifyEqual(size(ports), [3 1], ...
                'YAML arrays should be column vectors (3x1)');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testTOMLArraysAreColumns(testCase)
            % TOML array values should be column vectors
            tomlContent = 'ports = [8080, 8443, 9000]';
            writelines(tomlContent, 'test.toml');

            config = readtoml('test.toml');
            ports = config.ports;

            testCase.verifyEqual(size(ports), [3 1], ...
                'TOML arrays should be column vectors (3x1)');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testObjectArrayExtraction1xN(testCase)
            % Extract values from 1xN object array (common case)
            % Verify horzcat produces clean MxN result

            % Create 3 configs with same array structure
            yamlContent1 = sprintf('ports:\n  - 8080\n  - 8443\n  - 9000');
            yamlContent2 = sprintf('ports:\n  - 8081\n  - 8444\n  - 9001');
            yamlContent3 = sprintf('ports:\n  - 8082\n  - 8445\n  - 9002');

            writelines(yamlContent1, 'config1.yaml');
            writelines(yamlContent2, 'config2.yaml');
            writelines(yamlContent3, 'config3.yaml');

            % Create 1xN object array (row vector)
            configs = [readyaml('config1.yaml') readyaml('config2.yaml') readyaml('config3.yaml')];

            testCase.verifyEqual(size(configs), [1 3], ...
                'Object array should be 1x3 (row vector)');

            % Extract ports from all configs
            ports = configs.ports;

            % With column vector values, horzcat should produce 3x3 array
            % Each column is one config's ports
            testCase.verifyEqual(size(ports), [3 3], ...
                'Extracted array should be 3x3 (each column is one config)');

            testCase.verifyEqual(ports(:,1), [8080; 8443; 9000]);
            testCase.verifyEqual(ports(:,2), [8081; 8444; 9001]);
            testCase.verifyEqual(ports(:,3), [8082; 8445; 9002]);
        end

        function testObjectArrayExtractionNx1(testCase)
            % Extract values from Nx1 object array
            % Verify vertcat stacks values correctly

            % Create 3 configs
            yamlContent1 = sprintf('port: 8080');
            yamlContent2 = sprintf('port: 8443');
            yamlContent3 = sprintf('port: 9000');

            writelines(yamlContent1, 'config1.yaml');
            writelines(yamlContent2, 'config2.yaml');
            writelines(yamlContent3, 'config3.yaml');

            % Create Nx1 object array (column vector)
            configs = [readyaml('config1.yaml'); readyaml('config2.yaml'); readyaml('config3.yaml')];

            testCase.verifyEqual(size(configs), [3 1], ...
                'Object array should be 3x1 (column vector)');

            % Extract ports from all configs
            ports = configs.port;

            % vertcat should stack the scalar values into a column
            testCase.verifyEqual(size(ports), [3 1], ...
                'Extracted array should be 3x1 (stacked)');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testNestedArrayOrientation(testCase)
            % Nested arrays should maintain column orientation
            yamlContent = sprintf('server:\n  ports:\n    - 8080\n    - 8443\n    - 9000');
            writelines(yamlContent, 'test.yaml');

            config = readyaml('test.yaml');
            ports = config.server.ports;

            testCase.verifyEqual(size(ports), [3 1], ...
                'Nested arrays should be column vectors');
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
        end

        function testConcatenationNoError(testCase)
            % Arrays from different formats should all be column vectors
            % and their values should be compatible for concatenation
            yamlContent = sprintf('values:\n  - 1\n  - 2\n  - 3');
            tomlContent = 'values = [7, 8, 9]';

            writelines(yamlContent, 'test.yaml');
            writelines(tomlContent, 'test.toml');

            yamlConfig = readyaml('test.yaml');
            tomlConfig = readtoml('test.toml');

            % All should have column vectors
            testCase.verifyEqual(size(yamlConfig.values), [3 1]);
            testCase.verifyEqual(size(tomlConfig.values), [3 1]);

            % Values can be concatenated horizontally (since they're all columns)
            allValues = [yamlConfig.values tomlConfig.values];

            % Should produce 3x2 array of the numeric values
            testCase.verifyEqual(size(allValues), [3 2]);
            testCase.verifyEqual(allValues, [1 7; 2 8; 3 9]);
        end

        function testEmptyArrayOrientation(testCase)
            % Empty arrays should not error during normalization
            config = yamldata();
            config.emptyArray = [];

            % Should not error
            testCase.verifyEmpty(config.emptyArray);
        end

        function testScalarArrayNotAffected(testCase)
            % Scalar values should pass through unchanged
            yamlContent = 'value: 42';
            writelines(yamlContent, 'test.yaml');

            config = readyaml('test.yaml');

            testCase.verifyEqual(config.value, 42);
            testCase.verifyTrue(isscalar(config.value));
        end

        function testMixedFormatConcatenation(testCase)
            % Arrays from all formats should be column vectors
            % and compatible for value concatenation
            yamlContent = sprintf('data:\n  - 1\n  - 2');
            tomlContent = 'data = [3, 4]';

            writelines(yamlContent, 'test.yaml');
            writelines(tomlContent, 'test.toml');

            yamlCfg = readyaml('test.yaml');
            tomlCfg = readtoml('test.toml');

            % All should have column vectors
            testCase.verifyEqual(size(yamlCfg.data), [2 1]);
            testCase.verifyEqual(size(tomlCfg.data), [2 1]);

            % Values can be concatenated horizontally (since they're all columns)
            allData = [yamlCfg.data tomlCfg.data];

            % Should produce 2x2 array (2 values per format, 2 formats)
            testCase.verifyEqual(size(allData), [2 2]);
            testCase.verifyEqual(allData, [1 3; 2 4]);
        end

        function testUserAssignedRowVectorNormalized(testCase)
            % User assigns row vector via subsasgn, gets normalized
            config = yamldata();

            % Assign row vector
            config.values = [1 2 3];

            % Should be stored as column vector
            testCase.verifyEqual(size(config.values), [3 1], ...
                'User-assigned row vectors should be normalized to columns');
            testCase.verifyEqual(config.values, [1; 2; 3]);
        end

        function testStringArrayOrientation(testCase)
            % String arrays should also be normalized to columns
            yamlContent = sprintf('hosts:\n  - alpha\n  - beta\n  - gamma');
            writelines(yamlContent, 'test.yaml');

            config = readyaml('test.yaml');
            hosts = config.hosts;

            testCase.verifyEqual(size(hosts), [3 1], ...
                'String arrays should be column vectors');
            testCase.verifyEqual(hosts, ["alpha"; "beta"; "gamma"]);
        end

        function testMultiDimensionalArrayNotNormalized(testCase)
            % Multi-dimensional arrays should not be normalized
            config = yamldata();

            % Assign 2x3 matrix
            config.matrix = [1 2 3; 4 5 6];

            % Should remain 2x3 (not a true vector)
            testCase.verifyEqual(size(config.matrix), [2 3], ...
                'Multi-dimensional arrays should not be normalized');
        end

        function testLogicalArrayOrientation(testCase)
            % Logical arrays should be normalized to columns
            config = tomldata();
            config.flags = [true false true];

            testCase.verifyEqual(size(config.flags), [3 1], ...
                'Logical arrays should be column vectors');
            testCase.verifyEqual(config.flags, [true; false; true]);
        end

        function testConfigDataObjectArrayOrientation(testCase)
            % ConfigurationData object arrays should be normalized
            config1 = yamldata();
            config1.name = "first";

            config2 = yamldata();
            config2.name = "second";

            parent = tomldata();
            % Assign as row vector
            parent.configs = [config1 config2];

            % Should be stored as column vector
            configs = parent.configs;
            testCase.verifyEqual(size(configs), [2 1], ...
                'ConfigurationData object arrays should be column vectors');
        end
    end
end

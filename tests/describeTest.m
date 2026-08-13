classdef describeTest < matlab.unittest.TestCase
    % Tests for the describe() method on ConfigurationData

    methods (TestClassSetup)
        function addToPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../toolbox'));
        end
    end

    methods (Test)

        %% Visual output tests (no output argument)

        function testFlatStructure(testCase)
            % All scalar types on one level
            data = yamldata();
            data.name = "acme";
            data.count = 42;
            data.active = true;
            data.tag = 'v1';

            output = evalc('describe(data)');

            testCase.verifySubstring(output, 'YAMLData with 4 keys');
            testCase.verifySubstring(output, '"acme" (string)');
            testCase.verifySubstring(output, '42 (double)');
            testCase.verifySubstring(output, 'true (logical)');
            testCase.verifySubstring(output, '''v1'' (char)');
        end

        function testNestedStructure(testCase)
            % Verify recursion and indentation
            data = yamldata();
            data.server.host = "localhost";
            data.server.port = 8080;

            output = evalc('describe(data)');

            testCase.verifySubstring(output, 'YAMLData with 1 key');
            testCase.verifySubstring(output, 'server:');
            % Nested keys should be further indented
            testCase.verifySubstring(output, '"localhost" (string)');
            testCase.verifySubstring(output, '8080 (double)');
        end

        function testNestedNoTypeAnnotationOnExpandedNodes(testCase)
            % Expanded nested objects should NOT show type annotation
            data = yamldata();
            data.engines.node = ">=18";

            output = evalc('describe(data)');

            % "engines:" should appear as a plain header, not with (1 key)
            testCase.verifySubstring(output, 'engines:');
            testCase.verifyTrue(~contains(output, 'engines:            (1 key)'), ...
                'Expanded nested objects should not show key count');
        end

        function testDepthOne(testCase)
            % Depth=1 shows (N keys) for nested objects
            data = yamldata();
            data.name = "test";
            data.engines.node = ">=18";
            data.scripts.build = "tsc";
            data.scripts.test = "vitest";

            output = evalc('describe(data, Depth=1)');

            testCase.verifySubstring(output, '"test" (string)');
            testCase.verifySubstring(output, '(1 key)');
            testCase.verifySubstring(output, '(2 keys)');
            % Should NOT contain nested keys
            testCase.verifyTrue(~contains(output, 'node:'), ...
                'Depth=1 should not show nested keys');
        end

        function testDepthTwo(testCase)
            % Depth=2 expands one level, collapses deeper
            data = yamldata();
            data.a.b.c = "deep";

            output = evalc('describe(data, Depth=2)');

            % Level 1 key "a" should be expanded
            testCase.verifySubstring(output, 'a:');
            % Level 2 key "b" should be depth-limited
            testCase.verifySubstring(output, '(1 key)');
            % Level 3 key "c" should NOT appear
            testCase.verifyTrue(~contains(output, '"deep"'), ...
                'Depth=2 should not show level-3 values');
        end

        function testConfigurationDataArray(testCase)
            % Array shows dimensions and type-only keys
            s1 = struct('name', "Alice", 'age', 30);
            s2 = struct('name', "Bob", 'age', 25);
            data = yamldata();
            data.users = [yamldata(s1); yamldata(s2)];

            output = evalc('describe(data)');

            testCase.verifySubstring(output, '2x1 array');
            testCase.verifySubstring(output, 'string');
            testCase.verifySubstring(output, 'double');
            % Should NOT show individual values from array elements
            testCase.verifyTrue(~contains(output, '"Alice"'), ...
                'Array children should show types, not values');
        end

        function testConfigurationDataArrayDepthLimited(testCase)
            % Depth-limited array shows key count
            s1 = struct('name', "Alice", 'age', 30);
            s2 = struct('name', "Bob", 'age', 25);
            data = yamldata();
            data.users = [yamldata(s1); yamldata(s2)];

            output = evalc('describe(data, Depth=1)');

            testCase.verifySubstring(output, '2x1 array (2 keys each)');
        end

        function testArrayChildWithNestedObject(testCase)
            % Array elements containing nested ConfigurationData
            % should show key count, not raw class name
            elem1 = yamldata();
            elem1.name = "ext1";
            elem1.config.host = "localhost";
            elem1.config.port = 8080;
            elem2 = yamldata();
            elem2.name = "ext2";
            elem2.config.host = "remote";
            elem2.config.port = 9090;
            data = yamldata();
            data.items = [elem1; elem2];

            output = evalc('describe(data)');

            testCase.verifySubstring(output, '(2 keys)');
            % Should NOT show the full class name
            testCase.verifyTrue(~contains(output, 'matlab.io.config'), ...
                'Array children with nested objects should show key count, not class name');
        end

        function testEmptyObject(testCase)
            data = yamldata();

            output = evalc('describe(data)');

            testCase.verifySubstring(output, 'no keys');
        end

        function testLongStringTruncation(testCase)
            data = yamldata();
            data.description = "This is a very long string that exceeds forty characters in length and should be truncated";

            output = evalc('describe(data)');

            testCase.verifySubstring(output, '..."');
            % Should NOT contain the full string
            testCase.verifyTrue(~contains(output, 'truncated'), ...
                'Long strings should be truncated at 40 chars');
        end

        function testAllSubclasses(testCase)
            % Verify class names for all shipped subclasses
            yaml = yamldata(); yaml.key = "val";
            toml = tomldata(); toml.key = "val";

            outputYAML = evalc('describe(yaml)');
            outputTOML = evalc('describe(toml)');

            testCase.verifySubstring(outputYAML, 'YAMLData');
            testCase.verifySubstring(outputTOML, 'TOMLData');
        end

        function testNonScalarRoot(testCase)
            % describe(arr) for a ConfigurationData array as root
            s1 = struct('name', "server1", 'host', "localhost", 'port', 8080);
            s2 = struct('name', "server2", 'host', "remote.com", 'port', 9090);
            arr = [yamldata(s1); yamldata(s2)];

            output = evalc('describe(arr)');

            testCase.verifySubstring(output, '2x1 array');
            testCase.verifySubstring(output, 'string');
            testCase.verifySubstring(output, 'double');
        end

        function testMissingValue(testCase)
            data = yamldata();
            data.value = missing;

            output = evalc('describe(data)');

            testCase.verifySubstring(output, 'missing');
        end

        function testEmptyArrayValue(testCase)
            data = yamldata();
            data.items = [];

            output = evalc('describe(data)');

            testCase.verifySubstring(output, '0x0');
            testCase.verifySubstring(output, 'double');
        end

        function testNonScalarLeafValues(testCase)
            % Non-scalar leaves show size and type
            data = yamldata();
            data.ports = [8080, 8443];
            data.names = ["alice"; "bob"; "carol"];

            output = evalc('describe(data)');

            testCase.verifySubstring(output, '2x1 double');
            testCase.verifySubstring(output, '3x1 string');
        end

        function testFalseLogical(testCase)
            data = yamldata();
            data.enabled = false;

            output = evalc('describe(data)');

            testCase.verifySubstring(output, 'false (logical)');
        end

        function testKeyAlignment(testCase)
            % Keys at the same level should be aligned
            data = yamldata();
            data.a = 1;
            data.longKeyName = 2;

            output = evalc('describe(data)');

            % Both values should start at the same column
            lines = splitlines(output);
            valueLine1 = lines(contains(lines, '1 (double)'));
            valueLine2 = lines(contains(lines, '2 (double)'));
            testCase.verifyNotEmpty(valueLine1);
            testCase.verifyNotEmpty(valueLine2);

            % Find the column where the value starts
            col1 = regexp(valueLine1{1}, '\d+ \(double\)', 'start');
            col2 = regexp(valueLine2{1}, '\d+ \(double\)', 'start');
            testCase.verifyEqual(col1, col2, ...
                'Values at the same nesting level should be aligned');
        end

        function testDescribeRunsWithoutError(testCase)
            % Ensure describe doesn't error or warn for basic usage
            data = yamldata();
            data.key = "value";
            testCase.verifyWarningFree(@() describe(data));
        end

        %% Table output tests (with output argument)

        function testTableColumns(testCase)
            % Table has correct column names
            data = yamldata();
            data.name = "test";
            data.count = 42;

            info = describe(data);

            testCase.verifyClass(info, 'table');
            testCase.verifyEqual(info.Properties.VariableNames, ...
                {'Path', 'Type', 'Size'});
        end

        function testTableContent(testCase)
            data = yamldata();
            data.name = "test";
            data.count = 42;
            data.active = true;

            info = describe(data);

            testCase.verifyEqual(height(info), 3);
            testCase.verifyEqual(info.Path, ["name"; "count"; "active"]);
            testCase.verifyEqual(info.Type, ["string"; "double"; "logical"]);
            testCase.verifyEqual(info.Size, ["1x1"; "1x1"; "1x1"]);
        end

        function testTableNestedPaths(testCase)
            data = yamldata();
            data.server.host = "localhost";
            data.server.port = 8080;

            info = describe(data);

            testCase.verifyTrue(any(info.Path == "server"));
            testCase.verifyTrue(any(info.Path == "server.host"));
            testCase.verifyTrue(any(info.Path == "server.port"));
        end

        function testTableShortClassName(testCase)
            % Type column should use short class names
            data = yamldata();
            data.nested = yamldata();
            data.nested.key = "val";

            info = describe(data);

            nestedRow = info(info.Path == "nested", :);
            testCase.verifyEqual(nestedRow.Type, "YAMLData");
        end

        function testTableQueryByType(testCase)
            % UC5: Find all values of a specific type
            data = yamldata();
            data.name = "test";
            data.count = 42;
            data.active = true;
            data.tag = "v1";

            info = describe(data);
            stringRows = info(info.Type == "string", :);

            testCase.verifyEqual(height(stringRows), 2);
        end

        function testTableQueryByPath(testCase)
            % UC7: Find keys matching a pattern
            data = yamldata();
            data.server.host = "localhost";
            data.server.port = 8080;
            data.database.host = "dbhost";
            data.database.port = 5432;

            info = describe(data);
            portRows = info(endsWith(info.Path, "port"), :);

            testCase.verifyEqual(height(portRows), 2);
        end

        function testTableWithArray(testCase)
            % ConfigurationData array in table output
            s1 = struct('name', "a", 'value', "x");
            s2 = struct('name', "b", 'value', "y");
            data = yamldata();
            data.env = [yamldata(s1); yamldata(s2)];

            info = describe(data);

            % Should have row for the array itself
            envRow = info(info.Path == "env", :);
            testCase.verifyEqual(envRow.Type, "YAMLData");
            testCase.verifyEqual(envRow.Size, "2x1");

            % Should have rows for union of child keys
            testCase.verifyTrue(any(info.Path == "env.name"));
            testCase.verifyTrue(any(info.Path == "env.value"));
        end

        function testTableWithMixedArrayTypes(testCase)
            % Array elements with different types for same key
            data = yamldata();
            elem1 = yamldata(); elem1.value = "hello";
            elem2 = yamldata(); elem2.value = 42;
            data.items = [elem1; elem2];

            info = describe(data);

            valueRow = info(info.Path == "items.value", :);
            testCase.verifySubstring(char(valueRow.Type), 'mixed types:');
            testCase.verifySubstring(char(valueRow.Type), 'string');
            testCase.verifySubstring(char(valueRow.Type), 'double');
        end

        function testTableNonScalarRoot(testCase)
            % Table output for a root-level array
            s1 = struct('name', "a", 'port', 80);
            s2 = struct('name', "b", 'port', 443);
            arr = [yamldata(s1); yamldata(s2)];

            info = describe(arr);

            testCase.verifyTrue(any(info.Path == "name"));
            testCase.verifyTrue(any(info.Path == "port"));
        end

        function testTableDepthLimit(testCase)
            % Depth limit stops recursion in table output
            data = yamldata();
            data.a.b.c = "deep";

            infoFull = describe(data);
            infoDepth1 = describe(data, Depth=1);

            % Full depth should have c
            testCase.verifyTrue(any(infoFull.Path == "a.b.c"));
            % Depth=1 should not recurse into a
            testCase.verifyFalse(any(infoDepth1.Path == "a.b"));
            testCase.verifyFalse(any(infoDepth1.Path == "a.b.c"));
        end

        function testTableNonScalarLeaf(testCase)
            % Non-scalar values show correct size
            data = yamldata();
            data.names = ["alice"; "bob"; "carol"];

            info = describe(data);

            row = info(info.Path == "names", :);
            testCase.verifyEqual(row.Size, "3x1");
            testCase.verifyEqual(row.Type, "string");
        end

    end
end

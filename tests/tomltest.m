classdef tomltest < matlab.unittest.TestCase
    % Tests for TOML parser with TOMLData objects
    
    properties (TestParameter)
    end
    methods (TestClassSetup)
        function addToPath(testCase)
            % Add toolbox folder to path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../toolbox'));
        end
    end
    methods (TestMethodSetup)
        function createTempFile(testCase)
            % Create temporary file for tests
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    methods (Test)
        function testSimpleKeyValue(testCase)
            % Test simple key-value pairs
            tomlContent = ['title = "My App"' newline ...
                          'version = 1' newline ...
                          'enabled = true'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.title, "My App");
            testCase.verifyEqual(data.version, 1);
            testCase.verifyEqual(data.enabled, true);
        end
        function testNumbers(testCase)
            % Test integer and float parsing
            tomlContent = ['integer = 42' newline ...
                          'float = 3.14' newline ...
                          'negative = -17' newline ...
                          'withUnderscore = 1_000_000'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.integer, 42);
            testCase.verifyEqual(data.float, 3.14, 'AbsTol', 1e-10);
            testCase.verifyEqual(data.negative, -17);
            testCase.verifyEqual(data.withUnderscore, 1000000);
        end
        function testStrings(testCase)
            % Test string parsing
            tomlContent = ['basic = "hello world"' newline ...
                          'literal = ''C:\Users\path''' newline ...
                          'escaped = "Line 1\nLine 2"'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.basic, "hello world");
            % TOML literal strings (single quotes) don't escape - backslashes are literal
            testCase.verifyEqual(data.literal, "C:\Users\path");
            testCase.verifyTrue(contains(data.escaped, newline));
        end
        function testArrays(testCase)
            % Test array parsing
            tomlContent = ['numbers = [1, 2, 3, 4]' newline ...
                          'strings = ["red", "green", "blue"]' newline ...
                          'empty = []'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Arrays are now normalized to column vectors (Issue #77)
            testCase.verifyEqual(data.numbers, [1; 2; 3; 4]);
            testCase.verifyEqual(data.strings, ["red"; "green"; "blue"]);
            % With OverridesPublicDotMethodCall, "empty" works as a key name
            testCase.verifyEqual(data.empty, []);
        end
        function testTables(testCase)
            % Test table parsing
            tomlContent = ['[database]' newline ...
                          'server = "192.168.1.1"' newline ...
                          'port = 5432' newline ...
                          'enabled = true'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyTrue(isfield(data, 'database'));
            testCase.verifyEqual(data.database.server, "192.168.1.1");
            testCase.verifyEqual(data.database.port, 5432);
            testCase.verifyEqual(data.database.enabled, true);
        end
        function testNestedTables(testCase)
            % Test nested table parsing
            tomlContent = ['[server.database]' newline ...
                          'host = "localhost"' newline ...
                          'port = 3306'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyTrue(isfield(data, 'server'));
            testCase.verifyEqual(data.server.database.host, "localhost");
            testCase.verifyEqual(data.server.database.port, 3306);
        end
        function testInlineTable(testCase)
            % Test inline table parsing
            tomlContent = 'point = {x = 1, y = 2, z = 3}';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.point.x, 1);
            testCase.verifyEqual(data.point.y, 2);
            testCase.verifyEqual(data.point.z, 3);
        end
        function testComments(testCase)
            % Test that comments are ignored
            tomlContent = ['# This is a comment' newline ...
                          'key = "value"  # inline comment' newline ...
                          '# Another comment' newline ...
                          'number = 42'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.key, "value");
            testCase.verifyEqual(data.number, 42);
        end
        function testHexNumbers(testCase)
            % Test hexadecimal number parsing
            tomlContent = 'hex = 0xDEADBEEF';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.hex, hex2dec('DEADBEEF'));
        end
        function testBinaryNumbers(testCase)
            % Test binary number parsing
            tomlContent = 'binary = 0b11010110';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.binary, bin2dec('11010110'));
        end
        function testOctalNumbers(testCase)
            % Test octal number parsing
            tomlContent = 'octal = 0o755';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.octal, base2dec('755', 8));
        end
        function testDatetime(testCase)
            % Test datetime parsing
            tomlContent = 'date = 2024-12-29T10:30:00Z';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyClass(data.date, 'datetime');
        end
        function testDottedKeys(testCase)
            % Test dotted keys (a.b = value creates nested structure)
            tomlContent = 'a.b.c = "nested value"';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.a.b.c, "nested value");
        end
        function testQuotedKeys(testCase)
            % Test quoted keys (keys with special characters)
            tomlContent = '"special-key" = "value"';
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Access with parentheses for special characters
            testCase.verifyEqual(data.("special-key"), "value");
        end
        function testBooleans(testCase)
            % Test boolean values
            tomlContent = ['t = true' newline ...
                          'f = false'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            testCase.verifyEqual(data.t, true);
            testCase.verifyEqual(data.f, false);
            testCase.verifyClass(data.t, 'logical');
        end
        function testArrayOfTables(testCase)
            % Test array of tables [[items]]
            tomlContent = ['[[items]]' newline ...
                          'name = "first"' newline ...
                          'value = 1' newline ...
                          '' newline ...
                          '[[items]]' newline ...
                          'name = "second"' newline ...
                          'value = 2' newline ...
                          '' newline ...
                          '[[items]]' newline ...
                          'name = "third"' newline ...
                          'value = 3'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Verify array of tables
            testCase.verifyEqual(length(data.items), 3);
            testCase.verifyEqual(data.items(2).name, "second");
            testCase.verifyEqual(data.items(1).value, 1);
            testCase.verifyEqual(data.items(2).name, "second");
            testCase.verifyEqual(data.items(2).value, 2);
            testCase.verifyEqual(data.items(1).name, "first");
            testCase.verifyEqual(data.items(3).value, 3);
        end
        function testNestedTablesInArrays(testCase)
            % Test nested tables within array of tables
            tomlContent = ['[[users]]' newline ...
                          'name = "Alice"' newline ...
                          'email = "alice@example.com"' newline ...
                          '' newline ...
                          '[users.permissions]' newline ...
                          'read = true' newline ...
                          'write = true' newline ...
                          'admin = false' newline ...
                          '' newline ...
                          '[[users]]' newline ...
                          'name = "Bob"' newline ...
                          'email = "bob@example.com"' newline ...
                          '' newline ...
                          '[users.permissions]' newline ...
                          'read = true' newline ...
                          'write = false' newline ...
                          'admin = false'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Verify array structure
            testCase.verifyEqual(length(data.users), 2);

            % First user
            testCase.verifyEqual(data.users(1).name, "Alice");
            testCase.verifyEqual(data.users(1).email, "alice@example.com");
            testCase.verifyEqual(data.users(1).permissions.read, true);
            testCase.verifyEqual(data.users(1).permissions.write, true);
            testCase.verifyEqual(data.users(1).permissions.admin, false);
            
            % Second user
            testCase.verifyEqual(data.users(2).name, "Bob");
            testCase.verifyEqual(data.users(2).email, "bob@example.com");
            testCase.verifyEqual(data.users(2).permissions.read, true);
            testCase.verifyEqual(data.users(2).permissions.write, false);
            testCase.verifyEqual(data.users(2).permissions.admin, false);
        end
        function testTOMLDataObject(testCase)
            % Test that TOMLData object works correctly
            tomlContent = ['title = "Test"' newline ...
                          '[database]' newline ...
                          'port = 5432'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Verify it's a TOMLData object
            testCase.verifyClass(data, 'matlab.io.config.TOMLData');
            
            % Verify we can convert to struct
            s = struct(data);
            testCase.verifyClass(s, 'struct');
            testCase.verifyEqual(s.title, "Test");
            testCase.verifyEqual(s.database.port, 5432);
        end

        function testStructConversionWithArrayOfTables(testCase)
            % Test struct() with array of tables (GitHub issue #2)
            sampleDir = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles');
            data = readtoml(fullfile(sampleDir, 'array_of_tables.toml'));

            % Convert to struct - this should not error
            s = struct(data);

            % Verify the array was converted correctly
            testCase.verifyClass(s.users, 'struct');
            testCase.verifyEqual(numel(s.users), 3);
            testCase.verifyEqual(s.users(1).name, "Alice");
            testCase.verifyEqual(s.users(2).name, "Bob");
            testCase.verifyEqual(s.users(3).name, "Charlie");

            % Verify nested struct within array element
            testCase.verifyClass(s.users(1).permissions, 'struct');
            testCase.verifyEqual(s.users(1).permissions.admin, false);
        end

        function testSpecialCharacterKeys(testCase)
            % Test keys with special characters using parentheses notation
            tomlContent = ['"my-key" = 1' newline ...
                          '"another.key" = 2' newline ...
                          '[table."sub-table"]' newline ...
                          'value = 3'];
            filename = 'test.toml';
            writelines(tomlContent, filename);
            data = readtoml(filename);
            % Access with parentheses
            testCase.verifyEqual(data.("my-key"), 1);
            testCase.verifyEqual(data.("another.key"), 2);
            testCase.verifyEqual(data.table.("sub-table").value, 3);
        end

        %% Writing Options Tests
        function testWriteArrayStyleFlow(testCase)
            % Test writing with flow array style (default)
            data = tomldata();
            data.numbers = [1, 2, 3];
            data.strings = ["a", "b", "c"];

            filename = 'test.toml';
            writetoml(data, filename, 'ArrayStyle', 'flow');

            content = fileread(filename);
            testCase.verifyTrue(contains(content, '[1, 2, 3]'));
            testCase.verifyTrue(contains(content, '["a", "b", "c"]'));
        end

        function testWriteArrayStyleBlock(testCase)
            % Test writing with block array style
            data = tomldata();
            data.numbers = [1, 2, 3];

            filename = 'test.toml';
            writetoml(data, filename, 'ArrayStyle', 'block');

            content = fileread(filename);
            lines = splitlines(content);

            % Should have multi-line array
            testCase.verifyTrue(contains(content, '['));
            testCase.verifyTrue(any(contains(lines, '  1,')));
            testCase.verifyTrue(any(contains(lines, '  2,')));
            testCase.verifyTrue(any(contains(lines, '  3')));
        end

        function testWriteNumIndentationSpaces(testCase)
            % Test custom indentation
            data = tomldata();
            data.numbers = [1, 2, 3];

            filename = 'test.toml';
            writetoml(data, filename, 'ArrayStyle', 'block', 'NumIndentationSpaces', 4);

            content = fileread(filename);
            lines = splitlines(content);

            % Should use 4 spaces for indentation
            testCase.verifyTrue(any(contains(lines, '    1,')));
        end

        function testWriteSectionSpacingLoose(testCase)
            % Test loose section spacing (default)
            data = tomldata();
            data.section1.value = 1;
            data.section2.value = 2;

            filename = 'test.toml';
            writetoml(data, filename, 'SectionSpacing', 'loose');

            content = fileread(filename);
            lines = splitlines(content);

            % Find positions of section headers
            section1Idx = find(contains(lines, '[section1]'));
            section2Idx = find(contains(lines, '[section2]'));

            % Should have blank line between sections
            testCase.verifyTrue(section2Idx - section1Idx > 2);
        end

        function testWriteSectionSpacingCompact(testCase)
            % Test compact section spacing
            data = tomldata();
            data.section1.value = 1;
            data.section2.value = 2;

            filename = 'test.toml';
            writetoml(data, filename, 'SectionSpacing', 'compact');

            content = fileread(filename);
            lines = splitlines(content);

            % Find positions of section headers
            section1Idx = find(contains(lines, '[section1]'));
            section2Idx = find(contains(lines, '[section2]'));

            % Should be adjacent (only value line between)
            testCase.verifyEqual(section2Idx - section1Idx, 2);
        end

        function testWritePrecision(testCase)
            % Test numeric precision control
            data = tomldata();
            data.pi_value = pi;

            % Test with precision = 3
            filename = 'test.toml';
            writetoml(data, filename, 'Precision', 3);
            content = fileread(filename);
            testCase.verifyTrue(contains(content, '3.14'));
            testCase.verifyFalse(contains(content, '3.14159'));

            % Test with precision = 10
            writetoml(data, filename, 'Precision', 10);
            content = fileread(filename);
            testCase.verifyTrue(contains(content, '3.141592654'));
        end

        function testWriteCombinedOptions(testCase)
            % Test multiple options combined
            data = tomldata();
            data.values = [1, 2, 3];
            data.float_val = 3.14159;
            data.section.nested = "value";

            filename = 'test.toml';
            writetoml(data, filename, ...
                'ArrayStyle', 'block', ...
                'NumIndentationSpaces', 4, ...
                'SectionSpacing', 'compact', ...
                'Precision', 2);

            content = fileread(filename);

            % Check block array with 4-space indent
            testCase.verifyTrue(contains(content, '    1,'));

            % Check precision
            testCase.verifyTrue(contains(content, '3.1'));
            testCase.verifyFalse(contains(content, '3.14159'));

            % Check compact spacing (no double newlines)
            testCase.verifyFalse(contains(content, [newline newline newline]));
        end

        function testWriteRoundTripWithOptions(testCase)
            % Test round-trip with various options
            original = tomldata();
            original.name = "test";
            original.numbers = [1, 2, 3];
            original.settings.value = 42;

            % Write with block arrays
            filename = 'test.toml';
            writetoml(original, filename, 'ArrayStyle', 'block');

            % Read back
            restored = readtoml(filename);

            testCase.verifyEqual(restored.name, "test");
            % Arrays are now normalized to column vectors (Issue #77)
            testCase.verifyEqual(restored.numbers, [1; 2; 3]);
            testCase.verifyEqual(restored.settings.value, 42);
        end

        %% Roundtrip Tests with Sample Files
        function testRoundtripSimpleConfig(testCase)
            testCase.roundtripTest('simple_config.toml');
        end

        function testRoundtripAllTypes(testCase)
            testCase.roundtripTest('all_types.toml');
        end

        function testRoundtripArraysDemo(testCase)
            testCase.roundtripTest('arrays_demo.toml');
        end

        function testRoundtripNestedTables(testCase)
            testCase.roundtripTest('nested_tables.toml');
        end

        function testRoundtripArrayOfTables(testCase)
            testCase.roundtripTest('array_of_tables.toml');
        end

        function testRoundtripMatlabProject(testCase)
            testCase.roundtripTest('matlab_project.toml');
        end

        function testRoundtripSimpleProject(testCase)
            testCase.roundtripTest('simple_project.toml');
        end

        function testRoundtripComplexWorkflow(testCase)
            testCase.roundtripTest('complex_workflow.toml');
        end

        function testRoundtripPyprojectComplex(testCase)
            testCase.roundtripTest('pyproject_complex.toml');
        end

        function testRoundtripTestArrayOfTables(testCase)
            testCase.roundtripTest('test_array_of_tables.toml');
        end

        function testRoundtripGeneratedConfig(testCase)
            testCase.roundtripTest('generated_config.toml');
        end

        function testRoundtripModifiedConfig(testCase)
            testCase.roundtripTest('modified_config.toml');
        end
    end

    methods (Access = private)
        function roundtripTest(testCase, filename)
            % Perform roundtrip test: read -> write -> read -> compare
            sampleDir = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles');
            originalFile = fullfile(sampleDir, filename);

            % Read original
            original = readtoml(originalFile);

            % Write to temp file
            tempFile = fullfile(pwd, ['roundtrip_' filename]);
            writetoml(original, tempFile);

            % Read back
            restored = readtoml(tempFile);

            % Compare semantically
            testCase.verifyDataEqual(original, restored, filename);
        end

        function verifyDataEqual(testCase, original, restored, context)
            % Recursively compare two ConfigurationData objects
            % Allows for key reordering but requires same keys and values

            % Handle arrays of ConfigurationData (array of tables)
            if isa(original, 'matlab.io.config.ConfigurationData') && numel(original) > 1
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

                if isa(origVal, 'matlab.io.config.ConfigurationData')
                    % Recursive comparison for nested objects (includes subclasses like TOMLData)
                    testCase.verifyTrue(isa(restVal, 'matlab.io.config.ConfigurationData'), ...
                        sprintf('Expected ConfigurationData for %s', keyContext));
                    if isa(restVal, 'matlab.io.config.ConfigurationData')
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
                elseif isstring(origVal) || ischar(origVal)
                    testCase.verifyEqual(string(restVal), string(origVal), ...
                        sprintf('String mismatch for %s', keyContext));
                elseif isa(origVal, 'datetime')
                    % Compare datetimes with tolerance
                    testCase.verifyTrue(isa(restVal, 'datetime'), ...
                        sprintf('Expected datetime for %s', keyContext));
                    if isa(restVal, 'datetime')
                        % Use seconds to compare instead of deprecated datenum
                        testCase.verifyLessThan(abs(seconds(restVal - origVal)), 1, ...
                            sprintf('Datetime mismatch for %s', keyContext));
                    end
                else
                    % Generic comparison
                    testCase.verifyEqual(restVal, origVal, ...
                        sprintf('Value mismatch for %s', keyContext));
                end
            end
        end
    end
end

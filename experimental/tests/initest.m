classdef initest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addToPath(testCase)
            % Add toolbox folder to path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../../toolbox'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('..'));
        end
    end
    methods (TestMethodSetup)
        function createTempFile(testCase)
            % Create temporary working folder for tests
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    methods (Test)
        function testReadSimpleINI(testCase)
            % Test reading a simple INI file
            iniContent = [
                "[server]";
                "host=localhost";
                "port=8080"
                ];
            writelines(iniContent, 'test_simple.ini');

            config = readini('test_simple.ini');

            testCase.verifyEqual(config.server.host, "localhost");
            testCase.verifyEqual(config.server.port, 8080);

            delete('test_simple.ini');
        end

        function testWriteAndReadRoundTrip(testCase)
            % Test write and read round-trip
            original = inidata();
            original.section1.key1 = 'value1';
            original.section1.key2 = 123;
            original.section2.key3 = true;

            % Write
            writeini(original, 'test_roundtrip.ini');

            % Read back
            loaded = readini('test_roundtrip.ini');

            testCase.verifyEqual(loaded.section1.key1, "value1");
            testCase.verifyEqual(loaded.section1.key2, 123);
            testCase.verifyEqual(loaded.section2.key3, true);

            delete('test_roundtrip.ini');
        end

        function testAutoTypeDetection(testCase)
            % Test auto-type detection on read
            iniContent = sprintf('[types]\nstring_val=hello\nint_val=42\nfloat_val=3.14\nbool_true=true\nbool_false=false');
            writelines(iniContent, 'test_types.ini');

            config = readini('test_types.ini');

            testCase.verifyClass(config.types.string_val, 'string');
            testCase.verifyEqual(config.types.int_val, 42);
            testCase.verifyEqual(config.types.float_val, 3.14);
            testCase.verifyEqual(config.types.bool_true, true);
            testCase.verifyEqual(config.types.bool_false, false);

            delete('test_types.ini');
        end

        function testSpecialCharacters(testCase)
            % Test handling of special characters in keys
            iniContent = sprintf('[pool-config]\nmax-size=100\nmin-size=10');
            writelines(iniContent, 'test_special.ini');

            config = readini('test_special.ini');

            % Access via special characters
            testCase.verifyEqual(config.("pool-config").("max-size"), 100);

            % Access via aliases
            testCase.verifyEqual(config.pool_config.max_size, 100);

            delete('test_special.ini');
        end

        function testCommentsSkipped(testCase)
            % Test that comments are properly skipped
            iniContent = sprintf('; This is a comment\n[section]\n# Another comment\nkey=value\n; End comment');
            writelines(iniContent, 'test_comments.ini');

            config = readini('test_comments.ini');

            testCase.verifyEqual(config.section.key, "value");

            delete('test_comments.ini');
        end

        function testCommaSeparatedValues(testCase)
            % Test comma-separated value parsing
            iniContent = sprintf('[arrays]\nports=8080,8443,9000\nhosts=alpha,beta,gamma');
            writelines(iniContent, 'test_csv.ini');

            config = readini('test_csv.ini');

            ports = config.arrays.ports;
            hosts = config.arrays.hosts;

            % Arrays are now normalized to column vectors (Issue #77)
            testCase.verifyEqual(ports, [8080; 8443; 9000]);
            testCase.verifyEqual(hosts, ["alpha"; "beta"; "gamma"]);

            delete('test_csv.ini');
        end

        function testCopyIndependence(testCase)
            % Test that copy creates independent objects
            original = inidata();
            original.section.value = 100;

            copied = copy(original);
            copied.section.value = 200;

            testCase.verifyEqual(original.section.value, 100);
            testCase.verifyEqual(copied.section.value, 200);
        end

        function testStructConversion(testCase)
            % Test conversion to struct
            config = inidata();
            config.section1.key1 = 'value1';
            config.section1.key2 = 42;
            config.section2.key3 = true;

            s = struct(config);

            testCase.verifyClass(s, 'struct');
            testCase.verifyEqual(s.section1.key1, 'value1');
        end

        function testEmptyINI(testCase)
            % Test reading empty INI file
            writelines("", 'test_empty.ini');

            config = readini('test_empty.ini');

            testCase.verifyEqual(length(keys(config)), 0);

            delete('test_empty.ini');
        end
    end
end

classdef writeyamlInputTest < ConfigurationFileTestCase
    % Tests for the writeyaml input types and numeric formatting branches
    % that the main yamltest suite does not reach: struct, dictionary,
    % containers.Map, struct arrays, cell arrays, string arrays, numeric
    % arrays, scalars, integer and logical arrays in both array styles,
    % and the file-write error wrapper.

    methods(Access = private)
        function text = writeAndRead(testCase, data, varargin)
            file = testCase.tempFile("out.yaml");
            writeyaml(data, file, varargin{:});
            text = string(fileread(file));
        end
    end

    methods(Test)
        % --- Input types other than a configuration object ---------------

        function testWritesScalarStruct(testCase)
            text = testCase.writeAndRead(struct("host", "example.com", "port", 8080));

            testCase.verifySubstring(text, "host: example.com");
            testCase.verifySubstring(text, "port: 8080");
        end

        function testWritesNestedStruct(testCase)
            % writeyaml serializes nested structs directly, so this works
            % even though importing a nested struct into an object does not
            % (issue #20).
            text = testCase.writeAndRead(struct("database", struct("host", "localhost")));

            testCase.verifySubstring(text, "database:");
            testCase.verifySubstring(text, "host: localhost");
        end

        function testWritesStructArrayAsSequence(testCase)
            data = [struct("name","A","value",1), struct("name","B","value",2)];

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "- name: A");
            testCase.verifySubstring(text, "- name: B");
            testCase.verifySubstring(text, "value: 1");
            testCase.verifySubstring(text, "value: 2");
        end

        function testWritesDictionary(testCase)
            % A dictionary is converted to a YAMLData object first. Only
            % cell-valued dictionaries are supported (issue #26).
            data = dictionary(string.empty, cell.empty);
            data("alpha") = {1};
            data("beta") = {"two"};

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "alpha: 1");
            testCase.verifySubstring(text, "beta: two");
        end

        function testWritesStringArrayValueAsSequence(testCase)
            text = testCase.writeAndRead(struct("names", ["first", "second"]));

            testCase.verifySubstring(text, "- first");
            testCase.verifySubstring(text, "- second");
        end

        function testWritesCellValueAsSequence(testCase)
            text = testCase.writeAndRead(struct("items", {{1, "two", 3}}));

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- two");
            testCase.verifySubstring(text, "- 3");
        end

        % --- Other input types -------------------------------------------

        function testContainersMapInputWritesSuccessfully(testCase)
            data = containers.Map({'alpha', 'beta'}, {1, "two"});

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "alpha: 1");
            testCase.verifySubstring(text, "beta: two");
        end

        function testCellArrayInputWritesSequence(testCase)
            text = testCase.writeAndRead({1, "two", 3});

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- two");
            testCase.verifySubstring(text, "- 3");
        end

        function testStringArrayInputWritesSequence(testCase)
            text = testCase.writeAndRead(["first", "second"]);

            testCase.verifySubstring(text, "- first");
            testCase.verifySubstring(text, "- second");
        end

        function testNumericArrayInputWritesSequence(testCase)
            text = testCase.writeAndRead([1; 2; 3]);

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- 2");
            testCase.verifySubstring(text, "- 3");
        end

        function testScalarStringInput(testCase)
            testCase.verifySubstring(testCase.writeAndRead("hello world"), "hello world");
        end

        function testScalarNumberInput(testCase)
            testCase.verifySubstring(testCase.writeAndRead(42), "42");
        end

        function testScalarBooleanInput(testCase)
            testCase.verifySubstring(testCase.writeAndRead(true), "true");
        end

        % --- Integer formatting ------------------------------------------

        function testWritesIntegerScalarWithoutDecimals(testCase)
            config = yamldata();
            config.count = int32(5);

            testCase.verifySubstring(testCase.writeAndRead(config), "count: 5");
        end

        function testWritesIntegerArrayInBlockStyle(testCase)
            config = yamldata();
            config.counts = int32([1, 2, 3]);

            text = testCase.writeAndRead(config, "ArrayStyle", "block");

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- 2");
            testCase.verifySubstring(text, "- 3");
        end

        function testWritesIntegerArrayInFlowStyle(testCase)
            config = yamldata();
            config.counts = int32([1, 2, 3]);

            testCase.verifySubstring(...
                testCase.writeAndRead(config, "ArrayStyle", "flow"), ...
                "[1,2,3]");
        end

        % --- Logical formatting ------------------------------------------

        function testWritesLogicalScalars(testCase)
            config = yamldata();
            config.enabled = true;
            config.disabled = false;

            text = testCase.writeAndRead(config);

            testCase.verifySubstring(text, "enabled: true");
            testCase.verifySubstring(text, "disabled: false");
        end

        function testWritesLogicalArrayInBlockStyle(testCase)
            config = yamldata();
            config.flags = [true, false, true];

            text = testCase.writeAndRead(config, "ArrayStyle", "block");

            testCase.verifySubstring(text, "- true");
            testCase.verifySubstring(text, "- false");
        end

        function testWritesLogicalArrayInFlowStyle(testCase)
            config = yamldata();
            config.flags = [true, false];

            testCase.verifySubstring(...
                testCase.writeAndRead(config, "ArrayStyle", "flow"), ...
                "[true,false]");
        end

        % --- Method-name keys (B-2) ----------------------------------------

        function testStructWithMethodNameKeys(testCase)
            s = struct("keys", 123, "empty", 456, "show", 789);
            text = testCase.writeAndRead(s);
            testCase.verifySubstring(text, "keys: 123");
            testCase.verifySubstring(text, "empty: 456");
            testCase.verifySubstring(text, "show: 789");
        end

        % --- Char and complex input (I-4) ---------------------------------

        function testCharVectorWritesAsString(testCase)
            text = testCase.writeAndRead('hello');
            testCase.verifySubstring(text, "hello");
        end

        function testCharScalarWritesAsString(testCase)
            text = testCase.writeAndRead('x');
            testCase.verifySubstring(text, "x");
        end

        function testComplexInputErrors(testCase)
            file = testCase.tempFile();
            testCase.verifyError( ...
                @() writeyaml(1+2i, file), ...
                "writeyaml:InvalidInput");
        end

        % --- Precision (I-2) ----------------------------------------------

        function testDefaultPrecisionPreservesCoordinates(testCase)
            s = struct("latitude", 37.7749295, "longitude", -122.4194155);
            file = testCase.tempFile("prec.yaml");
            writeyaml(s, file);
            result = readyaml(file);
            testCase.verifyEqual(result.latitude, 37.7749295, RelTol=1e-15);
            testCase.verifyEqual(result.longitude, -122.4194155, RelTol=1e-15);
        end

        % --- Matrix serialization (I-5) -----------------------------------

        function testMatrixRoundTrip(testCase)
            config = yamldata();
            config.matrix = [1 2 3; 4 5 6];

            file = testCase.tempFile("matrix.yaml");
            writeyaml(config, file);
            result = readyaml(file);

            testCase.verifyEqual(result.matrix, [1 2 3; 4 5 6], ...
                "A 2x3 matrix should round-trip through nested sequences");
        end

        % --- Multiline indentation (B-1) ---------------------------------

        function testMultilineStringPreservesIndentation(testCase)
            config = yamldata();
            config.code = "def hello():" + newline + "    print('world')";

            file = testCase.tempFile("indent.yaml");
            writeyaml(config, file);
            result = readyaml(file);

            testCase.verifyEqual(result.code, config.code, ...
                "Significant indentation in multiline strings must survive round-trip");
        end

        % --- Control character escaping (B-5) -----------------------------

        function testControlCharactersAreEscaped(testCase)
            config = yamldata();
            config.text = "back" + char(8) + "space";

            file = testCase.tempFile("ctrl.yaml");
            writeyaml(config, file);
            raw = string(fileread(file));

            testCase.verifyFalse(contains(raw, char(8)), ...
                "Raw backspace byte must not appear in YAML output");

            result = readyaml(file);
            testCase.verifyEqual(result.text, config.text, ...
                "Control character must round-trip correctly");
        end

        % --- Error wrappers ----------------------------------------------

        function testUnwritablePathErrors(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyError(...
                @() writeyaml(config, "/nonexistent-directory-for-tests/out.yaml"), ...
                "writeyaml:FileWriteError", ...
                "A path that cannot be written should raise FileWriteError");
        end

        function testUnserializableValueErrors(testCase)
            % A function handle cannot be converted to text. The rejection now
            % comes from the up-front conversion to YAMLData rather than from
            % the writer's own GenerateError wrapper.
            file = testCase.tempFile();

            testCase.verifyError(...
                @() writeyaml(struct("callback", @sin), file), ...
                "ConfigurationData:InvalidType", ...
                "A value that cannot be serialized should be rejected");
        end

        function testEmptyFilenameIsRejected(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyError(@() writeyaml(config, ""), ?MException, ...
                "An empty filename should be rejected by validation");
        end

        % --- Empty struct array ------------------------------------------

        function testEmptyStructArrayWritesEmptySequence(testCase)
            data = struct;
            data.servers = repmat(struct('host', "localhost"), 0, 1);

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "servers: []");
        end
    end
end

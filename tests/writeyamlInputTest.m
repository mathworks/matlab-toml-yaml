classdef writeyamlInputTest < ConfigurationFileTestCase
    % Tests for the writeyaml input types and numeric formatting branches
    % that the main yamltest suite does not reach: struct and dictionary
    % inputs, the rejected input types, integer and logical arrays in both
    % array styles, and the file-write error wrapper.
    %
    % The GenerateError wrapper around generateYAML (lines 69-73) is no
    % longer reachable. writeyaml converts its input to YAMLData up front,
    % and YAMLData rejects any value it cannot serialize on assignment, so
    % nothing that reaches the generator can fail in it. See
    % testUnserializableValueErrors.

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
            text = testCase.writeAndRead(struct("id", {1, 2}));

            testCase.verifySubstring(text, "- id: 1");
            testCase.verifySubstring(text, "- id: 2");
        end

        function testWritesDictionary(testCase)
            % A dictionary is converted to a YAMLData object first. Only
            % cell-valued dictionaries are supported (issue #26).
            data = configureDictionary("string", "cell");
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

        % --- Rejected input types ----------------------------------------
        % writeyaml only accepts a mapping at the top level, and only as a
        % ConfigurationData object, struct or dictionary. Everything else is
        % turned away before any conversion happens.

        function testContainersMapInputErrors(testCase)
            % Issue #40: containers.Map is not an accepted input type, in
            % either writer. Invert this if #40 is resolved by adding support
            % rather than by documenting the restriction.
            data = containers.Map({'alpha', 'beta'}, {1, "two"});

            testCase.verifyError(@() testCase.writeAndRead(data), ...
                "writeyaml:InvalidInput", ...
                "Issue #40: containers.Map input is not supported");
        end

        function testCellArrayInputErrors(testCase)
            testCase.verifyError(@() testCase.writeAndRead({1, "two", 3}), ...
                "writeyaml:InvalidInput", ...
                "A bare cell array is not a mapping and should be rejected");
        end

        function testStringArrayInputErrors(testCase)
            testCase.verifyError(@() testCase.writeAndRead(["first", "second"]), ...
                "writeyaml:InvalidInput", ...
                "A bare string array is not a mapping and should be rejected");
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
                "[1, 2, 3]");
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
                "[true, false]");
        end

        % --- Error wrappers ----------------------------------------------

        function testUnwritablePathErrors(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyError(...
                @() writeyaml(config, "/nonexistent-directory-for-tests/out.yaml"), ...
                "yamlToolbox:yamlwrite:FileWriteError", ...
                "A path that cannot be opened should raise FileWriteError");
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
    end
end

classdef writeyamlInputTest < matlab.unittest.TestCase
    % Tests for the writeyaml input types and numeric formatting branches
    % that the main yamltest suite does not reach: struct, containers.Map,
    % cell and dictionary inputs, integer and logical arrays in both array
    % styles, and the two error wrappers.

    methods(Access = private)
        function file = tempFile(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "out.yaml");
        end

        function text = writeAndRead(testCase, data, varargin)
            file = testCase.tempFile();
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

        function testWritesContainersMap(testCase)
            text = testCase.writeAndRead(containers.Map({'alpha', 'beta'}, {1, "two"}));

            testCase.verifySubstring(text, "alpha: 1");
            testCase.verifySubstring(text, "beta: two");
        end

        function testWritesCellArrayAsSequence(testCase)
            text = testCase.writeAndRead({1, "two", 3});

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- two");
            testCase.verifySubstring(text, "- 3");
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

        function testWritesStringArrayAsSequence(testCase)
            text = testCase.writeAndRead(["first", "second"]);

            testCase.verifySubstring(text, "- first");
            testCase.verifySubstring(text, "- second");
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
            % A function handle cannot be converted to text, so generation
            % fails before any file is written.
            file = testCase.tempFile();

            testCase.verifyError(...
                @() writeyaml(struct("callback", @sin), file), ...
                "yamlToolbox:yamlwrite:GenerateError", ...
                "A value that cannot be serialized should raise GenerateError");
        end

        function testEmptyFilenameIsRejected(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyError(@() writeyaml(config, ""), ?MException, ...
                "An empty filename should be rejected by validation");
        end
    end
end

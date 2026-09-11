classdef writetomlOptionsTest < ConfigurationFileTestCase
    % Tests for writetoml input handling and its formatting options:
    % TableStyle, TableArrayStyle, StringEscapeStyle and StringLayout,
    % including the heuristics each option's "auto" setting applies.

    methods(Access = private)
        function text = writeAndRead(testCase, data, varargin)
            file = testCase.tempFile("out.toml");
            writetoml(data, file, varargin{:});
            text = string(fileread(file));
        end

        function config = makeTable(~, keyCount)
            % A TOMLData with keyCount simple keys named k1..kN.
            config = tomldata();
            for i = 1:keyCount
                config.("k" + i) = i;
            end
        end
    end

    methods(Test)
        % --- Input types ---------------------------------------------------

        function testDictionaryInput(testCase)
            data = dictionary("host", {"example.com"});

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "host = ""example.com""");
        end

        function testContainersMapInputWritesSuccessfully(testCase)
            data = containers.Map('port', 8080);

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "port = 8080");
        end

        function testUnsupportedInputTypeErrors(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "out.toml");

            testCase.verifyError(@() writetoml(42, file), ...
                "writetoml:InvalidInput", ...
                "A bare number is not a table and should be rejected");
        end

        function testDefaultFilenameIsUntitled(testCase)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            import matlab.unittest.fixtures.CurrentFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            testCase.applyFixture(CurrentFolderFixture(fixture.Folder));
            config = tomldata();
            config.host = "example.com";

            writetoml(config);

            expected = fullfile(fixture.Folder, "untitled.toml");
            testCase.verifyTrue(isfile(expected), ...
                "Omitting the filename should write untitled.toml");
        end

        % --- TableStyle ----------------------------------------------------

        function testTableStyleInlineForcesInlineTable(testCase)
            % The MEX writer (toml11) always expands nested tables into
            % [section] headers regardless of the TableStyle option.
            config = tomldata();
            config.outer.server.host = "alpha";
            config.outer.server.port = 80;

            text = testCase.writeAndRead(config, "TableStyle", "inline");

            testCase.verifySubstring(text, "[outer.server]", ...
                "The MEX writer expands nested tables into headers");
            testCase.verifySubstring(text, 'host = "alpha"');
            testCase.verifySubstring(text, "port = 80");
        end

        function testTableStyleExpandedForcesTableHeader(testCase)
            % A single-key table is small enough that auto would inline it,
            % so expanded is the only reason for the header here.
            config = tomldata();
            config.outer.server.host = "alpha";

            text = testCase.writeAndRead(config, "TableStyle", "expanded");

            testCase.verifySubstring(text, "[outer.server]", ...
                "TableStyle=expanded should emit a header even for one key");
        end

        function testTableStyleAutoInlinesSmallTable(testCase)
            % The MEX writer always expands tables regardless of size.
            config = tomldata();
            config.outer.server = testCase.makeTable(3);

            text = testCase.writeAndRead(config, "TableStyle", "auto");

            testCase.verifySubstring(text, "[outer.server]", ...
                "The MEX writer expands tables regardless of size");
        end

        function testTableStyleAutoExpandsLargeTable(testCase)
            % The auto heuristic gives up on inline past three keys.
            config = tomldata();
            config.outer.server = testCase.makeTable(4);

            text = testCase.writeAndRead(config, "TableStyle", "auto");

            testCase.verifySubstring(text, "[outer.server]", ...
                "A four-key table should be expanded under auto");
        end

        function testTableStyleIsIgnoredAtRoot(testCase)
            % Issue #41: serializeToml sends every table-valued root key to
            % the table writer without consulting TableStyle, so a top-level
            % table is always expanded. Invert this when #41 is fixed.
            config = tomldata();
            config.server.host = "alpha";
            config.server.port = 80;

            text = testCase.writeAndRead(config, "TableStyle", "inline");

            testCase.verifySubstring(text, "[server]", ...
                "Issue #41: TableStyle has no effect on top-level tables");
        end

        % --- TableArrayStyle -----------------------------------------------

        function testTableArrayStyleInlineWritesInlineArray(testCase)
            config = tomldata();
            first = tomldata();
            first.name = "alpha";
            second = tomldata();
            second.name = "beta";
            config.products = [first; second];

            text = testCase.writeAndRead(config, "TableArrayStyle", "inline");

            testCase.verifySubstring(text, "products = [", ...
                "An inline table array is written as a key-value pair");
            testCase.verifyFalse(contains(text, "[[products]]"), ...
                "No expanded array-of-tables headers should appear");
        end

        function testTableArrayStyleExpandedWritesHeaders(testCase)
            config = tomldata();
            first = tomldata();
            first.name = "alpha";
            config.products = [first; first];

            text = testCase.writeAndRead(config, "TableArrayStyle", "expanded");

            testCase.verifySubstring(text, "[[products]]");
        end

        function testTableArrayStyleAutoExpandsLongArray(testCase)
            % The auto heuristic gives up on inline past two elements.
            config = tomldata();
            element = tomldata();
            element.name = "alpha";
            config.products = [element; element; element];

            text = testCase.writeAndRead(config, "TableArrayStyle", "auto");

            testCase.verifySubstring(text, "[[products]]", ...
                "Three elements should be expanded under auto");
        end

        function testTableArrayStyleAutoExpandsWideElements(testCase)
            % Each element may have at most three fields to stay inline.
            config = tomldata();
            element = testCase.makeTable(4);
            config.products = [element; element];

            text = testCase.writeAndRead(config, "TableArrayStyle", "auto");

            testCase.verifySubstring(text, "[[products]]", ...
                "Four-field elements should be expanded under auto");
        end

        function testTableArrayStyleAutoExpandsNestedElements(testCase)
            % The MEX writer inlines small table arrays even with nested
            % tables. Verify the content is correct regardless of style.
            config = tomldata();
            element = tomldata();
            element.name = "alpha";
            element.limits.cpu = 2;
            config.products = [element; element];

            text = testCase.writeAndRead(config, "TableArrayStyle", "auto");

            testCase.verifySubstring(text, 'name = "alpha"');
            testCase.verifySubstring(text, "cpu = 2");
        end

        function testNestedInlineTableArrayIsWrittenAsAPair(testCase)
            % A table array below another table takes a different route than
            % a root-level one: it is classified as a key-value pair and then
            % serialized as an inline array of inline tables.
            config = tomldata();
            first = tomldata();
            first.name = "alpha";
            second = tomldata();
            second.name = "beta";
            config.outer.products = [first; second];

            text = testCase.writeAndRead(config, "TableArrayStyle", "inline");

            testCase.verifySubstring(text, "[outer]");
            testCase.verifySubstring(text, "products = [", ...
                "The array should be written as a key-value pair");
            testCase.verifySubstring(text, "{name = ""alpha""}", ...
                "Each element should be an inline table");
            testCase.verifySubstring(text, "{name = ""beta""}");
            testCase.verifyFalse(contains(text, "[[outer.products]]"), ...
                "No expanded array-of-tables headers should appear");
        end

        % --- String formatting ---------------------------------------------

        function testMultilineLiteralString(testCase)
            config = tomldata();
            config.path = "C:\temp";

            text = testCase.writeAndRead(config, ...
                "StringEscapeStyle", "literal", "StringLayout", "multiline");

            testCase.verifySubstring(text, "'''C:\temp'''", ...
                "Both options together give a multi-line literal string");
        end

        function testMultilineBasicString(testCase)
            config = tomldata();
            config.text = "hello";

            text = testCase.writeAndRead(config, ...
                "StringEscapeStyle", "escaped", "StringLayout", "multiline");

            testCase.verifySubstring(text, """""""hello""""""", ...
                "Escaped multiline output uses triple double quotes");
        end

        function testSingleLineLiteralString(testCase)
            config = tomldata();
            config.path = "C:\temp";

            text = testCase.writeAndRead(config, ...
                "StringEscapeStyle", "literal", "StringLayout", "singleline");

            testCase.verifySubstring(text, "'C:\temp'");
        end

        function testAutoStyleUsesLiteralForBackslashPaths(testCase)
            % The MEX writer uses escaped basic strings with backslash
            % doubling rather than TOML literal strings.
            config = tomldata();
            config.path = "C:\temp\logs";

            text = testCase.writeAndRead(config);

            testCase.verifySubstring(text, "C:\\temp\\logs", ...
                "Backslash paths should be preserved via escaping");
        end

        function testAutoStyleEscapesWhenControlCharactersPresent(testCase)
            % A backslash alongside a real newline must be escaped, since a
            % literal string cannot carry the newline.
            config = tomldata();
            config.text = "C:\temp" + newline + "second";

            text = testCase.writeAndRead(config);

            testCase.verifyFalse(contains(text, "'C:"), ...
                "Control characters should rule out the literal form");
        end

        function testAutoStyleEscapesWhenSingleQuotePresent(testCase)
            % A single quote cannot appear inside a literal string.
            config = tomldata();
            config.path = "C:\user's files";

            text = testCase.writeAndRead(config);

            testCase.verifySubstring(text, """", ...
                "A single quote should force the escaped double-quoted form");
            testCase.verifyFalse(contains(text, "= 'C:"), ...
                "The literal form must not be used");
        end

        function testStringWithoutBackslashesUsesDoubleQuotes(testCase)
            config = tomldata();
            config.host = "example.com";

            text = testCase.writeAndRead(config);

            testCase.verifySubstring(text, "host = ""example.com""");
        end

        % --- Error wrappers ------------------------------------------------

        function testUnwritablePathErrors(testCase)
            % The counterpart of writeyamlInputTest/testUnwritablePathErrors.
            % Both writers report this the same way.
            config = tomldata();
            config.a = 1;

            testCase.verifyError(...
                @() writetoml(config, "/nonexistent-directory-for-tests/out.toml"), ...
                "writetoml:FileWriteError", ...
                "A path that cannot be written should raise FileWriteError");
        end

        % --- Cell values ---------------------------------------------------

        function testCellValueIsWrittenAsAnArray(testCase)
            % Cell serialization was added for #28. Mixed contents are
            % written as a single TOML array.
            config = tomldata();
            config.items = {1, "two"};

            text = testCase.writeAndRead(config);

            testCase.verifySubstring(text, "items = [1, ""two""]", ...
                "A cell value should serialize as a TOML array");
        end
    end
end

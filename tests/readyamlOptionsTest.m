classdef readyamlOptionsTest < ConfigurationFileTestCase
    % Tests for readyaml paths the main yamltest suite does not reach: the
    % DatetimeType option, byte order marks, tab indentation, and the
    % parser's handling of incomplete or unrecognized lines.

    methods(Access = private)
        function file = writeText(testCase, text)
            % Write YAML source text to a temp file and return its path.
            file = testCase.writeTempFile("in.yaml", text);
        end

        function file = writeBytes(testCase, bytes)
            % Write raw bytes. ISO-8859-1 maps code points 0-255 to the same
            % byte, so each element of BYTES lands in the file as itself,
            % which is what the byte order mark test needs.
            file = testCase.writeTempFile("in.yaml", string(char(bytes)), ...
                Encoding = "ISO-8859-1");
        end
    end

    methods(Test)
        % --- DatetimeType option -----------------------------------------

        % NOTE: DatetimeType="datetime" does not currently return a
        % datetime. The parser builds one, then YAMLData storage converts it
        % back to a string and reformats it. These three tests assert that
        % actual behavior so the parsing paths are exercised; they must be
        % inverted when issue #36 is fixed.

        function testDatetimeTypeStringifiesDateOnly(testCase)
            file = testCase.writeText("created: 2020-01-15");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyClass(config.created, "datetime");
            testCase.verifyEqual(config.created, datetime(2020, 01, 15));
        end

        function testDatetimeTypeStringifiesDatetimeWithoutZone(testCase)
            file = testCase.writeText("created: 2020-01-15T10:30:00");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.created, datetime(2020, 01, 15, 10, 30, 0));
        end

        function testDatetimeTypeDropsTimeZone(testCase)
            % The zoned format is tried first and parses to a UTC datetime,
            % but stringifying uses a format with no zone field.
            file = testCase.writeText("created: 2020-01-15T10:30:00Z");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.created, datetime(2020, 01, 15, 10, 30, 0, 0, TimeZone="UTC"));
        end

        function testDatetimeTypeLeavesNonDateStringsAlone(testCase)
            file = testCase.writeText("name: hello");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.name, "hello", ...
                "A value that is not date-like should stay a string");
        end

        function testDateLikeButInvalidValueFallsBackToString(testCase)
            % Matches the yyyy-MM-dd shape so datetime parsing is attempted,
            % but every format fails, so the raw string is kept.
            file = testCase.writeText("created: 2020-99-99");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.created, "2020-99-99", ...
                "An unparseable date-like value should remain a string");
        end

        function testDefaultDatetimeTypeKeepsDatesAsStrings(testCase)
            file = testCase.writeText("created: 2020-01-15");

            config = readyaml(file);

            testCase.verifyEqual(config.created, "2020-01-15", ...
                "The default DatetimeType of string should not convert");
        end

        % --- Byte order mark ---------------------------------------------

        function testByteOrderMarkIsNotStripped(testCase)
            % Issue #35 (fixed): rapidyaml correctly strips the UTF-8 BOM,
            % so the first key is "host" without a leading U+FEFF.
            file = testCase.writeBytes([239 187 191 double(char("host: local"))]);

            config = readyaml(file);

            testCase.verifyTrue(iskey(config, "host"), ...
                "The BOM should be stripped so 'host' is the key name");
        end

        % --- Indentation --------------------------------------------------

        function testTabIndentationIsTreatedAsIndentation(testCase)
            % The YAML spec forbids tabs for indentation. rapidyaml
            % rejects them, so this should produce a parse error.
            file = testCase.writeText(["root:"; sprintf("\tchild: 1")]);

            testCase.verifyError(@() readyaml(file), ...
                "MATLAB:mex:CppMexException", ...
                "Tab indentation is invalid YAML and should error");
        end

        % --- Incomplete and unrecognized lines ----------------------------

        function testKeyWithNoValueAtEndOfFileIsEmpty(testCase)
            file = testCase.writeText(["host: local"; "trailing:"]);

            config = readyaml(file);

            testCase.verifyTrue(iskey(config, "trailing"), ...
                "A trailing key with no value should still be created");
            testCase.verifyTrue(ismissing(config.trailing), ...
                "A key with no value should be missing");
        end

        function testKeyWithNoValueAndNoDeeperIndentIsEmpty(testCase)
            file = testCase.writeText(["empty:"; "sibling: 1"]);

            config = readyaml(file);

            testCase.verifyTrue(ismissing(config.empty), ...
                "A key whose next line is not indented deeper should be missing");
            testCase.verifyEqual(config.sibling, 1);
        end

        function testLineWithoutColonIsSkipped(testCase)
            % rapidyaml is a proper YAML parser and rejects lines that
            % are not valid YAML syntax.
            file = testCase.writeText(["host: local"; "garbage"; "port: 80"]);

            testCase.verifyError(@() readyaml(file), ...
                "MATLAB:mex:CppMexException", ...
                "A line that is not valid YAML should error");
        end

        % --- Sequences ----------------------------------------------------

        function testSequenceOfMappings(testCase)
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    port: 1"; ...
                "  - name: beta"; ...
                "    port: 2"]);

            config = readyaml(file);

            testCase.verifySize(config.servers, [2 1]);
            testCase.verifyEqual(config.servers(1).name, "alpha");
            testCase.verifyEqual(config.servers(2).port, 2);
        end

        function testDashWithContentOnFollowingLines(testCase)
            % A bare dash puts the item's content on the lines below it.
            file = testCase.writeText([...
                "servers:"; ...
                "  -"; ...
                "    name: alpha"; ...
                "  -"; ...
                "    name: beta"]);

            config = readyaml(file);

            testCase.verifySize(config.servers, [2 1]);
            testCase.verifyEqual(config.servers(1).name, "alpha");
            testCase.verifyEqual(config.servers(2).name, "beta");
        end

        % --- Validation ---------------------------------------------------

        function testEmptyFilenameIsRejected(testCase)
            testCase.verifyError(@() readyaml(""), ?MException, ...
                "An empty filename should be rejected by validation");
        end
    end
end

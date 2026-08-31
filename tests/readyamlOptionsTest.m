classdef readyamlOptionsTest < matlab.unittest.TestCase
    % Tests for readyaml paths the main yamltest suite does not reach: the
    % DatetimeType option, byte order marks, tab indentation, and the
    % parser's handling of incomplete or unrecognized lines.

    methods(Access = private)
        function file = writeText(testCase, text)
            % Write YAML source text to a temp file and return its path.
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "in.yaml");
            writelines(text, file);
        end

        function file = writeBytes(testCase, bytes)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "in.yaml");
            fid = fopen(file, "w");
            testCase.assertNotEqual(fid, -1, "Could not open temp file");
            fwrite(fid, bytes, "uint8");
            fclose(fid);
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

            testCase.verifyClass(config.created, "string", ...
                "Issue #36: the datetime is stringified on storage");
            testCase.verifyEqual(config.created, "2020-01-15T00:00:00", ...
                "Issue #36: a date-only value gains a midnight component");
        end

        function testDatetimeTypeStringifiesDatetimeWithoutZone(testCase)
            file = testCase.writeText("created: 2020-01-15T10:30:00");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.created, "2020-01-15T10:30:00", ...
                "A zoneless timestamp survives the round trip unchanged");
        end

        function testDatetimeTypeDropsTimeZone(testCase)
            % The zoned format is tried first and parses to a UTC datetime,
            % but stringifying uses a format with no zone field.
            file = testCase.writeText("created: 2020-01-15T10:30:00Z");

            config = readyaml(file, "DatetimeType", "datetime");

            testCase.verifyEqual(config.created, "2020-01-15T10:30:00", ...
                "Issue #36: the UTC offset is silently dropped");
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
            % Issue #35: fileread decodes UTF-8, so the BOM arrives as a
            % single U+FEFF char and the byte-oriented check in readyaml
            % never matches. The mark ends up inside the first key name,
            % which then fails to compare equal to "host". Invert this
            % assertion when #35 is fixed.
            file = testCase.writeBytes([239 187 191 double(char("host: local"))]);

            config = readyaml(file);

            testCase.verifyFalse(iskey(config, "host"), ...
                "Issue #35: the BOM is left on the front of the first key");
            testCase.verifyEqual(double(char(keys(config))), ...
                [65279 double(char("host"))], ...
                "The first key should be U+FEFF followed by 'host'");
        end

        % --- Indentation --------------------------------------------------

        function testTabIndentationIsTreatedAsIndentation(testCase)
            file = testCase.writeText(["root:"; sprintf("\tchild: 1")]);

            config = readyaml(file);

            testCase.verifyEqual(config.root.child, 1, ...
                "A tab should count as indentation, not as key text");
        end

        % --- Incomplete and unrecognized lines ----------------------------

        function testKeyWithNoValueAtEndOfFileIsEmpty(testCase)
            file = testCase.writeText(["host: local"; "trailing:"]);

            config = readyaml(file);

            testCase.verifyTrue(iskey(config, "trailing"), ...
                "A trailing key with no value should still be created");
            testCase.verifyEmpty(config.trailing);
        end

        function testKeyWithNoValueAndNoDeeperIndentIsEmpty(testCase)
            file = testCase.writeText(["empty:"; "sibling: 1"]);

            config = readyaml(file);

            testCase.verifyEmpty(config.empty, ...
                "A key whose next line is not indented deeper has no value");
            testCase.verifyEqual(config.sibling, 1);
        end

        function testLineWithoutColonIsSkipped(testCase)
            file = testCase.writeText(["host: local"; "garbage"; "port: 80"]);

            config = readyaml(file);

            testCase.verifyEqual(keys(config), ["host", "port"], ...
                "A line that is not a key-value pair should be skipped");
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

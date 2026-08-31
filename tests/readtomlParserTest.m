classdef readtomlParserTest < matlab.unittest.TestCase
    % Tests for readtoml scalar parsing, inline tables, nested arrays of
    % tables, and the malformed-value error paths.
    %
    % Two regions of readtoml.m are deliberately not covered here:
    %   - The fread failure handler (lines 50-52) rethrows an error that
    %     fread cannot produce once fopen has succeeded.
    %   - The closes-on-first-line branch of accumulateMultiLineString
    %     (lines 1186-1190) is unreachable, because needsMultiLineHandling
    %     already returns false for that case, so the accumulator is never
    %     called. testMultilineStringClosingOnFirstLine in
    %     readtomlArrayTest confirms that input parses correctly.

    methods(Access = private)
        function file = writeToml(testCase, text)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "in.toml");
            writelines(text, file);
        end
    end

    methods(Test)
        % --- Number formats ------------------------------------------------

        function testHexadecimalInteger(testCase)
            file = testCase.writeToml("value = 0xFF");

            testCase.verifyEqual(readtoml(file).value, 255);
        end

        function testOctalInteger(testCase)
            file = testCase.writeToml("value = 0o755");

            testCase.verifyEqual(readtoml(file).value, 493);
        end

        function testBinaryInteger(testCase)
            file = testCase.writeToml("value = 0b1010");

            testCase.verifyEqual(readtoml(file).value, 10);
        end

        function testUnderscoreSeparatorsAreStripped(testCase)
            file = testCase.writeToml("value = 1_000_000");

            testCase.verifyEqual(readtoml(file).value, 1e6);
        end

        function testUnparseableNumberErrors(testCase)
            % An unquoted bare word is not valid TOML; it reaches the number
            % parser and fails there.
            file = testCase.writeToml("value = abc");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidNumber");
        end

        % --- Strings -------------------------------------------------------

        function testMultilineLiteralString(testCase)
            % The space before the delimiter leaks a stray apostrophe into
            % the value (#42), so this only checks that the lines survive.
            % readtomlMultilineStringTest covers the delimiter handling.
            file = testCase.writeToml([...
                "text = '''"; ...
                "line one"; ...
                "line two'''"]);

            config = readtoml(file);

            testCase.verifySubstring(config.text, "line one");
            testCase.verifySubstring(config.text, "line two");
        end

        function testLiteralStringSkipsEscapes(testCase)
            % Single-quoted strings take no escape processing.
            file = testCase.writeToml("path = 'C:\temp\new'");

            testCase.verifyEqual(readtoml(file).path, "C:\temp\new");
        end

        function testEscapeSequencesAreUnescaped(testCase)
            file = testCase.writeToml("text = ""a\tb\nc""");

            config = readtoml(file);

            testCase.verifySubstring(config.text, sprintf("\t"));
            testCase.verifySubstring(config.text, newline);
        end

        function testUnterminatedStringErrors(testCase)
            file = testCase.writeToml("text = ""unclosed");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidString");
        end

        % --- Datetimes -----------------------------------------------------

        function testLocalTimeIsParsed(testCase)
            file = testCase.writeToml("at = 07:32:00");

            testCase.verifyClass(readtoml(file).at, "datetime");
        end

        function testOffsetDatetimeIsParsed(testCase)
            file = testCase.writeToml("at = 1979-05-27T07:32:00Z");

            config = readtoml(file);

            testCase.verifyClass(config.at, "datetime");
            testCase.verifyEqual(config.at.TimeZone, 'UTC', ...
                "An explicit offset should be retained as a time zone");
        end

        function testDateLikeValueThatCannotParseErrors(testCase)
            % Matches the date shape, so datetime parsing is attempted, but
            % every candidate format fails.
            file = testCase.writeToml("at = 2020-99-99T99:99:99");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidDatetime");
        end

        function testTimeLikeValueThatCannotParseErrors(testCase)
            file = testCase.writeToml("at = 99:99:99");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidDatetime");
        end

        % --- Inline tables -------------------------------------------------

        function testEmptyInlineTable(testCase)
            file = testCase.writeToml("section = {}");

            config = readtoml(file);

            testCase.verifyClass(config.section, "matlab.io.config.TOMLData");
            testCase.verifyEmpty(keys(config.section), ...
                "An empty inline table should have no keys");
        end

        function testInlineTableEntryWithoutEqualsErrors(testCase)
            file = testCase.writeToml("section = {bare}");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidInlineTable");
        end

        function testUnclosedInlineTableErrors(testCase)
            % The value is accumulated to the end of the file and still has
            % no closing brace, so the syntax guard rejects it.
            file = testCase.writeToml("section = {bare = 1");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidInlineTable");
        end

        function testUnclosedArrayErrors(testCase)
            file = testCase.writeToml("items = [1, 2");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArray");
        end

        function testInlineTableWithMultipleEntries(testCase)
            file = testCase.writeToml("server = {host = ""alpha"", port = 80}");

            config = readtoml(file);

            testCase.verifyEqual(config.server.host, "alpha");
            testCase.verifyEqual(config.server.port, 80);
        end

        % --- Nested arrays of tables ---------------------------------------

        function testArrayOfTablesNestedInArrayOfTables(testCase)
            % The [[jobs.steps]] shape, where the parent is itself an array
            % of tables, so each job gets its own steps array.
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "name = ""build"""; ...
                "[[jobs.steps]]"; ...
                "run = ""make"""; ...
                "[[jobs.steps]]"; ...
                "run = ""test"""; ...
                "[[jobs]]"; ...
                "name = ""deploy"""; ...
                "[[jobs.steps]]"; ...
                "run = ""ship"""]);

            config = readtoml(file);

            testCase.verifyNumElements(config.jobs, 2);
            firstJob = config.jobs(1);
            secondJob = config.jobs(2);
            testCase.verifyEqual(firstJob.name, "build");
            testCase.verifyNumElements(firstJob.steps, 2, ...
                "Steps should attach to the job they follow");
            testCase.verifyEqual(firstJob.steps(1).run, "make");
            testCase.verifyEqual(firstJob.steps(2).run, "test");
            testCase.verifyEqual(secondJob.name, "deploy");
            testCase.verifyNumElements(secondJob.steps, 1, ...
                "The second job should not inherit the first job's steps");
            testCase.verifyEqual(secondJob.steps(1).run, "ship");
        end

        function testDeepSubtablePathInsideArrayOfTables(testCase)
            % A subtable two levels below the array element creates both
            % intermediate tables.
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "name = ""build"""; ...
                "[jobs.env.vars]"; ...
                "level = 1"]);

            config = readtoml(file);

            job = config.jobs;
            testCase.verifyEqual(keys(job), ["name", "env"]);
            testCase.verifyEqual(job.env.vars.level, 1);
        end

        function testPlainTableHeaderMatchingArrayPath(testCase)
            % A [products] header after [[products]] adds keys to the
            % current array element rather than starting a new table.
            file = testCase.writeToml([...
                "[[products]]"; ...
                "name = ""alpha"""; ...
                "[products]"; ...
                "extra = 1"]);

            config = readtoml(file);

            testCase.verifyNumElements(config.products, 1, ...
                "No new element should be appended");
            testCase.verifyEqual(keys(config.products), ["name", "extra"]);
            testCase.verifyEqual(config.products.extra, 1);
        end

        % --- Bracket tracking inside quotes --------------------------------

        function testBracketInsideQuotedArrayElement(testCase)
            % A closing bracket inside a quoted string must not be counted
            % when tracking how far a multi-line array extends.
            file = testCase.writeToml([...
                "items = ["; ...
                "  ""x]y"","; ...
                "  ""z"""; ...
                "]"]);

            config = readtoml(file);

            testCase.verifyEqual(config.items, ["x]y"; "z"], ...
                "The quoted bracket should be part of the value");
        end

        function testNestedBracketsOnTheOpeningLine(testCase)
            % Depth tracking on the first line must handle nested brackets
            % as well as quoted ones.
            file = testCase.writeToml([...
                "items = [ [""x]y""],"; ...
                "          [""z""] ]"]);

            config = readtoml(file);

            testCase.verifyNumElements(config.items, 2, ...
                "Both nested arrays should be collected");
        end

        % --- Empty arrays --------------------------------------------------

        function testArrayOfOnlyWhitespaceIsEmpty(testCase)
            file = testCase.writeToml("items = [ ]");

            testCase.verifyEmpty(readtoml(file).items);
        end

        % --- Unreadable file -----------------------------------------------

        function testUnopenableFileErrors(testCase)
            file = testCase.writeToml("host = ""local""");
            testCase.assertEqual(system("chmod 000 """ + file + """"), 0, ...
                "Could not change the file permissions");
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            % Skip where the process can read regardless of mode, such as
            % when the suite runs as root.
            testCase.assumeError(@() fileread(file), ?MException, ...
                "The file is still readable, so this path cannot be reached");

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:FileOpenError");
        end
    end
end

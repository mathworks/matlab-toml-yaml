classdef readtomlArrayTest < matlab.unittest.TestCase
    % Tests for readtoml paths the main tomltest suite does not reach: the
    % DatetimeType option, array element type consolidation, nested arrays
    % of tables, multiline strings, and the malformed-input error paths.

    methods(Access = private)
        function file = writeToml(testCase, text)
            import matlab.unittest.fixtures.TemporaryFolderFixture
            fixture = testCase.applyFixture(TemporaryFolderFixture);
            file = fullfile(fixture.Folder, "in.toml");
            writelines(text, file);
        end
    end

    methods(Test)
        % --- DatetimeType option -----------------------------------------

        function testDatetimeTypeDefaultsToDatetime(testCase)
            % Unlike readyaml, readtoml defaults to datetime, and TOMLData
            % stores datetime natively so the value survives.
            file = testCase.writeToml("created = 1979-05-27T07:32:00");

            config = readtoml(file);

            testCase.verifyClass(config.created, "datetime");
            testCase.verifyEqual(config.created, ...
                datetime(1979, 5, 27, 7, 32, 0));
        end

        function testDatetimeTypeStringKeepsRawText(testCase)
            file = testCase.writeToml("created = 1979-05-27T07:32:00");

            config = readtoml(file, "DatetimeType", "string");

            testCase.verifyClass(config.created, "string", ...
                "DatetimeType=string should skip datetime conversion");
        end

        function testLocalDateIsParsed(testCase)
            file = testCase.writeToml("created = 1979-05-27");

            config = readtoml(file);

            testCase.verifyClass(config.created, "datetime");
            testCase.verifyEqual(config.created, datetime(1979, 5, 27));
        end

        % --- Array element consolidation ----------------------------------

        function testEmptyArrayIsEmpty(testCase)
            file = testCase.writeToml("items = []");

            config = readtoml(file);

            testCase.verifyEmpty(config.items, ...
                "An empty TOML array should read as empty");
        end

        function testNumericArrayBecomesColumnVector(testCase)
            % readtoml returns arrays as column vectors.
            file = testCase.writeToml("ports = [80, 443, 8080]");

            testCase.verifyEqual(readtoml(file).ports, [80; 443; 8080]);
        end

        function testStringArrayBecomesStringArray(testCase)
            file = testCase.writeToml("hosts = [""a"", ""b""]");

            config = readtoml(file);

            testCase.verifyClass(config.hosts, "string");
            testCase.verifyEqual(config.hosts, ["a"; "b"]);
        end

        function testMixedTypeArrayStaysCell(testCase)
            % Elements of differing classes cannot form a homogeneous array,
            % so the parser keeps them in a cell.
            file = testCase.writeToml("mixed = [1, ""two""]");

            config = readtoml(file);

            testCase.verifyClass(config.mixed, "cell", ...
                "A mixed-type array should stay a cell array");
            testCase.verifyEqual(config.mixed{1}, 1);
            testCase.verifyEqual(config.mixed{2}, "two");
        end

        function testArrayOfInlineTablesBecomesObjectArray(testCase)
            file = testCase.writeToml("points = [{x = 1}, {x = 2}]");

            config = readtoml(file);

            testCase.verifyClass(config.points, "matlab.io.config.TOMLData");
            testCase.verifyNumElements(config.points, 2);
            testCase.verifyEqual(config.points(1).x, 1);
            testCase.verifyEqual(config.points(2).x, 2);
        end

        function testMultilineArray(testCase)
            % An array may span lines, with a trailing comma before the
            % closing bracket.
            file = testCase.writeToml([...
                "ports = ["; ...
                "  80,"; ...
                "  443,"; ...
                "]"]);

            testCase.verifyEqual(readtoml(file).ports, [80; 443]);
        end

        function testMultilineArrayWithBlankAndCommentLines(testCase)
            % Lines that are entirely blank or entirely a comment are
            % skipped while accumulating the value.
            file = testCase.writeToml([...
                "ports = ["; ...
                "  # the http ports"; ...
                ""; ...
                "  80,"; ...
                "  443"; ...
                "]"]);

            testCase.verifyEqual(readtoml(file).ports, [80; 443]);
        end

        function testMultilineArrayWithTrailingCommentErrors(testCase)
            % Issue #37: a comment at the end of a continuation line is not
            % stripped, so the commented-out text is spliced into the value
            % and the bracket-depth scan stops early. Valid TOML. Invert
            % this assertion when #37 is fixed.
            file = testCase.writeToml([...
                "ports = ["; ...
                "  80,   # http"; ...
                "  443,"; ...
                "]"]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArray", ...
                "Issue #37: trailing comments inside multi-line arrays fail");
        end

        function testMultilineInlineTable(testCase)
            % The same accumulator handles inline tables spanning lines.
            file = testCase.writeToml([...
                "server = {"; ...
                "  host = ""alpha"","; ...
                "  port = 80"; ...
                "}"]);

            config = readtoml(file);

            testCase.verifyEqual(config.server.host, "alpha");
            testCase.verifyEqual(config.server.port, 80);
        end

        % --- Arrays of tables ---------------------------------------------

        function testArrayOfTables(testCase)
            file = testCase.writeToml([...
                "[[products]]"; ...
                "name = ""alpha"""; ...
                ""; ...
                "[[products]]"; ...
                "name = ""beta"""]);

            config = readtoml(file);

            testCase.verifyNumElements(config.products, 2);
            testCase.verifyEqual(config.products(1).name, "alpha");
            testCase.verifyEqual(config.products(2).name, "beta");
        end

        function testNestedArrayOfTables(testCase)
            % An array of tables at a dotted path exercises the nested
            % branch, which resolves the parent before appending.
            file = testCase.writeToml([...
                "[[servers.web]]"; ...
                "host = ""alpha"""; ...
                ""; ...
                "[[servers.web]]"; ...
                "host = ""beta"""]);

            config = readtoml(file);

            testCase.verifyNumElements(config.servers.web, 2);
            testCase.verifyEqual(config.servers.web(1).host, "alpha");
            testCase.verifyEqual(config.servers.web(2).host, "beta");
        end

        function testSubtableInsideArrayOfTables(testCase)
            file = testCase.writeToml([...
                "[[products]]"; ...
                "name = ""alpha"""; ...
                ""; ...
                "[products.meta]"; ...
                "sku = 1"]);

            config = readtoml(file);

            testCase.verifyEqual(config.products(1).meta.sku, 1, ...
                "A subtable should attach to the current array element");
        end

        % --- Multiline strings --------------------------------------------

        function testMultilineBasicString(testCase)
            file = testCase.writeToml([...
                "text = """""""; ...
                "line one"; ...
                "line two"""""""]);

            config = readtoml(file);

            testCase.verifySubstring(config.text, "line one");
            testCase.verifySubstring(config.text, "line two");
        end

        function testMultilineStringClosingOnFirstLine(testCase)
            file = testCase.writeToml("text = """"""all on one line""""""");

            testCase.verifyEqual(readtoml(file).text, "all on one line");
        end

        % --- Malformed input ----------------------------------------------

        function testLineWithoutEqualsErrors(testCase)
            file = testCase.writeToml(["valid = 1"; "garbage"]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidSyntax", ...
                "A non key-value line should be reported as invalid syntax");
        end

        function testArrayOfTablesOverExistingScalarErrors(testCase)
            % Redefining a plain key as an array of tables is invalid TOML.
            file = testCase.writeToml([...
                "products = 1"; ...
                ""; ...
                "[[products]]"; ...
                "name = ""alpha"""]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables", ...
                "Reusing a scalar key as an array of tables should error");
        end
    end
end

classdef tTOMLMetadata < ConfigurationFileTestCase
    % Tests for TOML metadata: reading format info (hex/oct/bin integers,
    % scientific floats, literal strings, comments, inline tables),
    % round-tripping through getformat/setformat, and writer consumption.

    methods (Test)
        % --- Reader populates metadata ---

        function testHexIntegerMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "color = 0xFF0000");

            data = readtoml(file);

            meta = getformat(data, "color");
            testCase.verifyEqual(meta.IntegerFormat, "hex");
        end

        function testOctalIntegerMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "permissions = 0o755");

            data = readtoml(file);

            meta = getformat(data, "permissions");
            testCase.verifyEqual(meta.IntegerFormat, "oct");
        end

        function testBinaryIntegerMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "flags = 0b11010110");

            data = readtoml(file);

            meta = getformat(data, "flags");
            testCase.verifyEqual(meta.IntegerFormat, "bin");
        end

        function testScientificFloatMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "threshold = 1.5e-3");

            data = readtoml(file);

            meta = getformat(data, "threshold");
            testCase.verifyEqual(meta.FloatFormat, "scientific");
        end

        function testLiteralStringMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "path = 'C:\Users\Data'");

            data = readtoml(file);

            meta = getformat(data, "path");
            testCase.verifyEqual(meta.ScalarStyle, "single-quoted");
        end

        function testCommentMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                ["# Main port", "port = 8080"]);

            data = readtoml(file);

            meta = getformat(data, "port");
            testCase.verifyGreaterThan(numel(meta.Comments), 0);
            testCase.verifySubstring(meta.Comments(1), "Main port");
        end

        function testInlineTableMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "point = {x = 1, y = 2}");

            data = readtoml(file);

            nested = data.point;
            nodeMeta = getmetadata(nested);
            testCase.verifyEqual(nodeMeta.TableFormat, "inline");
            testCase.verifyEqual(nodeMeta.ContainerStyle, "flow");
        end

        function testFlowArrayMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "ports = [8080, 8443, 9000]");

            data = readtoml(file);

            meta = getformat(data, "ports");
            testCase.verifyEqual(meta.ContainerStyle, "flow");
        end

        function testDecIntegerHasDefaultMetadata(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "count = 42");

            data = readtoml(file);

            meta = getformat(data, "count");
            testCase.verifyEqual(meta.IntegerFormat, "dec");
        end

        % --- setformat / getformat ---

        function testSetFormatIntegerFormat(testCase)
            data = tomldata(struct("color", 255));

            data = setformat(data, "color", IntegerFormat="hex");

            meta = getformat(data, "color");
            testCase.verifyEqual(meta.IntegerFormat, "hex");
        end

        function testSetFormatFloatFormat(testCase)
            data = tomldata(struct("threshold", 0.0015));

            data = setformat(data, "threshold", FloatFormat="scientific");

            meta = getformat(data, "threshold");
            testCase.verifyEqual(meta.FloatFormat, "scientific");
        end

        function testSetFormatLiteralString(testCase)
            data = tomldata(struct("path", "C:\Users"));

            data = setformat(data, "path", ScalarStyle="single-quoted");

            meta = getformat(data, "path");
            testCase.verifyEqual(meta.ScalarStyle, "single-quoted");
        end

        function testSetFormatComments(testCase)
            data = tomldata(struct("port", 8080));

            data = setformat(data, "port", Comments="# Server port");

            meta = getformat(data, "port");
            testCase.verifyEqual(meta.Comments, "# Server port");
        end

        function testResetFormatClearsMetadata(testCase)
            data = tomldata(struct("color", 255));
            data = setformat(data, "color", IntegerFormat="hex");

            data = resetformat(data, "color");

            meta = getformat(data, "color");
            testCase.verifyEqual(meta.IntegerFormat, "dec");
        end

        function testGetFormatSummaryTable(testCase)
            data = tomldata(struct("a", 1, "b", "text", "c", 3.14));
            data = setformat(data, "a", IntegerFormat="hex");

            tbl = getformat(data);

            testCase.verifyClass(tbl, "table");
            testCase.verifyEqual(height(tbl), 3);
        end

        % --- Writer consumes metadata ---

        function testHexIntegerRoundTrip(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "color = 0xFF");

            data = readtoml(file);
            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "0x");
        end

        function testScientificFloatRoundTrip(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "threshold = 1.5e-3");

            data = readtoml(file);
            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(lower(text), "e");
        end

        function testLiteralStringRoundTrip(testCase)
            file = testCase.writeTempFile("test.toml", ...
                "path = 'C:\Users\Data'");

            data = readtoml(file);
            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "'C:\Users\Data'");
        end

        function testCommentRoundTrip(testCase)
            file = testCase.writeTempFile("test.toml", ...
                ["# Server config", "port = 8080"]);

            data = readtoml(file);
            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "# Server config");
        end

        function testSetFormatHexAffectsWriter(testCase)
            data = tomldata(struct("color", 255));
            data = setformat(data, "color", IntegerFormat="hex");

            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "0x");
        end

        function testSetFormatScientificAffectsWriter(testCase)
            data = tomldata(struct("threshold", 0.0015));
            data = setformat(data, "threshold", FloatFormat="scientific");

            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(lower(text), "e");
        end

        function testSetFormatLiteralAffectsWriter(testCase)
            data = tomldata(struct("path", "C:\Users\Data"));
            data = setformat(data, "path", ScalarStyle="single-quoted");

            outFile = testCase.tempFile("out.toml");
            writetoml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "'C:\Users\Data'");
        end

        function testMetadataPreservedThroughNestedRead(testCase)
            file = testCase.writeTempFile("test.toml", ...
                ["[settings]", ...
                "color = 0xFF", ...
                "threshold = 1.5e-3", ...
                "path = 'C:\temp'"]);

            data = readtoml(file);

            colorMeta = getformat(data.settings, "color");
            testCase.verifyEqual(colorMeta.IntegerFormat, "hex");

            threshMeta = getformat(data.settings, "threshold");
            testCase.verifyEqual(threshMeta.FloatFormat, "scientific");

            pathMeta = getformat(data.settings, "path");
            testCase.verifyEqual(pathMeta.ScalarStyle, "single-quoted");
        end
    end
end

classdef readtomlMultilineStringTest < ConfigurationFileTestCase
    % Tests for readtoml multi-line basic ("""...""") and literal
    % ('''...''') strings, including the newline trimmed after the opening
    % delimiter.
    %
    % Issue #42: the content offset is measured from the untrimmed text after
    % "=", so whitespace before the opening delimiter shifts it. The tests
    % below spell the key with no space before the delimiter, which is the
    % only spelling that parses correctly today. The two tests at the end pin
    % the buggy spellings so the fix has to update them.

    properties(Constant, Access = private)
        % Written as char so the delimiters read as themselves rather than
        % as a run of doubled quotes.
        BasicDelimiter = string('"""')
        LiteralDelimiter = string('''''''')
    end

    methods(Access = private)
        function file = writeToml(testCase, text)
            file = testCase.writeTempFile("in.toml", text);
        end
    end

    methods(Test)
        function testBasicStringTrimsNewlineAfterDelimiter(testCase)
            % Per the TOML spec, a newline immediately after the opening
            % delimiter is not part of the value.
            file = testCase.writeToml([...
                "text=" + testCase.BasicDelimiter; ...
                "line one"; ...
                "line two" + testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, "line one" + newline + "line two");
        end

        function testLiteralStringTrimsNewlineAfterDelimiter(testCase)
            file = testCase.writeToml([...
                "text=" + testCase.LiteralDelimiter; ...
                "line one"; ...
                "line two" + testCase.LiteralDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, "line one" + newline + "line two");
        end

        function testLiteralStringKeepsBackslashes(testCase)
            % Literal strings take no escape processing, even across lines.
            file = testCase.writeToml([...
                "text=" + testCase.LiteralDelimiter; ...
                "C:\temp"; ...
                "C:\logs" + testCase.LiteralDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, "C:\temp" + newline + "C:\logs");
        end

        function testBasicStringUnescapesAcrossLines(testCase)
            file = testCase.writeToml([...
                "text=" + testCase.BasicDelimiter; ...
                "a\tb"; ...
                "c" + testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, ...
                "a" + sprintf("\t") + "b" + newline + "c");
        end

        function testContentOnTheOpeningLineIsKept(testCase)
            % No newline follows the delimiter here, so nothing is trimmed.
            file = testCase.writeToml([...
                "text=" + testCase.BasicDelimiter + "first"; ...
                "second" + testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, "first" + newline + "second");
        end

        function testStringClosingOnItsOwnLine(testCase)
            % The closing delimiter on its own line: the newline before it
            % is part of the value per the TOML spec.
            file = testCase.writeToml([...
                "text=" + testCase.BasicDelimiter; ...
                "only line"; ...
                testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, "only line" + newline);
        end

        function testSingleLineDelimitedStringIsNotAccumulated(testCase)
            % Opening and closing on one line skips the accumulator.
            file = testCase.writeToml("text=" + testCase.BasicDelimiter + ...
                "inline" + testCase.BasicDelimiter);

            testCase.verifyEqual(readtoml(file).text, "inline");
        end

        % --- Issue #42 -----------------------------------------------------

        function testSpaceBeforeDelimiterParsesCorrectly(testCase)
            % Issue #42 (fixed): a space before the opening delimiter no
            % longer leaks a stray quote into the value.
            file = testCase.writeToml([...
                "text = " + testCase.BasicDelimiter; ...
                "line one"; ...
                "line two" + testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, ...
                "line one" + newline + "line two");
        end

        function testWideGapBeforeDelimiterParsesCorrectly(testCase)
            % Issue #42 (fixed): a wide gap before the opening delimiter no
            % longer crashes the parser.
            file = testCase.writeToml([...
                "text =   " + testCase.BasicDelimiter; ...
                "line one"; ...
                "line two" + testCase.BasicDelimiter]);

            config = readtoml(file);

            testCase.verifyEqual(config.text, ...
                "line one" + newline + "line two");
        end
    end
end

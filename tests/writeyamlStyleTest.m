classdef writeyamlStyleTest < ConfigurationFileTestCase
    % Tests for writeyaml formatting paths: flow-style cell arrays, nested
    % mapping values, and section spacing.

    methods(Access = private)
        function text = writeAndRead(testCase, data, varargin)
            file = testCase.tempFile("out.yaml");
            writeyaml(data, file, varargin{:});
            text = string(fileread(file));
        end
    end

    methods(Test)
        % --- Flow style ----------------------------------------------------

        function testCellArrayInFlowStyle(testCase)
            data = struct("items", {{1, 2, 3}});

            text = testCase.writeAndRead(data, "ArrayStyle", "flow");

            testCase.verifySubstring(text, "[1,2,3]", ...
                "A cell array should render inline in flow style");
        end

        function testMixedCellArrayInFlowStyle(testCase)
            data = struct("items", {{1, "two", true}});

            text = testCase.writeAndRead(data, "ArrayStyle", "flow");

            testCase.verifySubstring(text, "[", ...
                "Mixed cell contents should still render inline");
            testCase.verifySubstring(text, "two");
            testCase.verifyFalse(contains(text, "- "), ...
                "Flow style should not emit block sequence dashes");
        end

        function testCellArrayInBlockStyleUsesDashes(testCase)
            data = struct("items", {{1, 2}});

            text = testCase.writeAndRead(data, "ArrayStyle", "block");

            testCase.verifySubstring(text, "- 1", ...
                "Block style is the default rendering for sequences");
        end

        % --- Section spacing and nested values -----------------------------

        function testSingleKeyUsesSingleNewlineSeparator(testCase)
            % With only one top-level key there is no section separator to
            % add, so the loose spacing branch is skipped.
            data = struct("host", "example.com");

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "host: example.com");
        end

        function testNestedStructValueGoesOnItsOwnLines(testCase)
            % A value that is itself a mapping is written as an indented
            % block under its key rather than inline.
            data = struct("database", struct("port", 8080));

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "database:", ...
                "The outer key should be followed by a block");
            testCase.verifySubstring(text, "port: 8080", ...
                "The nested contents should be written");
            lines = splitlines(strtrim(text));
            testCase.verifyNumElements(lines, 2, ...
                "The nested value should be on its own line");
            testCase.verifyTrue(startsWith(lines(2), " "), ...
                "The nested key should be indented");
        end

        function testNestedObjectValueInsideDictionaryGoesOnItsOwnLines(testCase)
            inner = yamldata();
            inner.port = 8080;
            data = dictionary(string.empty, cell.empty);
            data("database") = {inner};

            text = testCase.writeAndRead(data);

            testCase.verifySubstring(text, "database:");
            testCase.verifySubstring(text, "port: 8080");
        end

        function testMultipleKeysWithLooseSpacing(testCase)
            data = struct("alpha", 1, "beta", 2);

            text = testCase.writeAndRead(data, "SectionSpacing", "loose");

            testCase.verifySubstring(text, "alpha: 1" + newline + newline, ...
                "Loose spacing should separate top-level keys by a blank line");
        end

        function testMultipleKeysWithCompactSpacing(testCase)
            data = struct("alpha", 1, "beta", 2);

            text = testCase.writeAndRead(data, "SectionSpacing", "compact");

            testCase.verifyFalse(contains(text, string(newline) + newline), ...
                "Compact spacing should not add blank lines");
        end
    end
end

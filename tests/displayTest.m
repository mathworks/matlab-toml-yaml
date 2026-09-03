classdef displayTest < matlab.unittest.TestCase
    % Tests for the display paths: show(), which prints values in the
    % object's native file format, and disp(), which prints the key
    % hierarchy with MATLAB types.
    %
    % Display text is matched with substrings rather than exact strings so
    % these tests do not break on incidental formatting changes. Class names
    % are hyperlinked in headers, so assertions avoid text adjacent to them.

    methods(Access = private)
        function config = makeYAML(~)
            config = yamldata();
            config.host = "example.com";
            config.port = 8080;
        end

        function config = makeTOML(~)
            config = tomldata();
            config.host = "example.com";
            config.port = 8080;
        end
    end

    methods(Test)
        % --- show: scalar objects ---------------------------------------

        function testShowPrintsYAMLSyntax(testCase)
            config = testCase.makeYAML();

            output = evalc('show(config)');

            testCase.verifySubstring(output, "host: example.com", ...
                "show on a YAMLData object should print YAML syntax");
            testCase.verifySubstring(output, "port: 8080");
        end

        function testShowPrintsTOMLSyntax(testCase)
            config = testCase.makeTOML();

            output = evalc('show(config)');

            testCase.verifySubstring(output, 'host = "example.com"', ...
                "show on a TOMLData object should print TOML syntax");
            testCase.verifySubstring(output, "port = 8080");
        end

        function testShowPrintsNestedYAMLStructure(testCase)
            config = yamldata();
            config.database.host = "localhost";

            output = evalc('show(config)');

            testCase.verifySubstring(output, "database:");
            testCase.verifySubstring(output, "host: localhost");
        end

        function testShowOnEmptyObjectDoesNotError(testCase)
            config = yamldata();

            output = evalc('show(config)');

            testCase.verifyEqual(strtrim(output), '{}', ...
                "An empty object should show as empty mapping");
        end

        % --- show: object arrays ----------------------------------------

        function testShowOnYAMLArrayWrapsUnderItem(testCase)
            % An object array is not a valid document on its own, so
            % showAsFormat wraps it in a single-key object named "item".
            first = yamldata();
            first.a = 1;
            second = yamldata();
            second.a = 2;
            configs = [first, second];

            output = evalc('show(configs)');

            testCase.verifySubstring(output, "item:", ...
                "An array should be wrapped under an 'item' key");
            testCase.verifySubstring(output, "a: 1");
            testCase.verifySubstring(output, "a: 2");
        end

        function testShowOnTOMLArrayWrapsUnderItemTableArray(testCase)
            first = tomldata();
            first.id = 1;
            second = tomldata();
            second.id = 2;
            configs = [first, second];

            output = evalc('show(configs)');

            testCase.verifySubstring(output, "[[item]]", ...
                "A TOML array should be wrapped as an array of tables");
            testCase.verifySubstring(output, "id = 1");
            testCase.verifySubstring(output, "id = 2");
        end

        % --- show: fallback ---------------------------------------------

        function testShowFallsBackToDispWhenWriterFails(testCase)
            % showAsFormat writes to a temp file to render the value view.
            % If the writer cannot serialize the data it must degrade to the
            % key listing rather than propagating the error to the user.
            config = testCase.makeYAML();
            failingWriter = @(varargin) error("displayTest:boom", "boom");

            output = evalc(...
                "matlab.io.config.internal.showAsFormat(config, failingWriter)");

            testCase.verifySubstring(output, "with keys:", ...
                "A failing writer should fall back to the disp output");
            testCase.verifySubstring(output, "host");
        end

        % --- disp: headers ----------------------------------------------

        function testDispHeaderReportsKeys(testCase)
            config = testCase.makeYAML();

            output = evalc('disp(config)');

            testCase.verifySubstring(output, "with keys:", ...
                "The header should say 'keys', not 'properties'");
        end

        function testDispHeaderForEmptyObjectReportsNoKeys(testCase)
            config = yamldata();

            output = evalc('disp(config)');

            testCase.verifySubstring(output, "with no keys", ...
                "An object with no keys should say so in the header");
        end

        function testDispHeaderForArrayReportsDimensions(testCase)
            config = testCase.makeYAML();
            configs = [config, config];

            output = evalc('disp(configs)');

            testCase.verifySubstring(output, "array with keys:", ...
                "An object array header should identify itself as an array");
        end

        % --- disp: nested compact representation ------------------------

        function testNestedScalarObjectShowsKeyCount(testCase)
            % A nested object is summarized rather than expanded inline.
            config = yamldata();
            config.database.host = "localhost";
            config.database.port = 5432;

            output = evalc('disp(config)');

            testCase.verifySubstring(output, ...
                sprintf("[1%s1 YAMLData with 2 keys]", char(215)), ...
                "A nested scalar object should show its key count");
        end

        function testNestedScalarObjectWithOneKeyUsesSingularKey(testCase)
            config = yamldata();
            config.database.host = "localhost";

            output = evalc('disp(config)');

            testCase.verifySubstring(output, ...
                sprintf("[1%s1 YAMLData with 1 key]", char(215)), ...
                "A single key should be reported as 'key', not 'keys'");
        end

        function testNestedObjectArrayShowsDimensionsOnly(testCase)
            % The non-scalar compact representation reports size instead of
            % a key count, since elements can have differing keys.
            first = yamldata();
            first.id = 1;
            second = yamldata();
            second.id = 2;
            config = yamldata();
            config.items = [first, second];

            output = evalc('disp(config)');

            testCase.verifySubstring(output, "YAMLData]", ...
                "A nested object array should be summarized by class");
            testCase.verifyTrue(...
                contains(output, sprintf("2%s1 YAMLData]", char(215))) || ...
                contains(output, sprintf("1%s2 YAMLData]", char(215))), ...
                "A nested object array should report its dimensions");
        end

        function testCompactColumnRepresentation(testCase)
            % compactRepresentationForColumn was redefined to hide the
            % method - cover that code with a test.
            t = table(yamldata());

            output = evalc('disp(t)');

            testCase.verifySubstring(output, "1 YAMLData");
        end

        function testNestedTOMLObjectUsesShortClassName(testCase)
            config = tomldata();
            config.database.host = "localhost";

            output = evalc('disp(config)');

            testCase.verifySubstring(output, "TOMLData with 1 key]", ...
                "The compact representation should use the short class name");
        end

        % --- disp: colon alignment with special-character keys ----------

        function testColonsAlignWithMangledKeyNames(testCase)
            config = yamldata();
            config.("host") = "localhost";
            config.("123-key") = "value";

            output = evalc('disp(config)');

            lines = splitlines(output);
            colonPositions = [];
            for i = 1:numel(lines)
                idx = strfind(lines{i}, ':');
                if ~isempty(idx) && contains(lines{i}, 'host') || ...
                        contains(lines{i}, '123-key')
                    colonPositions(end+1) = idx(1); %#ok<AGROW>
                end
            end
            testCase.verifyGreaterThanOrEqual(numel(colonPositions), 2, ...
                "Should find at least two key lines with colons");
            testCase.verifyEqual(numel(unique(colonPositions)), 1, ...
                "Colons should align to the same column");
        end

        % --- show: writerArgs forwarded on scalar path ------------------

        function testShowForwardsWriterArgsOnScalarPath(testCase)
            config = testCase.makeTOML();
            called = {};
            capturingWriter = @(varargin) captureArgs(varargin{:});

            function captureArgs(varargin)
                called = varargin;
                writelines("", varargin{2});
            end

            evalc('matlab.io.config.internal.showAsFormat(config, capturingWriter, {"TableStyle", "inline"})');

            testCase.verifyGreaterThan(numel(called), 2, ...
                "Writer should receive extra arguments on the scalar path");
        end
    end
end

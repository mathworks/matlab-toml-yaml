classdef formatMetadataTest < ConfigurationFileTestCase
    % Tests for format metadata: reading it from files, getformat,
    % setformat, resetformat, and preserving it when writing.

    methods (Access = private)
        function config = readTomlText(testCase, lines)
            config = readtoml(testCase.writeTempFile("in.toml", lines));
        end

        function config = readYamlText(testCase, lines)
            config = readyaml(testCase.writeTempFile("in.yaml", lines));
        end

        function text = writeTomlText(testCase, config)
            file = testCase.tempFile("out.toml");
            writetoml(config, file);
            text = string(fileread(file));
        end

        function text = writeYamlText(testCase, config)
            file = testCase.tempFile("out.yaml");
            writeyaml(config, file);
            text = string(fileread(file));
        end
    end

    methods (Test)
        % --- TOML reading ----------------------------------------------

        function testTomlHexIntegerFormat(testCase)
            config = testCase.readTomlText("mask = 0xFF");

            testCase.verifyEqual(getformat(config, "mask"), ...
                struct("IntegerFormat", "hex"));
            testCase.verifyEqual(config.mask, 255);
        end

        function testTomlLiteralString(testCase)
            config = testCase.readTomlText("path = 'C:\temp'");

            testCase.verifyEqual(getformat(config, "path"), ...
                struct("StringEscapeStyle", "literal"));
            testCase.verifyEqual(config.path, "C:\temp");
        end

        function testTomlMultilineString(testCase)
            config = testCase.readTomlText(["text = """""""; "a"; "b"""""""]);

            testCase.verifyEqual(getformat(config, "text"), ...
                struct("StringLayout", "multiline"));
        end

        function testTomlKeyComments(testCase)
            config = testCase.readTomlText(["# Server port"; "port = 80"]);

            testCase.verifyEqual(getformat(config, "port"), ...
                struct("Comments", "Server port"));
        end

        function testTomlTableHeaderComments(testCase)
            config = testCase.readTomlText([ ...
                "name = ""x"""; ""; "# Database"; "[db]"; "port = 1"]);

            testCase.verifyEqual(getformat(config, "db"), ...
                struct("Comments", "Database"));
        end

        function testTomlFileHeaderComments(testCase)
            config = testCase.readTomlText(["# File header"; ""; "a = 1"]);

            testCase.verifyEqual(getformat(config), ...
                struct("Comments", "File header"));
        end

        function testTomlInlineTable(testCase)
            config = testCase.readTomlText("point = {x = 1, y = 2}");

            testCase.verifyEqual(getformat(config, "point"), ...
                struct("TableStyle", "inline"));
            testCase.verifyEqual(config.point.y, 2);
        end

        function testTomlMultilineArray(testCase)
            config = testCase.readTomlText(["ports = ["; "  1,"; "  2,"; "]"]);

            testCase.verifyEqual(getformat(config, "ports"), ...
                struct("ArrayStyle", "block"));
            testCase.verifyEqual(config.ports, [1; 2]);
        end

        function testTomlInlineArrayOfTables(testCase)
            config = testCase.readTomlText("pts = [{x = 1}, {x = 2}]");

            testCase.verifyEqual(getformat(config, "pts"), ...
                struct("TableArrayStyle", "inline"));
            testCase.verifyEqual(config.pts(2).x, 2);
        end

        function testTomlNestedPath(testCase)
            config = testCase.readTomlText(["[server]"; "mask = 0x10"]);

            testCase.verifyEqual(getformat(config, "server.mask"), ...
                struct("IntegerFormat", "hex"));
        end

        function testTomlDefaultFormatHasNoMetadata(testCase)
            config = testCase.readTomlText(["a = 1"; "b = ""x"""; "c = [1, 2]"]);

            testCase.verifyEqual(getformat(config, "a"), struct());
            testCase.verifyEqual(getformat(config, "b"), struct());
            testCase.verifyEqual(getformat(config, "c"), struct());
        end

        function testTomlStyledArrayElementsKeepArrayType(testCase)
            config = testCase.readTomlText("masks = [0x1, 0x2]");

            testCase.verifyEqual(config.masks, [1; 2]);
        end

        % --- TOML writing ----------------------------------------------

        function testTomlRoundTripPreservesFormats(testCase)
            config = testCase.readTomlText([ ...
                "# File header"; ""; ...
                "# The mask"; "mask = 0xFF"; ...
                "path = 'C:\temp'"; ...
                "point = {x = 1}"; ...
                "pts = [{x = 1}, {x = 2}]"]);

            text = testCase.writeTomlText(config);

            testCase.verifySubstring(text, "# File header");
            testCase.verifySubstring(text, "# The mask" + newline + "mask = 0xFF");
            testCase.verifySubstring(text, "path = 'C:\temp'");
            testCase.verifySubstring(text, "point = {");
            testCase.verifySubstring(text, "pts = [");
        end

        function testTomlRoundTripPreservesGetformat(testCase)
            config = testCase.readTomlText([ ...
                "# The mask"; "mask = 0xFF"; "[server]"; "path = 'x'"]);

            reread = readtoml(testCase.writeTempFile("again.toml", ...
                testCase.writeTomlText(config)));

            testCase.verifyEqual(getformat(reread, "mask"), getformat(config, "mask"));
            testCase.verifyEqual(getformat(reread, "server.path"), ...
                getformat(config, "server.path"));
        end

        % --- YAML reading ----------------------------------------------

        function testYamlFlowSequence(testCase)
            config = testCase.readYamlText("items: [1, 2]");

            testCase.verifyEqual(getformat(config, "items"), ...
                struct("ContainerStyle", "flow"));
            testCase.verifyEqual(config.items, [1; 2]);
        end

        function testYamlFlowMapping(testCase)
            config = testCase.readYamlText("point: {x: 1, y: 2}");

            testCase.verifyEqual(getformat(config, "point"), ...
                struct("ContainerStyle", "flow"));
        end

        function testYamlQuotedScalar(testCase)
            config = testCase.readYamlText("name: 'alpha'");

            testCase.verifyEqual(getformat(config, "name"), ...
                struct("ScalarStyle", "single-quoted"));
            testCase.verifyEqual(config.name, "alpha");
        end

        function testYamlLiteralBlockScalar(testCase)
            config = testCase.readYamlText(["text: |"; "  line 1"; "  line 2"]);

            testCase.verifyEqual(getformat(config, "text"), ...
                struct("ScalarStyle", "literal"));
        end

        function testYamlQuotedKey(testCase)
            config = testCase.readYamlText("""my key"": 1");

            testCase.verifyEqual(getformat(config, "my key"), ...
                struct("KeyStyle", "double-quoted"));
        end

        function testYamlQuotedSequenceItemsConsolidate(testCase)
            config = testCase.readYamlText(["items:"; "  - ""a"""; "  - ""b"""]);

            testCase.verifyEqual(config.items, ["a"; "b"]);
        end

        % --- YAML writing ----------------------------------------------

        function testYamlRoundTripPreservesGetformat(testCase)
            config = testCase.readYamlText([ ...
                "name: 'alpha'"; "items: [1, 2]"; """my key"": 1"; ...
                "text: |"; "  line 1"]);

            reread = readyaml(testCase.writeTempFile("again.yaml", ...
                testCase.writeYamlText(config)));

            testCase.verifyEqual(getformat(reread, "name"), getformat(config, "name"));
            testCase.verifyEqual(getformat(reread, "items"), getformat(config, "items"));
            testCase.verifyEqual(getformat(reread, "my key"), getformat(config, "my key"));
            testCase.verifyEqual(getformat(reread, "text"), getformat(config, "text"));
            testCase.verifyEqual(struct(reread), struct(config));
        end

        function testYamlPlainStyleKeepsQuotesWhenNeeded(testCase)
            config = yamldata(struct("flag", "true"));
            config = setformat(config, "flag", ScalarStyle="plain");

            reread = readyaml(testCase.writeTempFile("again.yaml", ...
                testCase.writeYamlText(config)));

            testCase.verifyEqual(reread.flag, "true");
        end

        % --- setformat / resetformat -----------------------------------

        function testSetformatIntegerFormat(testCase)
            config = tomldata(struct("mask", 255));
            config = setformat(config, "mask", IntegerFormat="hex");

            text = testCase.writeTomlText(config);

            testCase.verifySubstring(text, "mask = 0xFF");
        end

        function testSetformatComments(testCase)
            config = tomldata(struct("port", 80));
            config = setformat(config, "port", Comments=["Line 1"; "Line 2"]);

            text = testCase.writeTomlText(config);

            testCase.verifySubstring(text, ...
                "# Line 1" + newline + "# Line 2" + newline + "port = 80");
        end

        function testSetformatNestedPath(testCase)
            config = tomldata(struct("server", struct("mask", 16)));
            config = setformat(config, "server.mask", IntegerFormat="hex");

            testCase.verifyEqual(getformat(config, "server.mask"), ...
                struct("IntegerFormat", "hex"));
        end

        function testSetformatTableLevel(testCase)
            config = tomldata(struct("a", 1));
            config = setformat(config, Comments="Header");

            testCase.verifyEqual(getformat(config), struct("Comments", "Header"));
        end

        function testSetformatAutoClears(testCase)
            config = tomldata(struct("mask", 255));
            config = setformat(config, "mask", IntegerFormat="hex");
            config = setformat(config, "mask", IntegerFormat="auto");

            testCase.verifyEqual(getformat(config, "mask"), struct());
        end

        function testSetformatYamlScalarStyle(testCase)
            config = yamldata(struct("name", "alpha"));
            config = setformat(config, "name", ScalarStyle="single-quoted");

            text = testCase.writeYamlText(config);

            testCase.verifySubstring(text, "name: 'alpha'");
        end

        function testSetformatYamlFlowSequence(testCase)
            config = yamldata(struct("items", [1; 2; 3]));
            config = setformat(config, "items", ContainerStyle="flow");

            text = testCase.writeYamlText(config);

            testCase.verifySubstring(text, "items: [");
        end

        function testSetformatInvalidPropertyForFormat(testCase)
            config = tomldata(struct("a", 1));

            testCase.verifyError(@() setformat(config, "a", ScalarStyle="plain"), ...
                "setformat:InvalidProperty");
        end

        function testSetformatInvalidValue(testCase)
            config = tomldata(struct("a", 1));

            testCase.verifyError(@() setformat(config, "a", IntegerFormat="base64"), ...
                "setformat:InvalidValue");
        end

        function testSetformatMissingKey(testCase)
            config = tomldata(struct("a", 1));

            testCase.verifyError(@() setformat(config, "b", IntegerFormat="hex"), ...
                "setformat:InvalidKey");
        end

        function testSetformatDoesNotChangeData(testCase)
            config = tomldata(struct("mask", 255, "list", [1; 2]));
            styled = setformat(config, "mask", IntegerFormat="hex");
            styled = setformat(styled, "list", ArrayStyle="block");

            testCase.verifyEqual(styled.mask, 255);
            testCase.verifyEqual(styled.list, [1; 2]);
            testCase.verifyTrue(isequaln(styled, config));
        end

        function testResetformatKey(testCase)
            config = testCase.readTomlText(["# c"; "mask = 0xFF"]);
            config = resetformat(config, "mask");

            testCase.verifyEqual(getformat(config, "mask"), struct());
        end

        function testResetformatAll(testCase)
            config = testCase.readTomlText(["# h"; ""; "# c"; "mask = 0xFF"]);
            config = resetformat(config);

            testCase.verifyEqual(getformat(config), struct());
            testCase.verifyEqual(getformat(config, "mask"), struct());
        end

        % --- Store behavior --------------------------------------------

        function testOverwriteKeepsKeyMetadataDropsValueFormat(testCase)
            config = testCase.readTomlText(["# c"; "mask = 0xFF"]);
            config.mask = 7;

            testCase.verifyEqual(getformat(config, "mask"), struct("Comments", "c"));
        end

        function testRemoveKeyRemovesMetadata(testCase)
            config = testCase.readTomlText(["# a"; "a = 1"; "# b"; "b = 2"]);
            config = rmfield(config, "a");
            config.a = 3;

            testCase.verifyEqual(getformat(config, "a"), struct());
            testCase.verifyEqual(getformat(config, "b"), struct("Comments", "b"));
        end
    end
end

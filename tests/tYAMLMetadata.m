classdef tYAMLMetadata < ConfigurationFileTestCase
    % Tests for YAML metadata: reading style info, round-tripping through
    % getformat/setformat, and verifying that writers consume metadata.

    methods (Test)
        % --- Reader populates metadata ---

        function testFlowSequenceMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                ["server:", "  ports: [8080, 8443, 9000]"]);

            data = readyaml(file);

            meta = getformat(data.server, "ports");
            testCase.verifyEqual(meta.ContainerStyle, "flow");
            testCase.verifyTrue(meta.IsArray);
        end

        function testFlowMapMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                ["server:", "  options: {timeout: 30, retries: 3}"]);

            data = readyaml(file);

            nested = data.server.options;
            nodeMeta = getmetadata(nested);
            testCase.verifyEqual(nodeMeta.ContainerStyle, "flow");
        end

        function testSingleQuotedScalarMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                "name: 'quoted-value'");

            data = readyaml(file);

            meta = getformat(data, "name");
            testCase.verifyEqual(meta.ScalarStyle, "single-quoted");
        end

        function testDoubleQuotedScalarMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                'name: "double-quoted"');

            data = readyaml(file);

            meta = getformat(data, "name");
            testCase.verifyEqual(meta.ScalarStyle, "double-quoted");
        end

        function testBlockSequenceHasNoExplicitMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                ["items:", "  - one", "  - two"]);

            data = readyaml(file);

            meta = getformat(data, "items");
            testCase.verifyEqual(meta.ContainerStyle, "block");
        end

        function testPlainScalarHasDefaultMetadata(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                "count: 42");

            data = readyaml(file);

            meta = getformat(data, "count");
            testCase.verifyEqual(meta.ScalarStyle, "auto");
        end

        % --- setformat / getformat ---

        function testSetFormatContainerStyle(testCase)
            data = yamldata(struct("ports", [80; 443; 8080]));

            data = setformat(data, "ports", ContainerStyle="flow", IsArray=true);

            meta = getformat(data, "ports");
            testCase.verifyEqual(meta.ContainerStyle, "flow");
            testCase.verifyTrue(meta.IsArray);
        end

        function testSetFormatScalarStyle(testCase)
            data = yamldata(struct("name", "example"));

            data = setformat(data, "name", ScalarStyle="single-quoted");

            meta = getformat(data, "name");
            testCase.verifyEqual(meta.ScalarStyle, "single-quoted");
        end

        function testResetFormatClearsMetadata(testCase)
            data = yamldata(struct("name", "example"));
            data = setformat(data, "name", ScalarStyle="literal");

            data = resetformat(data, "name");

            meta = getformat(data, "name");
            testCase.verifyEqual(meta.ScalarStyle, "auto");
        end

        function testGetFormatSummaryTable(testCase)
            data = yamldata(struct("a", 1, "b", "text", "c", [1;2;3]));
            data = setformat(data, "c", ContainerStyle="flow", IsArray=true);

            tbl = getformat(data);

            testCase.verifyClass(tbl, "table");
            testCase.verifyEqual(height(tbl), 3);
        end

        % --- Writer consumes metadata ---

        function testFlowSequenceRoundTrip(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                "ports: [8080, 8443, 9000]");

            data = readyaml(file);
            outFile = testCase.tempFile("out.yaml");
            writeyaml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "[8080,8443,9000]");
        end

        function testFlowMapRoundTrip(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                "options: {timeout: 30, retries: 3}");

            data = readyaml(file);
            outFile = testCase.tempFile("out.yaml");
            writeyaml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "{timeout: 30,retries: 3}");
        end

        function testSingleQuotedScalarRoundTrip(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                "name: 'my-app'");

            data = readyaml(file);
            outFile = testCase.tempFile("out.yaml");
            writeyaml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "'my-app'");
        end

        function testSetFormatAffectsWriterOutput(testCase)
            data = yamldata(struct("ports", [80; 443; 8080]));
            data = setformat(data, "ports", ContainerStyle="flow", IsArray=true);

            outFile = testCase.tempFile("out.yaml");
            writeyaml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "[80,443,8080]");
        end

        function testBlockSequenceIsDefault(testCase)
            data = yamldata(struct("items", [1; 2; 3]));

            outFile = testCase.tempFile("out.yaml");
            writeyaml(data, outFile);
            text = string(fileread(outFile));

            testCase.verifySubstring(text, "- 1");
            testCase.verifySubstring(text, "- 2");
        end

        function testMetadataPreservedThroughNestedRead(testCase)
            file = testCase.writeTempFile("test.yaml", ...
                ["server:", ...
                 "  host: localhost", ...
                 "  ports: [8080, 8443]", ...
                 "database:", ...
                 "  name: 'mydb'"]);

            data = readyaml(file);

            portsMeta = getformat(data.server, "ports");
            testCase.verifyEqual(portsMeta.ContainerStyle, "flow");

            nameMeta = getformat(data.database, "name");
            testCase.verifyEqual(nameMeta.ScalarStyle, "single-quoted");
        end
    end
end

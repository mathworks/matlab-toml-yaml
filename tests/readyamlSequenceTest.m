classdef readyamlSequenceTest < ConfigurationFileTestCase
    % Tests for readyaml paths inside sequence-of-mapping items: incomplete
    % keys, blank and unrecognized lines within an item, stray list markers,
    % indentless sequences, empty flow sequences, and the unreadable-file
    % error.
    %
    % Two regions of readyaml.m are deliberately not covered here because no
    % input can reach them:
    %   - The BOM strip (lines 78-82) tests for raw bytes that fileread has
    %     already decoded, so the condition is never true. See #35.
    %   - The ParseError wrapper (lines 68-70) catches failures from
    %     parseYAML, which is fully permissive: unmatched quotes, unclosed
    %     flow sequences, anchors, multiple documents, complex keys, merge
    %     keys, mixed-type sequences and 120-level nesting all parse without
    %     error. It is defensive code with no reachable trigger.

    methods(Access = private)
        function file = writeText(testCase, text)
            file = testCase.writeTempFile("in.yaml", text);
        end
    end

    methods(Test)
        % --- Incomplete keys inside a sequence item ------------------------

        function testItemKeyWithNoValueAndNoDeeperIndent(testCase)
            % "notes:" has nothing indented under it, so the item key is
            % created with an empty value.
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    notes:"; ...
                "    port: 80"]);

            config = readyaml(file);

            testCase.verifyTrue(iskey(config.servers(1), "notes"), ...
                "The valueless key should still be created");
            testCase.verifyEmpty(config.servers(1).notes);
            testCase.verifyEqual(config.servers(1).port, 80, ...
                "Parsing should continue past the valueless key");
        end

        function testItemKeyWithNoValueAtEndOfFile(testCase)
            % Same shape, but the file ends immediately after the key, so
            % there is no next line to inspect at all.
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    notes:"]);

            config = readyaml(file);

            testCase.verifyTrue(iskey(config.servers, "notes"));
            testCase.verifyEmpty(config.servers.notes);
        end

        function testItemKeyWithNestedBlock(testCase)
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    limits:"; ...
                "      cpu: 2"]);

            config = readyaml(file);

            testCase.verifyEqual(config.servers.limits.cpu, 2, ...
                "An indented block under an item key should be parsed");
        end

        % --- Blank and unrecognized lines inside a sequence item -----------

        function testBlankLineInsideItemIsSkipped(testCase)
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                ""; ...
                "    port: 80"]);

            config = readyaml(file);

            testCase.verifyEqual(config.servers.name, "alpha");
            testCase.verifyEqual(config.servers.port, 80, ...
                "A blank line should not end the item");
        end

        function testCommentOnlyLineInsideItemIsSkipped(testCase)
            % Blank lines are stripped before parsing, but comments are
            % removed afterwards, so a comment-only line is what actually
            % reaches the item parser as an empty line.
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    # a note about the port"; ...
                "    port: 80"]);

            config = readyaml(file);

            testCase.verifyEqual(keys(config.servers), ["name", "port"], ...
                "A comment line should not end the item");
            testCase.verifyEqual(config.servers.port, 80);
        end

        function testLineWithoutColonInsideItemIsSkipped(testCase)
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    garbage"; ...
                "    port: 80"]);

            config = readyaml(file);

            testCase.verifyEqual(keys(config.servers), ["name", "port"], ...
                "A line that is not a key-value pair should be skipped");
        end

        function testIndentedListMarkerEndsTheItem(testCase)
            % A stray dash indented deeper than the item's own dash ends the
            % mapping rather than being read as one of its keys. It then
            % becomes a sequence item of its own, so the sequence holds
            % mixed types and stays a cell.
            file = testCase.writeText([...
                "servers:"; ...
                "  - name: alpha"; ...
                "    - stray"]);

            config = readyaml(file);

            testCase.verifyClass(config.servers, "cell");
            testCase.verifySize(config.servers, [1 2]);
            mapping = config.servers{1};
            testCase.verifyEqual(keys(mapping), "name", ...
                "The stray marker should not become a key of the mapping");
            testCase.verifyEqual(config.servers{2}, "stray");
        end

        % --- Indentless sequences (#59) -------------------------------------

        function testIndentlessSequenceMatchesIndented(testCase)
            % A sequence may start at the same indentation as its parent key.
            indented = testCase.writeTempFile("indented.yaml", [...
                "source: orders"; ...
                "measures:"; ...
                "  - name: total_revenue"; ...
                "    expr: SUM(amount)"; ...
                "  - name: order_count"; ...
                "    expr: COUNT(*)"; ...
                "comment: example"]);
            indentless = testCase.writeTempFile("indentless.yaml", [...
                "source: orders"; ...
                "measures:"; ...
                "- name: total_revenue"; ...
                "  expr: SUM(amount)"; ...
                "- name: order_count"; ...
                "  expr: COUNT(*)"; ...
                "comment: example"]);

            config = readyaml(indentless);

            testCase.verifyEqual(struct(config), struct(readyaml(indented)));
            testCase.verifyEqual(config.measures.name, ["total_revenue"; "order_count"]);
            testCase.verifyEqual(config.comment, "example", ...
                "The key after the sequence should belong to the parent mapping");
        end

        function testNestedIndentlessSequence(testCase)
            file = testCase.writeText([...
                "outer:"; ...
                "  measures:"; ...
                "  - a"; ...
                "  - b"; ...
                "  comment: x"]);

            config = readyaml(file);

            testCase.verifyEqual(config.outer.measures, ["a"; "b"]);
            testCase.verifyEqual(config.outer.comment, "x");
        end

        function testIndentlessSequenceInsideItem(testCase)
            file = testCase.writeText([...
                "jobs:"; ...
                "- name: build"; ...
                "  steps:"; ...
                "  - checkout"; ...
                "  - compile"; ...
                "  timeout: 10"]);

            config = readyaml(file);

            testCase.verifyEqual(config.jobs.steps, ["checkout"; "compile"]);
            testCase.verifyEqual(config.jobs.timeout, 10, ...
                "The key after the sequence should belong to the item");
        end

        function testDeeperNonItemLineDoesNotEndSequence(testCase)
            % Only a non-item line at the sequence's own indentation ends it.
            file = testCase.writeText([...
                "items:"; ...
                "  - a"; ...
                "    continued"; ...
                "  - b"; ...
                "next: 1"]);

            config = readyaml(file);

            % "continued" is a multi-line plain scalar continuation, which
            % readyaml does not support. The line must not truncate the
            % sequence or leak "- b" into the parent mapping.
            testCase.verifySize(config.items, [2 1]);
            testCase.verifyEqual(config.items(2), "b");
            testCase.verifyEqual(config.next, 1);
        end

        function testBareDashItemIsEmpty(testCase)
            file = testCase.writeText([...
                "items:"; ...
                "- a"; ...
                "-"; ...
                "- c"]);

            config = readyaml(file);

            testCase.verifyEqual(config.items, {"a", [], "c"});
        end

        function testDashWithoutSpaceIsMappingKey(testCase)
            file = testCase.writeText([...
                "options:"; ...
                "  -verbose: true"]);

            config = readyaml(file);

            testCase.verifyEqual(keys(config.options), "-verbose");
            testCase.verifyTrue(config.options.("-verbose"));
        end

        % --- Flow sequences ------------------------------------------------

        function testEmptyFlowSequenceIsEmpty(testCase)
            file = testCase.writeText("items: []");

            config = readyaml(file);

            testCase.verifyEmpty(config.items, ...
                "An empty flow sequence should read as empty");
        end

        function testFlowSequenceWithOnlyWhitespaceIsEmpty(testCase)
            file = testCase.writeText("items: [   ]");

            testCase.verifyEmpty(readyaml(file).items);
        end

        % --- Unreadable file -----------------------------------------------

        function testUnreadableFileErrors(testCase)
            file = testCase.writeText("host: local");
            testCase.assertEqual(system("chmod 000 """ + file + """"), 0, ...
                "Could not change the file permissions");
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            % Skip where the process can read regardless of mode, such as
            % when the suite runs as root.
            testCase.assumeError(@() fileread(file), ?MException, ...
                "The file is still readable, so this path cannot be reached");

            testCase.verifyError(@() readyaml(file), ...
                "yamlToolbox:readyaml:FileReadError");
        end
    end
end

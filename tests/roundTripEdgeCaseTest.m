classdef roundTripEdgeCaseTest < ConfigurationFileTestCase
    % Tests for round-trip edge cases: single-element arrays, rmfield
    % cleanup, dotAssign overwrite, nested objects, array-of-tables, and
    % mixed type arrays.

    methods (Test)

        %% Issue 1 — Single-element array round-trip

        function testSingleElementArrayRoundTrip(testCase)
            file = testCase.writeTempFile("single.toml", "val = [5]");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.val, data.val, ...
                "Single-element array should survive read-write-read");
        end

        function testSingleElementArrayIsDistinctFromScalar(testCase)
            file = testCase.writeTempFile("arr.toml", ["val = [5]"; "scalar = 5"]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[5]", ...
                "[5] should be written with array brackets");
        end

        function testMultiElementArrayRoundTrip(testCase)
            file = testCase.writeTempFile("multi.toml", "val = [6, 7]");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[6, 7]");
        end

        function testNestedSingleElementArrayRoundTrip(testCase)
            file = testCase.writeTempFile("nested.toml", "val = [[5], [6]]");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[[5], [6]]", ...
                "Nested single-element arrays should preserve nesting depth");
        end

        function testNestedMultiElementArrayRoundTrip(testCase)
            file = testCase.writeTempFile("nested.toml", "val = [[6, 7], [8, 9]]");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[[6, 7], [8, 9]]");
        end

        function testMixedDepthNestedArrayRoundTrip(testCase)
            file = testCase.writeTempFile("mixed.toml", ...
                "val = [6, [7], [8, 9, [10, 11, 12]]]");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[6, [7], [8, 9, [10, 11, 12]]]");
        end

        %% Issue 2 — rmfield removes value and metadata atomically

        function testRmfieldRemovesKeyCompletely(testCase)
            file = testCase.writeTempFile("rm.toml", ["a = 1"; "b = 2"; "c = 3"]);
            data = readtoml(file);
            data = rmfield(data, "b");

            testCase.verifyEqual(keys(data), ["a", "c"]);
            testCase.verifyFalse(isfield(data, "b"));
        end

        function testRmfieldRoundTrip(testCase)
            file = testCase.writeTempFile("rm.toml", ...
                ["ports = [80, 443]"; "name = ""server"""; "debug = true"]);
            data = readtoml(file);
            data = rmfield(data, "ports");

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifyTrue(~contains(text, "ports"), ...
                "Removed key should not appear in output");
            testCase.verifySubstring(text, "name");
            testCase.verifySubstring(text, "debug");
        end

        function testRmfieldOnNestedObject(testCase)
            file = testCase.writeTempFile("rm.toml", ...
                ["[server]"; "host = ""localhost"""; "port = 8080"]);
            data = readtoml(file);
            data = rmfield(data, "server");

            testCase.verifyEmpty(keys(data));

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = strtrim(string(fileread(out)));
            testCase.verifyEqual(text, "", ...
                "Output should be empty after removing only key");
        end

        %% Issue 2 — dotAssign overwrite clears stale metadata

        function testOverwriteArrayWithScalarRoundTrips(testCase)
            file = testCase.writeTempFile("ow.toml", "ports = [80, 443, 8080]");
            data = readtoml(file);

            data.ports = "hello";

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, 'ports = "hello"', ...
                "Overwritten value should write as a string, not an array");
            testCase.verifyTrue(~contains(text, "["), ...
                "No array brackets should appear after overwrite to string");
        end

        function testOverwriteScalarWithNestedObjectRoundTrips(testCase)
            data = tomldata(struct("count", 42));
            data.count.inner = "nested";

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyClass(data2.count, "matlab.io.config.TOMLData");
            testCase.verifyEqual(data2.count.inner, "nested");
        end

        function testOverwriteNestedObjectWithScalarRoundTrips(testCase)
            data = tomldata();
            data.section.port = 8080;
            data.section.host = "localhost";

            data.section = "flat";

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.section, "flat");
        end

        function testOverwritePreservesKeyOrder(testCase)
            file = testCase.writeTempFile("order.toml", ...
                ["a = 1"; "b = 2"; "c = 3"]);
            data = readtoml(file);

            data.b = "replaced";

            testCase.verifyEqual(keys(data), ["a", "b", "c"], ...
                "Overwrite should preserve key position");
            testCase.verifyEqual(data.b, "replaced");
        end

        %% Issue 4 — Nested object metadata is structural, not split

        function testNestedObjectRoundTripPreservesStructure(testCase)
            file = testCase.writeTempFile("nested.toml", ...
                ["[server]"; "host = ""localhost"""; "port = 8080"; ...
                ""; "[server.tls]"; "enabled = true"; "cert = ""server.pem"""]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.server.host, "localhost");
            testCase.verifyEqual(data2.server.port, 8080);
            testCase.verifyEqual(data2.server.tls.enabled, true);
            testCase.verifyEqual(data2.server.tls.cert, "server.pem");
        end

        function testDeeplyNestedRoundTrip(testCase)
            file = testCase.writeTempFile("deep.toml", ...
                ["[a]"; "[a.b]"; "[a.b.c]"; "val = 42"]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.a.b.c.val, 42);
        end

        %% Issue 5 — Array-of-tables round-trip

        function testArrayOfTablesRoundTrip(testCase)
            file = testCase.writeTempFile("aot.toml", ...
                ["[[products]]"; "name = ""alpha"""; ...
                ""; "[[products]]"; "name = ""beta"""]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[[products]]", ...
                "Array-of-tables syntax should be preserved on round-trip");

            data2 = readtoml(out);
            testCase.verifyNumElements(data2.products, 2);
            testCase.verifyEqual(data2.products(1).name, "alpha");
            testCase.verifyEqual(data2.products(2).name, "beta");
        end

        function testNestedArrayOfTablesRoundTrip(testCase)
            file = testCase.writeTempFile("naot.toml", ...
                ["[[servers.web]]"; "host = ""alpha"""; ...
                ""; "[[servers.web]]"; "host = ""beta"""]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "[[servers.web]]");

            data2 = readtoml(out);
            testCase.verifyNumElements(data2.servers.web, 2);
            testCase.verifyEqual(data2.servers.web(1).host, "alpha");
        end

        function testArrayOfTablesWithSubtableRoundTrip(testCase)
            file = testCase.writeTempFile("aotsub.toml", ...
                ["[[products]]"; "name = ""alpha"""; ...
                ""; "[products.meta]"; "sku = 1"; ...
                ""; "[[products]]"; "name = ""beta"""; ...
                ""; "[products.meta]"; "sku = 2"]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.products(1).meta.sku, 1);
            testCase.verifyEqual(data2.products(2).meta.sku, 2);
        end

        %% Issue 7 — Quoted numeric strings in YAML

        function testQuotedNumericStringYAMLRoundTrip(testCase)

            file = testCase.writeTempFile("docker.yaml", ...
                ["version: '3.8'"; "ports:"; "  - '8080'"]);
            data = readyaml(file);

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyClass(data2.version, "string", ...
                "Quoted numeric string should remain a string after round-trip");
        end

        %% Composite round-trip — read, modify, write, re-read

        function testModifyAndRoundTrip(testCase)
            file = testCase.writeTempFile("mod.toml", ...
                ["title = ""My Project"""; "version = ""1.0"""; ...
                ""; "[database]"; "host = ""localhost"""; "port = 5432"]);
            data = readtoml(file);

            data.version = "2.0";
            data.database.port = 3306;
            data.database.engine = "mysql";

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.title, "My Project");
            testCase.verifyEqual(data2.version, "2.0");
            testCase.verifyEqual(data2.database.host, "localhost");
            testCase.verifyEqual(data2.database.port, 3306);
            testCase.verifyEqual(data2.database.engine, "mysql");
        end

        function testYAMLModifyAndRoundTrip(testCase)
            file = testCase.writeTempFile("mod.yaml", ...
                ["name: app"; "debug: false"; "server:"; "  host: localhost"; "  port: 8080"]);
            data = readyaml(file);

            data.debug = true;
            data.server.port = 9090;
            data.server.tls = true;

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyEqual(data2.name, "app");
            testCase.verifyEqual(data2.debug, true);
            testCase.verifyEqual(data2.server.host, "localhost");
            testCase.verifyEqual(data2.server.port, 9090);
            testCase.verifyEqual(data2.server.tls, true);
        end

        %% Mixed type arrays

        function testMixedTypeArrayRoundTrip(testCase)
            file = testCase.writeTempFile("mixed.toml", 'val = [1, "two", true]');
            data = readtoml(file);

            testCase.verifyClass(data.val, "cell");
            testCase.verifyEqual(data.val{1}, 1);
            testCase.verifyEqual(data.val{2}, "two");
            testCase.verifyEqual(data.val{3}, true);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyClass(data2.val, "cell");
            testCase.verifyEqual(data2.val{1}, 1);
            testCase.verifyEqual(data2.val{2}, "two");
            testCase.verifyEqual(data2.val{3}, true);
        end

        function testEmptyArrayRoundTrip(testCase)
            file = testCase.writeTempFile("empty.toml", "val = []");
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEmpty(data2.val);
        end

        %% YAML array edge cases

        function testYAMLBlockSequenceRoundTrip(testCase)
            file = testCase.writeTempFile("seq.yaml", ...
                ["items:"; "  - 10"; "  - 20"; "  - 30"]);
            data = readyaml(file);

            testCase.verifyEqual(data.items, [10; 20; 30]);

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyEqual(data2.items, [10; 20; 30]);
        end

        function testYAMLStringSequenceRoundTrip(testCase)
            file = testCase.writeTempFile("strs.yaml", ...
                ["tags:"; "  - web"; "  - api"; "  - docs"]);
            data = readyaml(file);

            testCase.verifyEqual(data.tags, ["web"; "api"; "docs"]);

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyEqual(data2.tags, ["web"; "api"; "docs"]);
        end

        function testYAMLObjectSequenceRoundTrip(testCase)
            file = testCase.writeTempFile("objs.yaml", ...
                ["items:"; "  - name: a"; "    val: 1"; "  - name: b"; "    val: 2"]);
            data = readyaml(file);

            testCase.verifyNumElements(data.items, 2);
            testCase.verifyEqual(data.items(1).name, "a");

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyNumElements(data2.items, 2);
            testCase.verifyEqual(data2.items(1).name, "a");
            testCase.verifyEqual(data2.items(2).val, 2);
        end

        %% Value type edge cases

        function testDatetimeRoundTripTOML(testCase)
            file = testCase.writeTempFile("dt.toml", ...
                "created = 2024-01-15T10:30:00Z");
            data = readtoml(file);

            testCase.verifyClass(data.created, "datetime");

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyClass(data2.created, "datetime");
        end

        function testMissingValueRoundTripTOML(testCase)
            data = tomldata(struct("a", 1));
            data.b = missing;

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            text = string(fileread(out));

            testCase.verifyTrue(contains(text, "a = 1"));
        end

        function testMissingValueRoundTripYAML(testCase)
            data = yamldata(struct("a", 1));
            data.b = missing;

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            text = string(fileread(out));

            testCase.verifySubstring(text, "null");
        end

        function testBooleanRoundTripTOML(testCase)
            file = testCase.writeTempFile("bool.toml", ...
                ["enabled = true"; "verbose = false"]);
            data = readtoml(file);

            out = testCase.tempFile("out.toml");
            writetoml(data, out);
            data2 = readtoml(out);

            testCase.verifyEqual(data2.enabled, true);
            testCase.verifyEqual(data2.verbose, false);
        end

        function testBooleanRoundTripYAML(testCase)
            file = testCase.writeTempFile("bool.yaml", ...
                ["enabled: true"; "verbose: false"]);
            data = readyaml(file);

            out = testCase.tempFile("out.yaml");
            writeyaml(data, out);
            data2 = readyaml(out);

            testCase.verifyEqual(data2.enabled, true);
            testCase.verifyEqual(data2.verbose, false);
        end
    end
end

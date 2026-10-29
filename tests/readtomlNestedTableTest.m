classdef readtomlNestedTableTest < ConfigurationFileTestCase
    % Tests for readtoml table paths that are more than one level deep:
    % arrays of tables reached through an intermediate table inside a parent
    % array element, arrays of tables under a plain table, and dotted keys
    % that have to create their own intermediate tables.

    methods(Access = private)
        function file = writeToml(testCase, text)
            file = testCase.writeTempFile("in.toml", text);
        end
    end

    methods(Test)
        % --- Arrays of tables below an intermediate table -------------------

        function testArrayOfTablesTwoLevelsInsideParentElement(testCase)
            % [[jobs.matrix.include]] has to create the "matrix" table inside
            % the current "jobs" element before appending to "include".
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "name = ""build"""; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""linux"""; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""mac"""]);

            config = readtoml(file);

            job = config.jobs;
            testCase.verifyEqual(keys(job), ["name", "matrix"]);
            include = job.matrix.include;
            testCase.verifyNumElements(include, 2, ...
                "Both elements should land in the same nested array");
            testCase.verifyEqual(include(1).os, "linux");
            testCase.verifyEqual(include(2).os, "mac");
        end

        function testSingleElementArrayTwoLevelsInsideParentElement(testCase)
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""linux"""]);

            config = readtoml(file);

            testCase.verifyNumElements(config.jobs.matrix.include, 1);
            testCase.verifyEqual(config.jobs.matrix.include.os, "linux");
        end

        function testNestedArrayIsPerParentElement(testCase)
            % Each [[jobs]] element gets its own matrix.include array.
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "name = ""build"""; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""linux"""; ...
                "[[jobs]]"; ...
                "name = ""deploy"""; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""mac"""]);

            config = readtoml(file);

            testCase.verifyNumElements(config.jobs, 2);
            firstJob = config.jobs(1);
            secondJob = config.jobs(2);
            testCase.verifyEqual(firstJob.matrix.include.os, "linux");
            testCase.verifyEqual(secondJob.matrix.include.os, "mac", ...
                "The second element should not inherit the first array");
        end

        function testArrayOverScalarKeyInSameElementErrors(testCase)
            % "steps" is a plain key of the current element, so it cannot be
            % turned into an array of tables.
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "steps = 1"; ...
                "[[jobs.steps]]"; ...
                "run = ""a"""]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        function testArrayOverScalarRootKeyErrors(testCase)
            file = testCase.writeToml(["items = 1"; "[[items]]"; "n = 1"]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        function testDeepArrayOverExistingScalarErrors(testCase)
            % "include" is already a number, so it cannot be appended to.
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "[jobs.matrix]"; ...
                "include = 1"; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""linux"""]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        % --- Deep headers with no declared parents ---------------------------

        function testDeepTableHeaderCreatesItsOwnParents(testCase)
            file = testCase.writeToml(["[a.b.c]"; "n = 1"]);

            config = readtoml(file);

            testCase.verifyEqual(config.a.b.c.n, 1, ...
                "Undeclared intermediate tables should be created");
        end

        function testDeepArrayHeaderCreatesItsOwnParents(testCase)
            file = testCase.writeToml(["[[a.b.c]]"; "n = 1"; "[[a.b.c]]"; "n = 2"]);

            config = readtoml(file);

            testCase.verifyEqual([config.a.b.c.n], [1; 2]);
        end

        % --- Arrays of tables below a plain table ---------------------------

        function testArrayOfTablesUnderPlainTable(testCase)
            file = testCase.writeToml([...
                "[tool]"; ...
                "name = ""build"""; ...
                "[[tool.items]]"; ...
                "n = 1"; ...
                "[[tool.items]]"; ...
                "n = 2"]);

            config = readtoml(file);

            testCase.verifyEqual(config.tool.name, "build");
            items = config.tool.items;
            testCase.verifyNumElements(items, 2);
            testCase.verifyEqual([items.n], [1; 2], ...
                "Elements are column-oriented, per #77");
        end

        function testArrayOfTablesOverExistingScalarErrors(testCase)
            file = testCase.writeToml([...
                "[tool]"; ...
                "items = 1"; ...
                "[[tool.items]]"; ...
                "n = 1"]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        % --- Arrays replaced by a scalar between elements --------------------
        % A [table] header naming a path that is already an array element
        % merges into that element, so a key written there can replace the
        % nested array the parser is still appending to. Appending after that
        % has to be rejected rather than concatenating onto a number.

        function testAppendingAfterNestedArrayIsOverwrittenErrors(testCase)
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "[[jobs.steps]]"; ...
                "run = ""a"""; ...
                "[jobs]"; ...
                "steps = 5"; ...
                "[[jobs.steps]]"; ...
                "run = ""b"""]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        function testAppendingAfterDeepArrayIsOverwrittenErrors(testCase)
            file = testCase.writeToml([...
                "[[jobs]]"; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""a"""; ...
                "[jobs.matrix]"; ...
                "include = 5"; ...
                "[[jobs.matrix.include]]"; ...
                "os = ""b"""]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        function testAppendingAfterTableArrayIsOverwrittenErrors(testCase)
            file = testCase.writeToml([...
                "[tool]"; ...
                "[[tool.items]]"; ...
                "n = 1"; ...
                "[tool]"; ...
                "items = 5"; ...
                "[[tool.items]]"; ...
                "n = 2"]);

            testCase.verifyError(@() readtoml(file), ...
                "tomlToolbox:readtoml:InvalidArrayOfTables");
        end

        % --- Dotted keys ---------------------------------------------------

        function testDottedKeyAtRootCreatesIntermediateTables(testCase)
            file = testCase.writeToml("a.b.c = 1");

            config = readtoml(file);

            testCase.verifyEqual(config.a.b.c, 1);
        end

        function testSecondDottedKeyReusesIntermediateTables(testCase)
            file = testCase.writeToml(["a.b.c = 1"; "a.b.d = 2"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.a.b), ["c", "d"], ...
                "The second key should be added to the existing table");
        end

        function testDottedKeyInsideTablePreservesLevels(testCase)
            file = testCase.writeToml(["[tool]"; "a.b.c = 1"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.tool.a.b), "c", ...
                "Middle level of a dotted key is preserved");
            testCase.verifyEqual(config.tool.a.b.c, 1);
        end

        function testDottedKeyInsideTablePreservesSiblingKeys(testCase)
            file = testCase.writeToml([...
                "[tool]"; "name = ""alpha"""; "a.b = 1"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.tool), ["name" "a"], ...
                "Dotted key preserves the keys written before it");
            testCase.verifyEqual(config.tool.name, "alpha");
            testCase.verifyEqual(config.tool.a.b, 1);
        end

        function testDottedKeyInsideDeepTableHeader(testCase)
            % Issue #54: a dotted key under a multi-level header errored
            % because the write-back replaced an ancestor of the header table.
            file = testCase.writeToml(["[a.b]"; "c.d = 5"]);

            config = readtoml(file);

            testCase.verifyEqual(config.a.b.c.d, 5);
        end

        function testDottedKeysInsideDeepTableHeaderPreserveSiblingKeys(testCase)
            file = testCase.writeToml([...
                "[a.b]"; ...
                "x = 1"; ...
                "c.d = 5"; ...
                "c.e = 6"; ...
                "y = 2"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.a.b), ["x" "c" "y"], ...
                "Dotted keys preserve the keys written around them");
            testCase.verifyEqual(keys(config.a.b.c), ["d" "e"], ...
                "The second dotted key reuses the intermediate table");
            testCase.verifyEqual(config.a.b.x, 1);
            testCase.verifyEqual(config.a.b.c.d, 5);
            testCase.verifyEqual(config.a.b.c.e, 6);
            testCase.verifyEqual(config.a.b.y, 2);
        end

        function testDottedKeyInsideArrayElementPreservesLevels(testCase)
            file = testCase.writeToml(["[[tool]]"; "a.b.c = 1"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.tool.a.b), "c", ...
                "Middle levels of a dotted key are preserved");
            testCase.verifyEqual(config.tool.a.b.c, 1);
        end

        function testDottedKeyIsPerArrayElement(testCase)
            % A dotted key used to be written to every element of the array.
            file = testCase.writeToml([...
                "[[tool]]"; ...
                "n = 1"; ...
                "[[tool]]"; ...
                "n = 2"; ...
                "a.b = 2"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.tool(1)), "n", ...
                "The first element should not get the second element's key");
            testCase.verifyEqual(config.tool(2).a.b, 2);
        end

        function testDottedKeysInsideTableInArrayElement(testCase)
            file = testCase.writeToml([...
                "[[tool]]"; ...
                "[tool.sub]"; ...
                "z = 0"; ...
                "x.y = 1"; ...
                "x.w = 2"]);

            config = readtoml(file);

            testCase.verifyEqual(keys(config.tool.sub), ["z" "x"]);
            testCase.verifyEqual(keys(config.tool.sub.x), ["y" "w"], ...
                "The second dotted key reuses the intermediate table");
            testCase.verifyEqual(config.tool.sub.x.w, 2);
        end
    end
end

classdef mergeTest < matlab.unittest.TestCase
    % Tests for merge(), which recursively merges two configuration objects
    % with override winning on conflicts.
    %
    % Objects are built with dot assignment rather than from a struct so
    % these tests do not depend on the struct import path (see issue #20).

    methods(Access = private)
        function base = makeBase(~)
            base = yamldata();
            base.timeout = 30;
            base.retries = 3;
            base.database.host = "localhost";
            base.database.port = 5432;
        end
    end

    methods(Test)
        function testOverrideWinsForSharedKeys(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;

            result = merge(base, override);

            testCase.verifyEqual(result.timeout, 60, ...
                "Override value should win for keys present in both");
        end

        function testBaseOnlyKeysAreKept(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;

            result = merge(base, override);

            testCase.verifyEqual(result.retries, 3, ...
                "Keys present only in base should be kept");
        end

        function testOverrideOnlyKeysAreAdded(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.newKey = "added";

            result = merge(base, override);

            testCase.verifyEqual(result.newKey, "added", ...
                "Keys present only in override should be added");
        end

        function testNestedObjectsMergeRecursively(testCase)
            % The documented deep-merge case: overriding one nested key must
            % not discard its siblings.
            base = testCase.makeBase();
            override = yamldata();
            override.database.host = "prod-db";

            result = merge(base, override);

            testCase.verifyEqual(result.database.host, "prod-db", ...
                "Nested override should win");
            testCase.verifyEqual(result.database.port, 5432, ...
                "Sibling keys in a nested object should survive the merge");
        end

        function testDeeplyNestedMergeRecurses(testCase)
            base = yamldata();
            base.a.b.c = 1;
            base.a.b.keep = "yes";

            override = yamldata();
            override.a.b.c = 2;

            result = merge(base, override);

            testCase.verifyEqual(result.a.b.c, 2);
            testCase.verifyEqual(result.a.b.keep, "yes", ...
                "Recursion should preserve siblings at every depth");
        end

        function testArraysOverrideAtomically(testCase)
            % Documented: arrays are replaced, never concatenated.
            base = yamldata();
            base.ports = [8080; 8443; 9000];

            override = yamldata();
            override.ports = [80; 443];

            result = merge(base, override);

            testCase.verifyEqual(result.ports, [80; 443], ...
                "Arrays should be replaced atomically, not concatenated");
        end

        function testStringsOverrideAtomically(testCase)
            base = yamldata();
            base.name = "original";

            override = yamldata();
            override.name = "replacement";

            testCase.verifyEqual(merge(base, override).name, "replacement");
        end

        function testKeyOrderIsBaseOrderThenNewKeys(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;
            override.appended = 1;

            result = merge(base, override);

            testCase.verifyEqual(keys(result), ...
                ["timeout", "retries", "database", "appended"], ...
                "Base key order should be preserved with new keys appended");
        end

        function testResultClassMatchesBase(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;

            testCase.verifyClass(merge(base, override), ...
                "matlab.io.config.YAMLData");
        end

        function testResultClassMatchesBaseWhenClassesDiffer(testCase)
            % Documented: the result takes base's class, so merging a TOML
            % override into a YAML base yields YAML, and vice versa.
            yamlBase = yamldata();
            yamlBase.a = 1;
            tomlBase = tomldata();
            tomlBase.a = 1;

            testCase.verifyClass(merge(yamlBase, tomlBase), ...
                "matlab.io.config.YAMLData", ...
                "YAML base should yield a YAML result");
            testCase.verifyClass(merge(tomlBase, yamlBase), ...
                "matlab.io.config.TOMLData", ...
                "TOML base should yield a TOML result");
        end

        function testBaseIsUnmodified(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;
            override.added = 1;

            merge(base, override);

            testCase.verifyEqual(base.timeout, 30, ...
                "merge must not modify base");
            testCase.verifyEqual(keys(base), ...
                ["timeout", "retries", "database"], ...
                "merge must not add keys to base");
        end

        function testOverrideIsUnmodified(testCase)
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;

            merge(base, override);

            testCase.verifyEqual(keys(override), "timeout", ...
                "merge must not modify override");
        end

        function testEmptyOverrideLeavesBaseKeys(testCase)
            base = testCase.makeBase();

            result = merge(base, yamldata());

            testCase.verifyEqual(keys(result), keys(base), ...
                "Merging an empty override should preserve base exactly");
            testCase.verifyEqual(result.timeout, 30);
        end

        function testEmptyBaseAdoptsOverrideKeys(testCase)
            override = yamldata();
            override.only = "value";

            result = merge(yamldata(), override);

            testCase.verifyEqual(keys(result), "only", ...
                "Merging into an empty base should adopt override's keys");
            testCase.verifyEqual(result.only, "value");
        end

        function testScalarIsReplacedByNestedObject(testCase)
            % Type change is an atomic override, not an error.
            base = yamldata();
            base.thing = 5;

            override = yamldata();
            override.thing.deep = 7;

            result = merge(base, override);

            testCase.verifyClass(result.thing, "matlab.io.config.YAMLData", ...
                "A scalar should be replaceable by a nested object");
            testCase.verifyEqual(result.thing.deep, 7);
        end

        function testNestedObjectIsReplacedByScalar(testCase)
            base = yamldata();
            base.thing.deep = 7;

            override = yamldata();
            override.thing = 5;

            testCase.verifyEqual(merge(base, override).thing, 5, ...
                "A nested object should be replaceable by a scalar");
        end

        function testKeyWithSpecialCharactersIsAdded(testCase)
            base = yamldata();
            base.a = 1;

            override = yamldata();
            override.("build-system") = "cmake";

            result = merge(base, override);

            testCase.verifyEqual(keys(result), ["a", "build-system"], ...
                "Original key name should survive the merge");
            testCase.verifyEqual(result.("build-system"), "cmake");
        end

        function testKeyWithSpecialCharactersIsOverridden(testCase)
            base = yamldata();
            base.("build-system") = "make";

            override = yamldata();
            override.("build-system") = "cmake";

            result = merge(base, override);

            testCase.verifyEqual(keys(result), "build-system", ...
                "Overriding a hyphenated key should not duplicate it");
            testCase.verifyEqual(result.("build-system"), "cmake");
        end

        function testMergingWithItselfIsIdempotent(testCase)
            base = testCase.makeBase();

            result = merge(base, base);

            testCase.verifyEqual(keys(result), keys(base));
            testCase.verifyEqual(result.timeout, 30);
            testCase.verifyEqual(result.database.port, 5432);
        end

        function testStructOverrideErrors(testCase)
            base = testCase.makeBase();

            testCase.verifyError(@() merge(base, struct("timeout", 60)), ...
                "MATLAB:validation:UnableToConvert");
        end

        function testStructBaseErrors(testCase)
            override = yamldata();
            override.timeout = 60;

            testCase.verifyError(@() merge(struct("timeout", 30), override), ...
                "MATLAB:validation:UnableToConvert");
        end

        function testObjectArrayInputErrors(testCase)
            % merge declares no size restriction, so an object array passes
            % validation and then fails inside with an opaque indexing error.
            % Asserting only that it errors, not the specific identifier,
            % because the fix for issue #24 will change it.
            base = testCase.makeBase();
            override = yamldata();
            override.timeout = 60;

            testCase.verifyError(@() merge([base, base], override), ...
                ?MException);
        end
    end
end

classdef selectTest < matlab.unittest.TestCase
    % Tests for select(), which returns a new object containing only the
    % requested keys.
    %
    % Objects are built with dot assignment rather than from a struct so
    % these tests do not depend on the struct import path (see issue #20).

    methods(Access = private)
        function config = makeConfig(~)
            % Three keys, one of which needs a MATLAB-valid alias.
            config = yamldata();
            config.host = "example.com";
            config.port = 8080;
            config.("build-system") = "cmake";
        end
    end

    methods(Test)
        function testSelectsOnlyRequestedKeys(testCase)
            config = testCase.makeConfig();

            result = select(config, ["host", "port"]);

            testCase.verifyEqual(keys(result), ["host", "port"], ...
                "Result should contain exactly the requested keys");
        end

        function testOrderFollowsSelectedKeys(testCase)
            % Documented behavior: result order matches selectedKeys, not
            % the key order of the source object.
            config = testCase.makeConfig();

            result = select(config, ["port", "host"]);

            testCase.verifyEqual(keys(result), ["port", "host"], ...
                "Result order should follow selectedKeys, not source order");
        end

        function testValuesArePreserved(testCase)
            config = testCase.makeConfig();

            result = select(config, ["host", "port"]);

            testCase.verifyEqual(result.host, "example.com");
            testCase.verifyEqual(result.port, 8080);
        end

        function testSingleKeyReturnsObjectNotValue(testCase)
            % select always returns a ConfigurationData, even for one key.
            config = testCase.makeConfig();

            result = select(config, "host");

            testCase.verifyClass(result, "matlab.io.config.YAMLData", ...
                "select should return an object, not the bare value");
            testCase.verifyEqual(keys(result), "host");
        end

        function testAcceptsCellArrayOfChar(testCase)
            config = testCase.makeConfig();

            result = select(config, {'host', 'port'});

            testCase.verifyEqual(keys(result), ["host", "port"], ...
                "Cell array of char should be accepted");
        end

        function testAcceptsColumnVectorOfKeys(testCase)
            % select reshapes selectedKeys to a row before iterating, so a
            % column vector must behave identically to a row.
            config = testCase.makeConfig();

            result = select(config, ["host"; "port"]);

            testCase.verifyEqual(keys(result), ["host", "port"], ...
                "Column vector of keys should behave like a row vector");
        end

        function testSourceObjectIsUnmodified(testCase)
            % select is non-destructive; the value semantics of
            % ConfigurationData should leave the source untouched.
            config = testCase.makeConfig();
            keysBefore = keys(config);

            select(config, "host");

            testCase.verifyEqual(keys(config), keysBefore, ...
                "select must not modify the source object");
        end

        function testPreservesYAMLClass(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyClass(select(config, "a"), ...
                "matlab.io.config.YAMLData");
        end

        function testPreservesTOMLClass(testCase)
            config = tomldata();
            config.a = 1;

            testCase.verifyClass(select(config, "a"), ...
                "matlab.io.config.TOMLData");
        end

        function testMissingKeyErrors(testCase)
            config = testCase.makeConfig();

            testCase.verifyError(@() select(config, "nope"), ...
                "ConfigurationData:InvalidKey");
        end

        function testMissingKeyErrorsWhenMixedWithValidKeys(testCase)
            % Validation covers every requested key, not just the first.
            config = testCase.makeConfig();

            testCase.verifyError(@() select(config, ["host", "nope"]), ...
                "ConfigurationData:InvalidKey");
        end

        function testMissingKeyLeavesSourceUnmodified(testCase)
            config = testCase.makeConfig();
            keysBefore = keys(config);

            testCase.verifyError(@() select(config, ["host", "nope"]), ...
                "ConfigurationData:InvalidKey");

            testCase.verifyEqual(keys(config), keysBefore, ...
                "A failed select must not modify the source object");
        end

        function testObjectArrayInputErrors(testCase)
            % select is declared (1,1); an object array is a size violation.
            config = testCase.makeConfig();
            configs = [config, config];

            testCase.verifyError(@() select(configs, "host"), ...
                "MATLAB:validation:IncompatibleSize");
        end

        function testEmptySelectionReturnsObjectWithNoKeys(testCase)
            config = testCase.makeConfig();

            result = select(config, string.empty);

            testCase.verifyClass(result, "matlab.io.config.YAMLData");
            testCase.verifyEmpty(keys(result), ...
                "Selecting no keys should yield an object with no keys");
        end

        function testKeyWithSpecialCharactersIsPreserved(testCase)
            % Requesting the original key name must keep that exact name, so
            % a later write emits "build-system" rather than an alias.
            config = testCase.makeConfig();

            result = select(config, "build-system");

            testCase.verifyEqual(keys(result), "build-system", ...
                "Original key name should survive selection");
            testCase.verifyEqual(result.("build-system"), "cmake");
        end

        function testAliasedKeyPreservesOriginalName(testCase)
            config = testCase.makeConfig();

            result = select(config, "build_system");

            testCase.verifyEqual(keys(result), "build-system", ...
                "Selecting by alias should keep the original key name");
            testCase.verifyEqual(result.build_system, "cmake", ...
                "Alias should resolve to the aliased key's value");
        end

        function testDuplicateKeysCollapse(testCase)
            % Assigning the same key twice is harmless; the result holds one.
            config = testCase.makeConfig();

            result = select(config, ["host", "host"]);

            testCase.verifyEqual(keys(result), "host", ...
                "Repeated keys should collapse to a single key");
        end

        function testNestedObjectValueIsPreserved(testCase)
            config = yamldata();
            config.database.host = "localhost";
            config.database.port = 5432;
            config.unrelated = 1;

            result = select(config, "database");

            testCase.verifyEqual(keys(result), "database");
            testCase.verifyEqual(result.database.host, "localhost");
            testCase.verifyEqual(result.database.port, 5432);
        end

        function testArrayValueIsPreserved(testCase)
            config = yamldata();
            config.ports = [8080; 8443; 9000];

            result = select(config, "ports");

            testCase.verifyEqual(result.ports, [8080; 8443; 9000], ...
                "Array values should survive selection unchanged");
        end
    end
end

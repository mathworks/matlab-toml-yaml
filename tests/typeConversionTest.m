classdef typeConversionTest < matlab.unittest.TestCase
    % Tests for the ConfigurationToType conversion methods: dictionary,
    % map, fieldnames, properties, rmfield, and remove.
    %
    % Objects are built with dot assignment rather than from a struct so
    % these tests do not depend on the struct import path (see issue #20).

    methods(Access = private)
        function config = makeConfig(~)
            config = yamldata();
            config.host = "example.com";
            config.port = 8080;
            config.nested.inner = 42;
            config.("build-system") = "cmake";
        end
    end

    methods(Test)
        % --- fieldnames -------------------------------------------------

        function testFieldnamesMatchesKeys(testCase)
            config = testCase.makeConfig();

            testCase.verifyEqual(fieldnames(config), keys(config), ...
                "fieldnames is documented as an alias for keys");
        end

        function testFieldnamesUsesOriginalKeyNames(testCase)
            config = testCase.makeConfig();

            testCase.verifyTrue(ismember("build-system", fieldnames(config)), ...
                "fieldnames should report the original key, not the alias");
        end

        % --- properties -------------------------------------------------

        function testPropertiesReturnsCellArrayOfChar(testCase)
            % properties() feeds IDE tab completion, which requires cellstr.
            config = testCase.makeConfig();

            result = properties(config);

            testCase.verifyClass(result, "cell");
            testCase.verifyTrue(all(cellfun(@ischar, result)), ...
                "properties should return a cell array of char");
        end

        function testPropertiesListsAllKeys(testCase)
            config = testCase.makeConfig();

            testCase.verifyEqual(string(properties(config))', keys(config), ...
                "properties should list every key");
        end

        % --- dictionary -------------------------------------------------

        function testDictionaryConvertsToDictionary(testCase)
            config = testCase.makeConfig();

            result = dictionary(config);

            testCase.verifyClass(result, "dictionary");
        end

        function testDictionaryPreservesKeyOrder(testCase)
            config = testCase.makeConfig();

            result = dictionary(config);

            testCase.verifyEqual(keys(result)', keys(config), ...
                "dictionary should preserve insertion order");
        end

        function testDictionaryPreservesValues(testCase)
            config = testCase.makeConfig();

            result = dictionary(config);

            import matlab.io.config.internal.lookupCellDictionaryKey

            testCase.verifyEqual(lookupCellDictionaryKey(result, "host"), "example.com");
            testCase.verifyEqual(lookupCellDictionaryKey(result, "port"), 8080);
        end

        function testDictionaryRecursesIntoNestedObjects(testCase)
            % Documented: nested objects become nested dictionaries.
            config = testCase.makeConfig();

            result = dictionary(config);

            import matlab.io.config.internal.lookupCellDictionaryKey
            nested = lookupCellDictionaryKey(result, "nested");
            testCase.verifyClass(nested, "dictionary", ...
                "Nested objects should convert recursively");
            testCase.verifyEqual(lookupCellDictionaryKey(nested, "inner"), 42);
        end

        function testDictionaryPreservesArrayValues(testCase)
            config = yamldata();
            config.ports = [8080; 8443];

            result = dictionary(config);

            import matlab.io.config.internal.lookupCellDictionaryKey
            testCase.verifyEqual(lookupCellDictionaryKey(result, "ports"), [8080; 8443]);
        end

        % --- map --------------------------------------------------------

        function testMapConvertsToContainersMap(testCase)
            config = testCase.makeConfig();

            testCase.verifyClass(map(config), "containers.Map");
        end

        function testMapContainsEveryKey(testCase)
            % containers.Map sorts its keys, so compare as sets rather than
            % in order.
            config = testCase.makeConfig();

            result = map(config);

            testCase.verifyEqual(sort(string(result.keys)), ...
                sort(keys(config)), ...
                "map should contain every key");
        end

        function testMapPreservesValues(testCase)
            config = testCase.makeConfig();

            result = map(config);

            testCase.verifyEqual(result('host'), "example.com");
            testCase.verifyEqual(result('port'), 8080);
        end

        function testMapRecursesIntoNestedObjects(testCase)
            config = testCase.makeConfig();

            result = map(config);

            nested = result('nested');
            testCase.verifyClass(nested, "containers.Map", ...
                "Nested objects should convert recursively");
            testCase.verifyEqual(nested('inner'), 42);
        end

        % --- rmfield ----------------------------------------------------

        function testRmfieldRemovesTheKey(testCase)
            config = testCase.makeConfig();

            result = rmfield(config, "port");

            testCase.verifyFalse(iskey(result, "port"), ...
                "rmfield should remove the requested key");
        end

        function testRmfieldPreservesRemainingKeyOrder(testCase)
            config = testCase.makeConfig();

            result = rmfield(config, "port");

            testCase.verifyEqual(keys(result), ...
                ["host", "nested", "build-system"], ...
                "Remaining keys should keep their order");
        end

        function testRmfieldIsNonDestructive(testCase)
            config = testCase.makeConfig();
            keysBefore = keys(config);

            rmfield(config, "port");

            testCase.verifyEqual(keys(config), keysBefore, ...
                "rmfield must not modify the source object");
        end

        function testRmfieldByAliasRemovesOriginalKey(testCase)
            % Unlike select (issue #23), rmfield resolves the alias to the
            % canonical key before removing it.
            config = testCase.makeConfig();

            result = rmfield(config, "build_system");

            testCase.verifyFalse(iskey(result, "build-system"), ...
                "Removing by alias should remove the original key");
            testCase.verifyEqual(keys(result), ["host", "port", "nested"]);
        end

        function testRmfieldMissingKeyErrors(testCase)
            config = testCase.makeConfig();

            testCase.verifyError(@() rmfield(config, "nope"), ...
                "ConfigurationData:InvalidKey");
        end

        function testRmfieldPreservesClass(testCase)
            config = tomldata();
            config.a = 1;
            config.b = 2;

            testCase.verifyClass(rmfield(config, "b"), ...
                "matlab.io.config.TOMLData");
        end

        % --- remove -----------------------------------------------------

        function testRemoveRemovesTheKey(testCase)
            config = testCase.makeConfig();

            result = remove(config, "port");

            testCase.verifyFalse(iskey(result, "port"), ...
                "remove should remove the requested key");
        end

        function testRemoveMatchesRmfield(testCase)
            % remove is documented as an alias for rmfield.
            config = testCase.makeConfig();

            testCase.verifyEqual(keys(remove(config, "port")), ...
                keys(rmfield(config, "port")), ...
                "remove should behave identically to rmfield");
        end

        function testRemoveIsNonDestructive(testCase)
            config = testCase.makeConfig();
            keysBefore = keys(config);

            remove(config, "port");

            testCase.verifyEqual(keys(config), keysBefore, ...
                "remove must not modify the source object");
        end

        function testRemoveMissingKeyErrors(testCase)
            config = testCase.makeConfig();

            testCase.verifyError(@() remove(config, "nope"), ...
                "ConfigurationData:InvalidKey");
        end
    end
end

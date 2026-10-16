classdef dataConstructorTest < matlab.unittest.TestCase
    % Tests for the yamldata() and tomldata() constructor functions and the
    % importFrom conversion they delegate to.

    properties(TestParameter)
        % Each constructor paired with the class it should produce.
        constructor = struct(...
            yaml = struct(make = @yamldata, class = "matlab.io.config.YAMLData"), ...
            toml = struct(make = @tomldata, class = "matlab.io.config.TOMLData"))
    end

    methods(Test, ParameterCombination = "sequential")
        function testNoArgumentsCreatesEmptyObject(testCase, constructor)
            result = constructor.make();

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEmpty(keys(result), ...
                "An object created with no arguments should have no keys");
        end

        function testCreatesFromScalarStruct(testCase, constructor)
            result = constructor.make(struct("host", "example.com", "port", 8080));

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEqual(keys(result), ["host", "port"], ...
                "Field order should become key order");
            testCase.verifyEqual(result.host, "example.com");
            testCase.verifyEqual(result.port, 8080);
        end

        function testCharFieldValuesBecomeStrings(testCase, constructor)
            % char is an accepted input type that is stored as string.
            result = constructor.make(struct("name", 'MyApp'));

            testCase.verifyEqual(result.name, "MyApp");
        end

        function testCreatesFromStructArray(testCase, constructor)
            % A struct array becomes an object array of the same shape.
            result = constructor.make(struct("id", {1, 2, 3}));

            testCase.verifyClass(result, constructor.class);
            testCase.verifySize(result, [1 3], ...
                "The object array should match the struct array shape");
            testCase.verifyEqual(result(1).id, 1);
            testCase.verifyEqual(result(3).id, 3);
        end

        function testCreatesFromCellValuedDictionary(testCase, constructor)
            input = dictionary(string.empty, cell.empty);
            input("host") = {"example.com"};
            input("port") = {8080};

            result = constructor.make(input);

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEqual(keys(result), ["host", "port"]);
            testCase.verifyEqual(result.port, 8080);
        end

        function testCreatesFromPlainValuedDictionary(testCase, constructor)
            input = dictionary(["host", "port"], ["example.com", "8080"]);

            result = constructor.make(input);

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEqual(result.host, "example.com");
            testCase.verifyEqual(result.port, "8080");
        end

        function testCreatesFromContainersMap(testCase, constructor)
            input = containers.Map({'host', 'port'}, {'example.com', 8080});

            result = constructor.make(input);

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEqual(result.host, "example.com");
            testCase.verifyEqual(result.port, 8080);
        end

        function testCreatesFromContainersMapWithSingleEntry(testCase, constructor)
            input = containers.Map("name", "app");

            result = constructor.make(input);

            testCase.verifyClass(result, constructor.class);
            testCase.verifyEqual(result.name, "app");
        end

        function testUnsupportedInputErrors(testCase, constructor)
            testCase.verifyError(@() constructor.make(42), ...
                "ConfigurationData:InvalidInput", ...
                "Input other than a struct or dictionary should be rejected");
        end

        function testNestedStructDoesNotInheritParentKeys(testCase, constructor)
            input = struct("name", "app", "count", 42, ...
                "server", struct("host", "localhost", "timeout", 2.5));

            result = constructor.make(input);

            testCase.verifyEqual(keys(result.server), ["host", "timeout"], ...
                "Nested struct should contain only its own keys");
            testCase.verifyEqual(result.server.host, "localhost");
            testCase.verifyEqual(result.server.timeout, 2.5);
        end

        function testDeeplyNestedStructKeysAreIsolated(testCase, constructor)
            input = struct("a", 1, ...
                "level1", struct("b", 2, ...
                "level2", struct("c", 3)));

            result = constructor.make(input);

            testCase.verifyEqual(keys(result), ["a", "level1"]);
            testCase.verifyEqual(keys(result.level1), ["b", "level2"]);
            testCase.verifyEqual(keys(result.level1.level2), "c");
        end

        function testNestedStructPreservesSubclassType(testCase, constructor)
            input = struct("outer", struct("inner", 1));

            result = constructor.make(input);

            testCase.verifyClass(result.outer, constructor.class);
        end

        function testNestedDictionaryDoesNotInheritParentKeys(testCase, constructor)
            inner = dictionary(string.empty, cell.empty);
            inner("host") = {"localhost"};
            inner("port") = {8080};

            result = constructor.make(struct("name", "app"));
            result.server = inner;

            testCase.verifyEqual(keys(result.server), ["host", "port"], ...
                "Nested dictionary should contain only its own keys");
        end
    end
end

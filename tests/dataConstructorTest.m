classdef dataConstructorTest < matlab.unittest.TestCase
    % Tests for the yamldata() and tomldata() constructor functions and the
    % importFrom conversion they delegate to.
    %
    % Nested structs and dictionaries as *values* are not covered here
    % because importing them is broken (issue #20); only flat inputs and the
    % cell-valued dictionary form work today.

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
            input = configureDictionary("string", "cell");
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

        function testKeyNeedingAnAliasIsPreserved(testCase, constructor)
            % Struct field names cannot contain hyphens, so a key needing an
            % alias has to be assigned after construction.
            result = constructor.make(struct("a", 1));
            result.("build-system") = "cmake";

            testCase.verifyEqual(keys(result), ["a", "build-system"]);
            testCase.verifyEqual(result.build_system, "cmake", ...
                "The alias should resolve to the hyphenated key");
        end
    end
end

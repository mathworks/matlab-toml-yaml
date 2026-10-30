classdef siblingStructImportTest < ConfigurationFileTestCase
    % Tests that importing a struct or dictionary whose fields hold nested
    % structs or dictionaries keeps each nested value independent of its
    % siblings (issue #56). Previously, each nested value was imported into
    % a copy of the parent object, so later siblings picked up copies of the
    % earlier ones.

    properties(TestParameter)
        % Each format with its constructor, writer and reader.
        format = struct(...
            yaml = struct(make = @yamldata, write = @writeyaml, read = @readyaml, file = "out.yaml"), ...
            toml = struct(make = @tomldata, write = @writetoml, read = @readtoml, file = "out.toml"))
    end

    methods(Test)
        function testTwoSiblingStructsStayIndependent(testCase, format)
            s = struct(a = struct(x = 1), b = struct(y = 2));

            result = format.make(s);

            testCase.verifyEqual(keys(result), ["a", "b"]);
            testCase.verifyEqual(keys(result.a), "x");
            testCase.verifyEqual(keys(result.b), "y", ...
                "The second sibling should not contain a copy of the first");
        end

        function testThreeSiblingStructsStayIndependent(testCase, format)
            s = struct(a = struct(x = 1), b = struct(y = 2), c = struct(z = 3));

            result = format.make(s);

            testCase.verifyEqual(keys(result.b), "y");
            testCase.verifyEqual(keys(result.c), "z", ...
                "The third sibling should not contain copies of earlier siblings");
        end

        function testSiblingOrderDoesNotMatter(testCase, format)
            s = struct(b = struct(y = 2), a = struct(x = 1));

            result = format.make(s);

            testCase.verifyEqual(keys(result.b), "y");
            testCase.verifyEqual(keys(result.a), "x");
        end

        function testDeeplyNestedSiblingsStayIndependent(testCase, format)
            s = struct(outer = struct(a = struct(x = 1), b = struct(y = 2)));

            result = format.make(s);

            testCase.verifyEqual(keys(result.outer), ["a", "b"]);
            testCase.verifyEqual(keys(result.outer.b), "y");
        end

        function testNestedStructAfterScalarFieldStaysIndependent(testCase, format)
            % A non-struct sibling assigned earlier must not leak either.
            s = struct(name = "app", settings = struct(debug = true));

            result = format.make(s);

            testCase.verifyEqual(keys(result.settings), "debug");
        end

        function testSiblingDictionariesStayIndependent(testCase, format)
            d = dictionary(["a", "b"], {dictionary("x", 1), dictionary("y", 2)});

            result = format.make(d);

            testCase.verifyEqual(keys(result.a), "x");
            testCase.verifyEqual(keys(result.b), "y", ...
                "The second dictionary value should not contain a copy of the first");
        end

        function testSiblingContainersMapValuesStayIndependent(testCase, format)
            m = containers.Map({'a', 'b'}, {struct(x = 1), struct(y = 2)});

            result = format.make(m);

            testCase.verifyEqual(keys(result.b), "y");
        end

        function testAssigningStructToPopulatedObject(testCase, format)
            % Dot assignment of a struct into an object that already has
            % keys must not copy those keys into the new value.
            config = format.make(struct(a = struct(x = 1)));

            config.b = struct(y = 2);

            testCase.verifyEqual(keys(config.b), "y");
        end

        function testSingleElementStructNextToTable(testCase, format)
            % A single-element struct next to another struct must not pick
            % up a copy of it.
            s = struct( ...
                block = struct(class = "c"), ...
                param = struct(name = "a", kind = "value"));

            result = format.make(s);

            testCase.verifyEqual(keys(result.param), ["name", "kind"]);
        end

        function testWriteAndReadRoundTripsSiblingStructs(testCase, format)
            s = struct(a = struct(x = 1), b = struct(y = 2));
            file = testCase.tempFile(format.file);

            format.write(s, file);
            result = format.read(file);

            testCase.verifyEqual(keys(result.a), "x");
            testCase.verifyEqual(keys(result.b), "y", ...
                "The written file should not contain extra keys");
        end
    end
end

classdef builderTypeTest < ConfigurationFileTestCase
    % Tests targeting C++ MatlabBuilder type dispatch, array consolidation,
    % N-D reconstruction, and cell fallback. Exercises specific code paths
    % in matlab_builder.cpp through the readtoml/readyaml interface.

    methods (Test)

        %% Integer precision boundary (intValue / uintValue)

        function testSmallIntegerIsDouble(testCase)
            file = testCase.writeTempFile("t.toml", "v = 42");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
            testCase.verifyEqual(data.v, 42);
        end

        function testIntegerAtExact2Pow53IsDouble(testCase)
            file = testCase.writeTempFile("t.toml", "v = 9007199254740992");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
        end

        function testIntegerAbove2Pow53IsInt64(testCase)
            file = testCase.writeTempFile("t.toml", "v = 9007199254740993");
            data = readtoml(file);
            testCase.verifyClass(data.v, "int64");
            testCase.verifyEqual(data.v, int64(9007199254740993));
        end

        function testNegativeIntegerBelowMinus2Pow53IsInt64(testCase)
            file = testCase.writeTempFile("t.toml", "v = -9007199254740993");
            data = readtoml(file);
            testCase.verifyClass(data.v, "int64");
            testCase.verifyEqual(data.v, int64(-9007199254740993));
        end

        function testNegativeIntegerAtMinus2Pow53IsDouble(testCase)
            file = testCase.writeTempFile("t.toml", "v = -9007199254740992");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
        end

        function testZeroIsDouble(testCase)
            file = testCase.writeTempFile("t.toml", "v = 0");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
            testCase.verifyEqual(data.v, 0);
        end

        %% Scalar consolidation (endArray, uniform scalars)

        function testDoubleArrayConsolidation(testCase)
            file = testCase.writeTempFile("t.toml", "v = [1, 2, 3]");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
            testCase.verifyEqual(data.v, [1; 2; 3]);
        end

        function testBoolArrayConsolidation(testCase)
            file = testCase.writeTempFile("t.toml", "v = [true, false, true]");
            data = readtoml(file);
            testCase.verifyClass(data.v, "logical");
            testCase.verifyEqual(data.v, [true; false; true]);
        end

        function testStringArrayConsolidation(testCase)
            file = testCase.writeTempFile("t.toml", 'v = ["a", "b", "c"]');
            data = readtoml(file);
            testCase.verifyClass(data.v, "string");
            testCase.verifyEqual(data.v, ["a"; "b"; "c"]);
        end

        function testInt64ArrayConsolidation(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "v = [9007199254740993, 9007199254740994]");
            data = readtoml(file);
            testCase.verifyClass(data.v, "int64");
            expected = [int64(9007199254740993); int64(9007199254740993) + int64(1)];
            testCase.verifyEqual(data.v, expected);
        end

        function testSingleElementArrayIsColumnVector(testCase)
            file = testCase.writeTempFile("t.toml", "v = [5]");
            data = readtoml(file);
            testCase.verifySize(data.v, [1 1]);
        end

        function testMultiElementArrayIsColumnVector(testCase)
            file = testCase.writeTempFile("t.toml", "v = [1, 2, 3, 4]");
            data = readtoml(file);
            testCase.verifySize(data.v, [4 1]);
        end

        %% N-D array reconstruction (endArray, uniform nested arrays)

        function test2DMatrixReconstruction(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "m = [[1, 2, 3], [4, 5, 6]]");
            data = readtoml(file);
            testCase.verifySize(data.m, [2 3]);
            testCase.verifyEqual(data.m, [1 2 3; 4 5 6]);
        end

        function test3DArrayReconstruction(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "m = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]");
            data = readtoml(file);
            testCase.verifySize(data.m, [2 2 2]);
        end

        function testBoolMatrixReconstruction(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "m = [[true, false], [false, true]]");
            data = readtoml(file);
            testCase.verifyClass(data.m, "logical");
            testCase.verifySize(data.m, [2 2]);
            testCase.verifyEqual(data.m, [true false; false true]);
        end

        function testStringMatrixReconstruction(testCase)
            file = testCase.writeTempFile("t.toml", ...
                'm = [["a", "b"], ["c", "d"]]');
            data = readtoml(file);
            testCase.verifyClass(data.m, "string");
            testCase.verifySize(data.m, [2 2]);
            testCase.verifyEqual(data.m, ["a" "b"; "c" "d"]);
        end

        function testSquareMatrixReconstruction(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "m = [[1, 2], [3, 4]]");
            data = readtoml(file);
            testCase.verifySize(data.m, [2 2]);
            testCase.verifyEqual(data.m, [1 2; 3 4]);
        end

        %% Cell fallback (non-uniform types or shapes)

        function testMixedTypesProduceColumnCell(testCase)
            file = testCase.writeTempFile("t.toml", 'v = [1, "two", true]');
            data = readtoml(file);
            testCase.verifyClass(data.v, "cell");
            testCase.verifySize(data.v, [3 1]);
        end

        function testMixedNumericTypesProduceColumnCell(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "v = [3.14, 9007199254740993]");
            data = readtoml(file);
            testCase.verifyClass(data.v, "cell");
            testCase.verifySize(data.v, [2 1]);
        end

        function testRaggedNestedArrayProducesColumnCell(testCase)
            file = testCase.writeTempFile("t.toml", ...
                "v = [[1, 2], [3, 4, 5]]");
            data = readtoml(file);
            testCase.verifyClass(data.v, "cell");
            testCase.verifySize(data.v, [2 1]);
        end

        function testMixedTypeNestedArrayProducesCell(testCase)
            file = testCase.writeTempFile("t.toml", ...
                'v = [[1, 2], ["a", "b"]]');
            data = readtoml(file);
            testCase.verifyClass(data.v, "cell");
        end

        %% Empty array

        function testEmptyArrayIsEmptyDouble(testCase)
            file = testCase.writeTempFile("t.toml", "v = []");
            data = readtoml(file);
            testCase.verifyClass(data.v, "double");
            testCase.verifyEmpty(data.v);
        end

        %% YAML builder paths (same builder, different parser)

        function testYAMLIntegerBoundary(testCase)
            file = testCase.writeTempFile("t.yaml", "v: 9007199254740993");
            data = readyaml(file);
            testCase.verifyClass(data.v, "int64");
        end

        function testYAMLSmallIntegerIsDouble(testCase)
            file = testCase.writeTempFile("t.yaml", "v: 100");
            data = readyaml(file);
            testCase.verifyClass(data.v, "double");
        end

        function testYAMLNestedSequenceBecomesMatrix(testCase)
            file = testCase.writeTempFile("t.yaml", ...
                ["matrix:"; "  - [1, 2, 3]"; "  - [4, 5, 6]"]);
            data = readyaml(file);
            testCase.verifySize(data.matrix, [2 3]);
            testCase.verifyEqual(data.matrix, [1 2 3; 4 5 6]);
        end

        function testYAMLMixedSequenceIsColumnCell(testCase)
            file = testCase.writeTempFile("t.yaml", ...
                ["items:"; "  - 1"; "  - hello"; "  - true"]);
            data = readyaml(file);
            testCase.verifyClass(data.items, "cell");
            testCase.verifySize(data.items, [3 1]);
        end
    end
end

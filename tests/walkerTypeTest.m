classdef walkerTypeTest < ConfigurationFileTestCase
    % Tests targeting C++ MatlabWalker type dispatch, N-D array nesting,
    % and whole-double conversion. Exercises specific code paths in
    % matlab_walker.cpp through the writetoml/writeyaml interface.

    methods (Access = private)
        function text = writeTomlAndRead(testCase, data)
            file = testCase.tempFile("out.toml");
            writetoml(data, file);
            text = string(fileread(file));
        end

        function text = writeYamlAndRead(testCase, data)
            file = testCase.tempFile("out.yaml");
            writeyaml(data, file);
            text = string(fileread(file));
        end
    end

    methods (Test)

        %% Matrix nesting (walkTypedArray, emitSequence)

        function testDoubleMatrixWritesAsNestedArray(testCase)
            config = tomldata();
            config.m = [1 2; 3 4];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[[1, 2], [3, 4]]");
        end

        function testColumnVectorWritesAsFlatArray(testCase)
            config = tomldata();
            config.v = [1; 2; 3];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[1, 2, 3]");
        end

        function testRowVectorWritesAsFlatArray(testCase)
            config = tomldata();
            config.v = [1, 2, 3];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[1, 2, 3]");
        end

        function test3DArrayWritesAsDeeplyNestedArray(testCase)
            config = tomldata();
            m = zeros(2, 2, 2);
            m(:,:,1) = [1 2; 3 4];
            m(:,:,2) = [5 6; 7 8];
            config.m = m;
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[[[1, 5], [2, 6]], [[3, 7], [4, 8]]]");
        end

        function testMatrixRoundTripPreservesValues(testCase)
            config = tomldata();
            config.m = [10 20 30; 40 50 60];
            file = testCase.tempFile("rt.toml");
            writetoml(config, file);
            data = readtoml(file);
            testCase.verifyEqual(data.m, [10 20 30; 40 50 60]);
        end

        %% Numeric type dispatch

        function testInt8WritesAsInteger(testCase)
            config = yamldata();
            config.v = int8([-128, 0, 127]);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "-128");
            testCase.verifySubstring(text, "127");
        end

        function testInt16WritesAsInteger(testCase)
            config = yamldata();
            config.v = int16(1000);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "1000");
        end

        function testInt32WritesAsInteger(testCase)
            config = yamldata();
            config.v = int32([-1, 0, 1]);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "-1");
        end

        function testInt64WritesAsInteger(testCase)
            config = tomldata();
            config.v = int64(9007199254740993);
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "9007199254740993");
        end

        function testUint8WritesAsInteger(testCase)
            config = yamldata();
            config.v = uint8([0, 255]);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "255");
        end

        function testUint16WritesAsInteger(testCase)
            config = yamldata();
            config.v = uint16(65535);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "65535");
        end

        function testUint32WritesAsInteger(testCase)
            config = yamldata();
            config.v = uint32(4000000000);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "4000000000");
        end

        function testUint64WritesAsInteger(testCase)
            config = yamldata();
            config.v = uint64(18446744073709551615);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "18446744073709551615");
        end

        function testSingleWritesAsNumber(testCase)
            config = yamldata();
            config.v = single([1.5, 2.5]);
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "1");
            testCase.verifySubstring(text, "2");
        end

        %% Whole-double conversion (doubles that look like integers)

        function testWholeDoubleWritesWithoutDecimalPoint(testCase)
            config = tomldata();
            config.v = 42.0;
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "v = 42");
            testCase.verifyTrue(~contains(text, "42.0"));
        end

        function testFractionalDoubleWritesAsFloat(testCase)
            config = tomldata();
            config.v = 3.14;
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "3.14");
        end

        %% Special floating-point values (YAML)

        function testInfWritesAsDotInf(testCase)
            config = yamldata();
            config.v = Inf;
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, ".inf");
        end

        function testNegInfWritesAsNegDotInf(testCase)
            config = yamldata();
            config.v = -Inf;
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, "-.inf");
        end

        function testNaNWritesAsDotNan(testCase)
            config = yamldata();
            config.v = NaN;
            text = testCase.writeYamlAndRead(config);
            testCase.verifySubstring(text, ".nan");
        end

        %% Logical arrays

        function testLogicalMatrixWritesAsNestedBools(testCase)
            config = tomldata();
            config.m = [true false; false true];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[[true, false], [false, true]]");
        end

        function testLogicalVectorWritesAsBools(testCase)
            config = tomldata();
            config.v = [true; false; true];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, "[true, false, true]");
        end

        %% String arrays

        function testStringVectorWritesAsArray(testCase)
            config = tomldata();
            config.v = ["hello"; "world"];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, '["hello", "world"]');
        end

        function testStringMatrixWritesAsNestedArray(testCase)
            config = tomldata();
            config.m = ["a" "b"; "c" "d"];
            text = testCase.writeTomlAndRead(config);
            testCase.verifySubstring(text, '[["a", "b"], ["c", "d"]]');
        end

        %% YAML matrix emission

        function testYAMLMatrixWritesAsNestedSequence(testCase)
            config = yamldata();
            config.m = [1 2; 3 4];
            text = testCase.writeYamlAndRead(config);
            data = readyaml(testCase.writeTempFile("rt.yaml", text));
            testCase.verifyEqual(data.m, [1 2; 3 4]);
        end

        function testYAMLLogicalMatrixRoundTrip(testCase)
            config = yamldata();
            config.m = [true false; false true];
            file = testCase.tempFile("rt.yaml");
            writeyaml(config, file);
            data = readyaml(file);
            testCase.verifyEqual(data.m, [true false; false true]);
        end
    end
end

classdef describeVisitorTest < matlab.unittest.TestCase
    % Tests for the describe visitors constructed directly, without the
    % Depth argument that describe() always supplies. The default is an
    % unlimited depth, so every level of a nested object is reported.
    %
    % The base ConfigurationVisitor.visitNode implementation is not tested
    % here: all three concrete visitors override it, so the inherited default
    % has no caller.

    methods(Access = private)
        function config = makeThreeLevelObject(~)
            config = yamldata();
            config.a.b.c = 1;
        end
    end

    methods(Test)
        function testTableVisitorDefaultsToUnlimitedDepth(testCase)
            visitor = matlab.io.config.internal.DescribeTableVisitor();
            config = testCase.makeThreeLevelObject();

            result = describeRoot(visitor, config);

            testCase.verifyEqual(string(result.Path)', ["a", "a.b", "a.b.c"], ...
                "Every level should be reported when no depth is given");
        end

        function testTextVisitorDefaultsToUnlimitedDepth(testCase)
            visitor = matlab.io.config.internal.DescribeTextVisitor();
            config = testCase.makeThreeLevelObject();

            result = describeRoot(visitor, config);

            testCase.verifySubstring(result, "c", ...
                "The deepest key should appear when no depth is given");
        end

        function testTableVisitorHonorsAnExplicitDepth(testCase)
            visitor = matlab.io.config.internal.DescribeTableVisitor(1);
            config = testCase.makeThreeLevelObject();

            result = describeRoot(visitor, config);

            testCase.verifyEqual(string(result.Path)', "a", ...
                "A depth of one should stop after the first level");
        end
    end
end

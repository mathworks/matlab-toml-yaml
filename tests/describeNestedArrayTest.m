classdef describeNestedArrayTest < matlab.unittest.TestCase
    % Tests for describe() paths the main describeTest suite does not reach:
    % object arrays holding nested object arrays, depth limiting at the root
    % of an array, and sections with no keys.

    methods(Access = private)
        function pair = makeArrayWithNestedArray(~)
            % A 1x2 object array whose "endpoints" key holds a 1x2 array.
            endpoint = yamldata();
            endpoint.path = "/health";
            endpoint.method = "GET";
            endpoints = [endpoint, endpoint];

            service = yamldata();
            service.name = "api";
            service.endpoints = endpoints;

            pair = [service, service];
        end
    end

    methods(Test)
        % --- Nested arrays inside array elements ---------------------------

        function testTextDescribeReportsNestedArrayDimensions(testCase)
            pair = testCase.makeArrayWithNestedArray();

            output = evalc("describe(pair)");

            testCase.verifySubstring(output, "1x2 array", ...
                "The root array dimensions should be reported");
            testCase.verifySubstring(output, "2 keys each", ...
                "The nested array's key count should be reported");
        end

        function testTableDescribeIncludesNestedArrayRow(testCase)
            pair = testCase.makeArrayWithNestedArray();

            result = describe(pair);

            testCase.verifyClass(result, "table");
            testCase.verifyTrue(any(result.Path == "endpoints"), ...
                "The nested array key should appear as a row");
        end

        function testNestedArrayKeyCountUnionsAcrossElements(testCase)
            % The nested array's key count is the union over its elements,
            % so a key present in only one element still counts.
            first = yamldata();
            first.path = "/a";
            second = yamldata();
            second.path = "/b";
            second.deprecated = true;

            service = yamldata();
            service.endpoints = [first, second];
            pair = [service, service];

            output = evalc("describe(pair)");

            testCase.verifySubstring(output, "2 keys each", ...
                "path and deprecated should both be counted");
        end

        % --- Depth limiting ------------------------------------------------

        function testDepthOneOnArrayRootOmitsChildKeys(testCase)
            % At Depth=1 the array root reports only its dimensions, taking
            % the branch that produces no child lines.
            pair = testCase.makeArrayWithNestedArray();

            output = evalc("describe(pair, Depth=1)");

            testCase.verifySubstring(output, "1x2 array", ...
                "The dimensions should still be shown");
            testCase.verifyFalse(contains(output, "endpoints"), ...
                "Depth=1 should not list the element keys");
        end

        function testDepthOneOnScalarReportsKeyCountOnly(testCase)
            config = yamldata();
            config.section.inner = 1;

            output = evalc("describe(config, Depth=1)");

            testCase.verifySubstring(output, "(1 key)", ...
                "A depth-limited nested object shows its key count");
            testCase.verifyFalse(contains(output, "inner"), ...
                "Depth=1 should not descend into the section");
        end

        function testDepthLimitedNestedArrayShowsKeysEach(testCase)
            pair = testCase.makeArrayWithNestedArray();

            output = evalc("describe(pair(1), Depth=1)");

            testCase.verifySubstring(output, "keys each", ...
                "A depth-limited nested array reports keys per element");
        end

        % --- Sections with no keys -----------------------------------------

        function testEmptySectionRendersNoKeys(testCase)
            config = yamldata();
            config.name = "app";
            config.section = yamldata();

            output = evalc('describe(config)');

            testCase.verifySubstring(output, "(no keys)", ...
                "An empty nested section should render as '(no keys)'");
        end

        function testEmptySectionWorksInTableForm(testCase)
            % The table form does not go through the text line assembly, so
            % it handles the shape that #38 breaks on.
            config = yamldata();
            config.name = "app";
            config.section = yamldata();

            result = describe(config);

            testCase.verifyClass(result, "table");
            testCase.verifyTrue(any(result.Path == "section"), ...
                "The empty section should appear as a row");
        end

        function testObjectWithNoKeysDescribes(testCase)
            config = yamldata();

            output = evalc("describe(config)");

            testCase.verifySubstring(output, "with no keys");
        end
    end
end

classdef methodsTest < matlab.unittest.TestCase
    % Tests for YAMLData/TOMLData methods

    properties(TestParameter)
        object = {yamldata(), tomldata()};
    end

    methods(Test)
        % Reduce tab-completion clutter due to public methods.
        function testMethodsList(testCase, object)
            mlist = methods(object);
            testCase.verifyEqual(mlist, {extractAfter(class(object), 'matlab.io.config.')});
        end

        % Make sure only the intended properties are public.
        function testPropertiesList(testCase, object)
            plist = string(properties(object));
            testCase.verifyEmpty(plist);
        end

        % Add a key and verify that properties updates correctly.
        function testAddPropertiesList(testCase, object)
            object.A = 5;
            plist = string(properties(object));
            testCase.verifyEqual(plist, "A");
        end
    end
end
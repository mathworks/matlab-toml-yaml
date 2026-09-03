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

        % Array-of-objects case.
        function testArrayOfObjects(testCase, object)
            object = [object object];
            object(1).A = 5;
            object(2).B = 3;
            plist = string(properties(object));
            testCase.verifyEqual(plist, ["A" "B"]');
        end
    end
end
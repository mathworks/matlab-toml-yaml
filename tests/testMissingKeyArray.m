classdef testMissingKeyArray < matlab.unittest.TestCase
    % Tests for missing key behavior on scalar and array ConfigurationData
    % objects.

    methods (Test)
        function scalarMissingKeyErrors(testCase)
            t = tomldata;
            t.newkey = "my key";
            testCase.verifyError(@() t.notakey, ...
                "ConfigurationData:InvalidKey");
        end

        function arrayElementMissingKeyErrors(testCase)
            t = tomldata;
            t.newkey = "my key";
            t(2) = tomldata;
            testCase.verifyError(@() t(2).notakey, ...
                "ConfigurationData:InvalidKey");
        end

        function arrayAllMissingKeyErrors(testCase)
            t = tomldata;
            t.newkey = "my key";
            t(2) = tomldata;
            testCase.verifyError(@() t.notakey, ...
                "ConfigurationData:InvalidKey");
        end

        function arrayPartialKeyReturnsMixed(testCase)
            t = tomldata;
            t.sensor = "temperature";
            t(2) = tomldata;
            t(2).location = "lab";

            val = t.sensor;
            testCase.verifyLength(val, 2);
            testCase.verifyEqual(val(1), "temperature");
            testCase.verifyTrue(ismissing(val(2)));
        end

        function arrayFullKeyReturnsAll(testCase)
            t = tomldata;
            t.sensor = "temperature";
            t(2) = tomldata;
            t(2).sensor = "pressure";

            val = t.sensor;
            testCase.verifyEqual(val, ["temperature", "pressure"]);
        end
    end
end

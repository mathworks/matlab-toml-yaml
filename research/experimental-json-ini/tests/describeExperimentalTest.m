classdef describeExperimentalTest < matlab.unittest.TestCase
    % describe() coverage that is specific to the experimental JSON/INI
    % formats. The format-neutral describe() behavior is covered by
    % tests/describeTest.m; this file holds only the cases that depend on
    % JSONData/INIData or read JSON sample files.

    methods (TestClassSetup)
        function addToPath(testCase)
            % Experimental code lives alongside the shipped toolbox on the path.
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../../toolbox'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('..'));
        end
    end

    methods (Test)

        function testRealPackageJSON(testCase)
            % Verify structure of a real sample file
            sampleDir = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles');
            pkg = readjson(fullfile(sampleDir, '01_package.json'));

            output = evalc('describe(pkg)');

            testCase.verifySubstring(output, 'JSONData with 14 keys');
            testCase.verifySubstring(output, '"acme-webapp" (string)');
            testCase.verifySubstring(output, 'engines:');
            testCase.verifySubstring(output, 'scripts:');
            testCase.verifySubstring(output, 'dependencies:');
            testCase.verifySubstring(output, 'browserslist:');
            testCase.verifySubstring(output, 'string');
        end

        function testAllSubclasses(testCase)
            % Verify class names for the experimental subclasses
            json = jsondata(); json.key = "val";
            ini = inidata();  ini.key = "val";

            outputJSON = evalc('describe(json)');
            outputINI  = evalc('describe(ini)');

            testCase.verifySubstring(outputJSON, 'JSONData');
            testCase.verifySubstring(outputINI,  'INIData');
        end

        function testK8sDeployment(testCase)
            % Deep nesting with arrays (k8s deployment)
            sampleDir = fullfile(fileparts(mfilename('fullpath')), 'SampleFiles');
            k8s = readjson(fullfile(sampleDir, '08_k8s_deployment.json'));

            output = evalc('describe(k8s)');

            testCase.verifySubstring(output, 'JSONData with 4 keys');
            testCase.verifySubstring(output, '"apps/v1" (string)');
            testCase.verifySubstring(output, '"Deployment" (string)');
            testCase.verifySubstring(output, 'containers:');
            testCase.verifySubstring(output, '2x1 array');
            testCase.verifySubstring(output, 'livenessProbe:');
        end

    end
end

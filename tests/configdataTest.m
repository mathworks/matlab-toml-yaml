classdef configdataTest < matlab.unittest.TestCase
    %CONFIGDATATEST Tests for configdata(), merge(), select(), and general
    %   ConfigurationData as a format-neutral hierarchical data container.

    properties (TestParameter)
    end

    methods (TestMethodSetup)
        function addToolboxPath(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture('../toolbox'));
        end
    end

    %% configdata() constructor
    methods (Test)

        function testConfigdataEmpty(testCase)
            d = configdata();
            testCase.verifyClass(d, 'matlab.io.config.ConfigurationData');
            testCase.verifyEmpty(keys(d));
        end

        function testConfigdataFromStruct(testCase)
            s.name = "Alice";
            s.score = 95;
            d = configdata(s);
            testCase.verifyEqual(d.name, "Alice");
            testCase.verifyEqual(d.score, 95);
        end

        function testConfigdataFromStructArray(testCase)
            % dir()-style use case: struct array → ConfigurationData array
            s(1).name = "file1.m"; s(1).bytes = 100;
            s(2).name = "file2.m"; s(2).bytes = 5000;
            s(3).name = "file3.m"; s(3).bytes = 200;
            files = configdata(s);
            testCase.verifySize(files, [1 3]);
            names = files.name;
            testCase.verifyEqual(names, ["file1.m", "file2.m", "file3.m"]);
        end

        function testConfigdataFilterArrayByField(testCase)
            s(1).name = "file1.m"; s(1).bytes = 100;
            s(2).name = "file2.m"; s(2).bytes = 5000;
            s(3).name = "file3.m"; s(3).bytes = 200;
            files = configdata(s);
            big = files(files.bytes > 1000);
            testCase.verifySize(big, [1 1]);
            testCase.verifyEqual(big.name, "file2.m");
        end

        function testConfigdataDotAssignAndAccess(testCase)
            d = configdata();
            d.name = "test";
            d.value = 42;
            testCase.verifyEqual(d.name, "test");
            testCase.verifyEqual(d.value, 42);
        end

        function testConfigdataNestedCreation(testCase)
            d = configdata();
            d.database.host = "localhost";
            d.database.port = 5432;
            testCase.verifyEqual(d.database.host, "localhost");
            testCase.verifyEqual(d.database.port, 5432);
        end

        function testConfigdataIsConcreteClass(testCase)
            % ConfigurationData should be directly instantiable now
            d = matlab.io.config.ConfigurationData();
            testCase.verifyClass(d, 'matlab.io.config.ConfigurationData');
        end

    end

    %% Type flexibility for format-neutral objects
    methods (Test)

        function testConfigdataAcceptsTable(testCase)
            d = configdata();
            t = table(["a";"b"], [1;2], VariableNames=["label","value"]);
            % Should not throw for format-neutral configdata
            d.results = t;
            testCase.verifyEqual(d.results, t);
        end

        function testConfigdataAcceptsComplexNumbers(testCase)
            d = configdata();
            d.impedance = 3 + 4i;
            testCase.verifyEqual(d.impedance, 3 + 4i);
        end

        function testConfigdataAcceptsCategorical(testCase)
            d = configdata();
            c = categorical(["a", "b", "a"]);
            d.labels = c;
            % Arrays are normalized to column vectors (Issue #77)
            testCase.verifyEqual(d.labels, categorical(["a"; "b"; "a"]));
        end

        function testYamldataStillRejectsTable(testCase)
            % Format-specific subclasses should still enforce type restrictions
            d = yamldata();
            t = table(["a";"b"], [1;2], VariableNames=["label","value"]);
            testCase.verifyError(@() assignTable(d, t), 'ConfigurationData:InvalidType');
        end

        function testYamldataStillRejectsComplexNumbers(testCase)
            d = yamldata();
            testCase.verifyError(@() assignComplex(d), 'ConfigurationData:InvalidType');
        end

    end

    %% merge()
    methods (Test)

        function testMergeBasicOverride(testCase)
            base = configdata(); base.a = 1; base.b = 2; base.c = 3;
            override = configdata(); override.b = 99;
            result = merge(base, override);
            testCase.verifyEqual(result.a, 1);   % from base
            testCase.verifyEqual(result.b, 99);  % overridden
            testCase.verifyEqual(result.c, 3);   % from base
        end

        function testMergeAddsNewKeysFromOverride(testCase)
            base = configdata(); base.a = 1;
            override = configdata(); override.newKey = "hello";
            result = merge(base, override);
            testCase.verifyEqual(result.a, 1);
            testCase.verifyEqual(result.newKey, "hello");
        end

        function testMergeDeepNested(testCase)
            base = configdata();
            base.database.host = "localhost";
            base.database.port = 5432;
            base.timeout = 30;

            override = configdata();
            override.database.host = "prod-db";  % override one nested key

            result = merge(base, override);
            testCase.verifyEqual(result.database.host, "prod-db");  % overridden
            testCase.verifyEqual(result.database.port, 5432);        % preserved from base
            testCase.verifyEqual(result.timeout, 30);                 % preserved from base
        end

        function testMergeArraysAreAtomic(testCase)
            % Arrays should be replaced, not concatenated
            base = configdata(); base.tags = ["a", "b", "c"];
            override = configdata(); override.tags = ["x", "y"];
            result = merge(base, override);
            % Arrays are normalized to column vectors (Issue #77)
            testCase.verifyEqual(result.tags, ["x"; "y"]);
        end

        function testMergePreservesBaseClass(testCase)
            base = yamldata(); base.x = 1;
            override = yamldata(); override.y = 2;
            result = merge(base, override);
            testCase.verifyClass(result, 'matlab.io.config.YAMLData');
        end

        function testMergeBaseUnmodified(testCase)
            % merge is non-destructive — base should not change
            base = configdata(); base.a = 1; base.b = 2;
            override = configdata(); override.b = 99; override.c = 3;
            merge(base, override);
            testCase.verifyEqual(base.b, 2);   % base still has original value
            testCase.verifyFalse(iskey(base, "c"));
        end

        function testMergeLayeredConfig(testCase)
            % Three-layer merge: system → env → user
            system = configdata(); system.timeout = 30; system.retries = 3; system.debug = false;
            env = configdata(); env.timeout = 60;
            user = configdata(); user.debug = true;

            config = merge(merge(system, env), user);
            testCase.verifyEqual(config.timeout, 60);    % from env
            testCase.verifyEqual(config.retries, 3);     % from system
            testCase.verifyTrue(config.debug);            % from user
        end

    end

    %% select()
    methods (Test)

        function testSelectBasic(testCase)
            config = configdata();
            config.host = "localhost";
            config.port = 8080;
            config.debug = true;
            config.secret = "abc";

            network = select(config, ["host", "port"]);
            testCase.verifyEqual(keys(network), ["host", "port"]);
            testCase.verifyEqual(network.host, "localhost");
            testCase.verifyEqual(network.port, 8080);
            testCase.verifyFalse(iskey(network, "debug"));
            testCase.verifyFalse(iskey(network, "secret"));
        end

        function testSelectPreservesOrder(testCase)
            config = configdata();
            config.a = 1; config.b = 2; config.c = 3; config.d = 4;
            result = select(config, ["c", "a"]);
            % Should follow the order of selectedKeys, not original insertion order
            testCase.verifyEqual(keys(result), ["c", "a"]);
        end

        function testSelectSingleKey(testCase)
            config = configdata(); config.x = 42; config.y = 99;
            result = select(config, "x");
            testCase.verifyEqual(numel(keys(result)), 1);
            testCase.verifyEqual(result.x, 42);
        end

        function testSelectErrorOnMissingKey(testCase)
            config = configdata(); config.a = 1;
            testCase.verifyError(@() select(config, "nonexistent"), ...
                'ConfigurationData:InvalidKey');
        end

        function testSelectPreservesClass(testCase)
            y = yamldata(); y.a = 1; y.b = 2;
            result = select(y, "a");
            testCase.verifyClass(result, 'matlab.io.config.YAMLData');
        end

        function testSelectOriginalUnmodified(testCase)
            config = configdata(); config.a = 1; config.b = 2;
            select(config, "a");
            testCase.verifyTrue(iskey(config, "b"));  % original unchanged
        end

    end

    %% show() on base class
    methods (Test)

        function testShowOnConfigdata(testCase)
            d = configdata(); d.x = 1; d.name = "hello";
            % show() should not error — it delegates to describe()
            testCase.verifyWarningFree(@() show(d));
        end

    end

end

%% Local helpers for error-testing lambdas
function assignTable(d, t)
    d.results = t;
end

function assignComplex(d)
    d.z = 1 + 2i;
end

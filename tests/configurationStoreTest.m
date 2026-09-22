classdef configurationStoreTest < matlab.unittest.TestCase
    % Shared contract tests for ConfigurationStore implementations.
    % Each subclass should pass all tests when added to the factory parameter.

    properties (TestParameter)
        factory = struct( ...
            NodeTree = struct( ...
                make = @() matlab.io.config.internal.NodeTreeStore.empty(), ...
                fromNodeTree = @(varargin) matlab.io.config.internal.NodeTreeStore.fromNodeTree(varargin{:})))
    end

    methods (Test)

        %% Empty store

        function emptyStoreHasNoKeys(testCase, factory)
            store = factory.make();
            testCase.verifyEmpty(allKeys(store));
            testCase.verifyEqual(numKeys(store), 0);
            testCase.verifyFalse(hasKey(store, "anything"));
        end

        %% setValue and getValue

        function setAndGetDouble(testCase, factory)
            store = factory.make();
            store = setValue(store, "port", 8080);
            testCase.verifyEqual(getValue(store, "port"), 8080);
        end

        function setAndGetString(testCase, factory)
            store = factory.make();
            store = setValue(store, "host", "localhost");
            testCase.verifyEqual(getValue(store, "host"), "localhost");
        end

        function setAndGetLogical(testCase, factory)
            store = factory.make();
            store = setValue(store, "debug", true);
            testCase.verifyEqual(getValue(store, "debug"), true);
        end

        function setAndGetArray(testCase, factory)
            store = factory.make();
            store = setValue(store, "ports", [80; 443; 8080]);
            testCase.verifyEqual(getValue(store, "ports"), [80; 443; 8080]);
        end

        function setAndGetCell(testCase, factory)
            store = factory.make();
            store = setValue(store, "mixed", {1, "two", true});
            testCase.verifyEqual(getValue(store, "mixed"), {1, "two", true});
        end

        function setAndGetMissing(testCase, factory)
            store = factory.make();
            store = setValue(store, "empty", missing);
            testCase.verifyClass(getValue(store, "empty"), "missing");
        end

        function setAndGetNestedObject(testCase, factory)
            store = factory.make();
            inner = tomldata(struct("port", 8080));
            store = setValue(store, "server", inner);
            result = getValue(store, "server");
            testCase.verifyClass(result, "matlab.io.config.TOMLData");
            testCase.verifyEqual(result.port, 8080);
        end

        %% hasKey

        function hasKeyTrueForExisting(testCase, factory)
            store = factory.make();
            store = setValue(store, "key", 1);
            testCase.verifyTrue(hasKey(store, "key"));
        end

        function hasKeyFalseForAbsent(testCase, factory)
            store = factory.make();
            store = setValue(store, "key", 1);
            testCase.verifyFalse(hasKey(store, "other"));
        end

        %% Key ordering

        function keysPreserveInsertionOrder(testCase, factory)
            store = factory.make();
            store = setValue(store, "b", 2);
            store = setValue(store, "a", 1);
            store = setValue(store, "c", 3);
            testCase.verifyEqual(allKeys(store), ["b", "a", "c"]);
        end

        function overwritePreservesKeyPosition(testCase, factory)
            store = factory.make();
            store = setValue(store, "a", 1);
            store = setValue(store, "b", 2);
            store = setValue(store, "a", 99);
            testCase.verifyEqual(allKeys(store), ["a", "b"]);
            testCase.verifyEqual(getValue(store, "a"), 99);
        end

        %% numKeys

        function numKeysAfterInsertions(testCase, factory)
            store = factory.make();
            store = setValue(store, "a", 1);
            store = setValue(store, "b", 2);
            testCase.verifyEqual(numKeys(store), 2);
        end

        function numKeysAfterRemoval(testCase, factory)
            store = factory.make();
            store = setValue(store, "a", 1);
            store = setValue(store, "b", 2);
            store = removeKey(store, "a");
            testCase.verifyEqual(numKeys(store), 1);
        end

        %% removeKey

        function removeKeyDeletesEntry(testCase, factory)
            store = factory.make();
            store = setValue(store, "a", 1);
            store = setValue(store, "b", 2);
            store = removeKey(store, "a");
            testCase.verifyFalse(hasKey(store, "a"));
            testCase.verifyTrue(hasKey(store, "b"));
            testCase.verifyEqual(allKeys(store), "b");
        end

        %% Value semantics

        function copyIsIndependent(testCase, factory)
            store = factory.make();
            store = setValue(store, "a", 1);
            copy = store;
            copy = setValue(copy, "a", 99);
            testCase.verifyEqual(getValue(store, "a"), 1, ...
                "Original should not change when copy is modified");
        end

        %% fromNodeTree

        function fromNodeTreeScalarValues(testCase, factory)
            tree = makeNodeTree( ...
                Keys = ["port", "host", "debug"], ...
                Values = {8080, "localhost", true});
            store = factory.fromNodeTree(tree, "toml");
            testCase.verifyEqual(getValue(store, "port"), 8080);
            testCase.verifyEqual(getValue(store, "host"), "localhost");
            testCase.verifyEqual(getValue(store, "debug"), true);
        end

        function fromNodeTreeNullValues(testCase, factory)
            tree = makeNodeTree( ...
                Keys = ["a", "b"], ...
                Values = {1, struct("Data", [], "Type", "missing")});
            store = factory.fromNodeTree(tree, "toml");
            testCase.verifyEqual(getValue(store, "a"), 1);
            testCase.verifyClass(getValue(store, "b"), "missing");
        end

        function fromNodeTreeDatetimeValues(testCase, factory)
            tree = makeNodeTree( ...
                Keys = "created", ...
                Values = {struct("Data", "2024-01-15T10:30:00Z", ...
                    "Type", "datetime")});
            store = factory.fromNodeTree(tree, "toml");
            result = getValue(store, "created");
            testCase.verifyClass(result, "datetime");
        end

        function fromNodeTreeNestedTable(testCase, factory)
            inner = makeNodeTree( ...
                Keys = "port", Values = {8080});
            tree = makeNodeTree( ...
                Keys = "server", Values = {inner});
            store = factory.fromNodeTree(tree, "toml");
            nested = getValue(store, "server");
            testCase.verifyClass(nested, "matlab.io.config.TOMLData");
            testCase.verifyEqual(nested.port, 8080);
        end

        function fromNodeTreeArrayOfTables(testCase, factory)
            child1 = makeNodeTree(Keys = "name", Values = {"Alice"});
            child2 = makeNodeTree(Keys = "name", Values = {"Bob"});
            tree = makeNodeTree( ...
                Keys = "people", ...
                Values = {{child1, child2}});
            store = factory.fromNodeTree(tree, "toml");
            arr = getValue(store, "people");
            testCase.verifyClass(arr, "matlab.io.config.TOMLData");
            testCase.verifyNumElements(arr, 2);
        end

        function fromNodeTreePreservesKeyOrder(testCase, factory)
            tree = makeNodeTree( ...
                Keys = ["z", "a", "m"], ...
                Values = {1, 2, 3});
            store = factory.fromNodeTree(tree, "toml");
            testCase.verifyEqual(allKeys(store), ["z", "a", "m"]);
        end

        function fromNodeTreeYAMLCreatesYAMLData(testCase, factory)
            inner = makeNodeTree( ...
                Keys = "port", Values = {8080});
            tree = makeNodeTree( ...
                Keys = "server", Values = {inner});
            store = factory.fromNodeTree(tree, "yaml");
            nested = getValue(store, "server");
            testCase.verifyClass(nested, "matlab.io.config.YAMLData");
        end
    end
end

function tree = makeNodeTree(options)
    arguments
        options.Keys (1,:) string = string.empty
        options.Values (1,:) cell = {}
    end
    tree = struct("Keys", options.Keys, "Values", {options.Values});
end

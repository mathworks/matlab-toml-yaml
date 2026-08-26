classdef subsasgnTest < matlab.unittest.TestCase
    % Tests for subsasgn behavior (using YAMLData as concrete implementation)

    methods (TestMethodSetup)
        function setupPath(testCase)
            addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'toolbox'));
        end
    end

    methods (Test)
        %% Core subsasgn tests
        function testAssignToArrayElementField(testCase)
            % Test: data.items(2).name = "New"
            data = yamldata();
            data.items = [yamldata(), yamldata()];
            data.items(1).name = "First";
            data.items(2).name = "Second";

            data.items(2).name = "Changed";
            testCase.verifyEqual(data.items(2).name, "Changed");
            testCase.verifyEqual(data.items(1).name, "First");  % Unchanged
        end

        function testAssignNestedFieldInArrayElement(testCase)
            % Test: data.items(1).nested.value = 42
            data = yamldata();
            data.items = [yamldata(), yamldata()];
            data.items(1).nested.value = 42;
            testCase.verifyEqual(data.items(1).nested.value, 42);
        end

        function testAssignDeepChainThroughArrayElement(testCase)
            % Test: data.items(1).a.b.c = "deep"
            data = yamldata();
            data.items = [yamldata()];
            data.items(1).a.b.c = "deep";
            testCase.verifyEqual(data.items(1).a.b.c, "deep");
        end

        function testDirectElementReplacement(testCase)
            % Test: data.items(2) = newElement (no further chaining)
            data = yamldata();
            data.items = [yamldata(), yamldata()];
            data.items(1).x = 1;
            data.items(2).x = 2;

            newElem = yamldata();
            newElem.x = 99;
            data.items(2) = newElem;

            testCase.verifyEqual(data.items(2).x, 99);
            testCase.verifyEqual(data.items(1).x, 1);  % Unchanged
        end

        %% Regression tests - ensure existing patterns still work
        function testSimpleDotAssign(testCase)
            data = yamldata();
            data.title = "Test";
            testCase.verifyEqual(data.title, "Test");
        end

        function testChainedDotAssign(testCase)
            data = yamldata();
            data.a.b.c = "deep";
            testCase.verifyEqual(data.a.b.c, "deep");
        end

        %% Subclass validation - TOMLData
        function testTOMLDataInheritsSubsasgn(testCase)
            data = tomldata();
            data.items = [tomldata(), tomldata()];
            data.items(1).name = "Alice";
            data.items(2).name = "Bob";

            data.items(2).name = "Charlie";
            testCase.verifyEqual(data.items(2).name, "Charlie");
        end

        %% Subclass validation - YAMLData
        function testYAMLDataInheritsSubsasgn(testCase)
            data = yamldata();
            data.items = [yamldata(), yamldata()];
            data.items(1).value = 10;
            data.items(2).value = 20;

            data.items(2).value = 99;
            testCase.verifyEqual(data.items(2).value, 99);
        end

        %% Reserved name collision tests (Issue #14)
        % With OverridesPublicDotMethodCall, users can have keys that match
        % method names. The key takes priority over the method when using
        % dot notation. Methods must be called with function syntax.

        function testKeyNamedKeys(testCase)
            % Test: user can create a key named "keys"
            data = yamldata();
            data.keys = "my keys value";

            % Dot notation returns the data key, not the method
            testCase.verifyEqual(data.keys, "my keys value");

            % Function syntax still calls the method
            allKeys = keys(data);
            testCase.verifyEqual(allKeys, "keys");
        end

        function testKeyNamedIsfield(testCase)
            % Test: user can create a key named "isfield"
            data = yamldata();
            data.isfield = true;

            % Dot notation returns the data key
            testCase.verifyEqual(data.isfield, true);

            % Function syntax still works for the method
            testCase.verifyTrue(isfield(data, "isfield"));
        end

        function testKeyNamedShow(testCase)
            % Test: user can create a key named "show"
            data = yamldata();
            data.show = "my show value";

            % Dot notation returns the data key
            testCase.verifyEqual(data.show, "my show value");
        end

        function testKeyNamedStruct(testCase)
            % Test: user can create a key named "struct"
            data = yamldata();
            data.struct = "struct value";

            % Dot notation returns the data key
            testCase.verifyEqual(data.struct, "struct value");

            % Function syntax still works for conversion
            s = struct(data);
            testCase.verifyTrue(isstruct(s));
            testCase.verifyEqual(s.struct, "struct value");
        end

        function testKeyNamedIskey(testCase)
            % Test: user can create a key named "iskey"
            data = yamldata();
            data.iskey = "iskey value";

            % Dot notation returns the data key
            testCase.verifyEqual(data.iskey, "iskey value");

            % Function syntax still calls the method, not the key
            testCase.verifyTrue(iskey(data, "iskey"));
        end

        function testMultipleReservedNames(testCase)
            % Test: multiple reserved names can coexist
            data = yamldata();
            data.keys = ["key1", "key2"];
            data.isfield = false;
            data.struct = "struct value";
            data.normal = "normal value";

            % All values accessible via dot notation
            % Arrays are normalized to column vectors (Issue #77)
            testCase.verifyEqual(data.keys, ["key1"; "key2"]);
            testCase.verifyEqual(data.isfield, false);
            testCase.verifyEqual(data.struct, "struct value");
            testCase.verifyEqual(data.normal, "normal value");

            % Method still works via function syntax
            allKeys = keys(data);
            testCase.verifyEqual(sort(allKeys), sort(["keys", "isfield", "struct", "normal"]));
        end

        function testReservedNameInYAMLData(testCase)
            % Test: reserved names work in YAMLData subclass
            data = yamldata();
            data.keys = "yaml keys";

            testCase.verifyEqual(data.keys, "yaml keys");
            testCase.verifyEqual(keys(data), "keys");
        end

        function testReservedNameInTOMLData(testCase)
            % Test: reserved names work in TOMLData subclass
            data = tomldata();
            data.keys = "toml keys";

            testCase.verifyEqual(data.keys, "toml keys");
            testCase.verifyEqual(keys(data), "keys");
        end

        %% Array dot reference tests
        % Enable arr.field syntax on arrays of ConfigurationData

        function testArrayDotReferenceStrings(testCase)
            % Test: arr.field returns string array when all values are strings
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(2).name = "Bob";
            arr(3).name = "Charlie";

            names = arr.name;
            testCase.verifyClass(names, "string");
            testCase.verifyEqual(names, ["Alice", "Bob", "Charlie"]);
        end

        function testArrayDotReferenceNumbers(testCase)
            % Test: arr.field returns numeric array when all values are numbers
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            values = arr.value;
            testCase.verifyClass(values, "double");
            testCase.verifyEqual(values, [10, 20, 30]);
        end

        function testArrayDotReferenceLogicals(testCase)
            % Test: arr.field returns logical array when all values are logicals
            arr = [tomldata(), tomldata()];
            arr(1).active = true;
            arr(2).active = false;

            actives = arr.active;
            testCase.verifyClass(actives, "logical");
            testCase.verifyEqual(actives, [true, false]);
        end

        function testArrayDotReferenceNestedObjects(testCase)
            % Test: arr.field returns ConfigurationData array for nested objects
            arr = [yamldata(), yamldata()];
            arr(1).config.value = 1;
            arr(2).config.value = 2;

            configs = arr.config;
            testCase.verifyClass(configs, "matlab.io.config.YAMLData");
            testCase.verifySize(configs, [1, 2]);
            testCase.verifyEqual(configs(1).value, 1);
            testCase.verifyEqual(configs(2).value, 2);
        end

        function testArrayDotReferenceChained(testCase)
            % Test: arr.field1.field2 works for chained access
            arr = [yamldata(), yamldata()];
            arr(1).settings.enabled = true;
            arr(2).settings.enabled = false;

            enabled = arr.settings.enabled;
            testCase.verifyClass(enabled, "logical");
            testCase.verifyEqual(enabled, [true, false]);
        end

        function testArrayDotReferenceMissingKeyError(testCase)
            % Test: missing returned when key absent in some elements (Issue #74)
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(3).name = "Charlie";
            % arr(2) has no "name" key

            % Should return ["Alice", missing, "Charlie"] without error
            names = arr.name;
            testCase.verifyEqual(numel(names), 3);
            testCase.verifyEqual(names(1), "Alice");
            testCase.verifyTrue(ismissing(names(2)));
            testCase.verifyEqual(names(3), "Charlie");

            % Verify key not actually added to arr(2)
            testCase.verifyFalse(iskey(arr(2), "name"));
        end

        function testArrayDotReferenceTypeMismatchError(testCase)
            % Test: error when types differ across elements
            arr = [yamldata(), yamldata()];
            arr(1).value = 42;       % double
            arr(2).value = "text";   % string

            testCase.verifyError(@() arr.value, 'ConfigurationData:TypeMismatch');
        end

        function testIsKeyVectorized(testCase)
            % Test: iskey returns logical array for arrays
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(1).email = "alice@test.com";
            arr(2).name = "Bob";
            % arr(2) has no email
            arr(3).name = "Charlie";
            arr(3).email = "charlie@test.com";

            % All have name
            hasName = iskey(arr, "name");
            testCase.verifyClass(hasName, "logical");
            testCase.verifyEqual(hasName, [true, true, true]);

            % Only 1 and 3 have email
            hasEmail = iskey(arr, "email");
            testCase.verifyEqual(hasEmail, [true, false, true]);
        end

        function testIsfieldDelegatesToIskey(testCase)
            % Test: isfield behaves same as iskey
            arr = [tomldata(), tomldata()];
            arr(1).x = 1;
            arr(2).x = 2;

            testCase.verifyEqual(isfield(arr, "x"), iskey(arr, "x"));
            testCase.verifyEqual(isfield(arr, "y"), iskey(arr, "y"));
        end

        function testFilterWithIskey(testCase)
            % Test: can filter array using iskey results
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(1).score = 100;
            arr(2).name = "Bob";
            % arr(2) has no score
            arr(3).name = "Charlie";
            arr(3).score = 85;

            hasScore = iskey(arr, "score");
            filtered = arr(hasScore);

            testCase.verifySize(filtered, [1, 2]);
            testCase.verifyEqual(filtered.name, ["Alice", "Charlie"]);
            testCase.verifyEqual(filtered.score, [100, 85]);
        end

        function testArrayDotReferenceWithLogicalFilter(testCase)
            % Test: arr.field(logicalMask) pre-filters array before key check
            % This enables the pattern: arr.field(iskey(arr, "field"))
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(1).score = 100;
            arr(2).name = "Bob";
            % arr(2) has no score - this is the heterogeneous case
            arr(3).name = "Charlie";
            arr(3).score = 85;

            % Direct access now returns [100, NaN, 85] (missing coerces to NaN for double)
            allScores = arr.score;
            testCase.verifyEqual(allScores(1), 100);
            testCase.verifyTrue(isnan(allScores(2)));  % missing becomes NaN for double
            testCase.verifyEqual(allScores(3), 85);

            % arr.score(logicalMask) pre-filters and returns only existing values
            hasScore = iskey(arr, "score");
            scores = arr.score(hasScore);  % This should NOT error
            testCase.verifyEqual(scores, [100, 85]);

            % Verify the logical mask is as expected
            testCase.verifyEqual(hasScore, [true, false, true]);
        end

        function testArrayDotAssignWithLogicalFilterScalar(testCase)
            % Test: arr.field(logicalMask) = scalarValue broadcasts
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(1).active = true;
            arr(2).name = "Bob";
            % arr(2) has no active
            arr(3).name = "Charlie";
            arr(3).active = false;

            hasActive = iskey(arr, "active");
            arr.active(hasActive) = true;  % Broadcast scalar to filtered elements

            testCase.verifyEqual(arr(1).active, true);
            testCase.verifyEqual(arr(3).active, true);
            % arr(2) still has no active key
            testCase.verifyFalse(iskey(arr(2), "active"));
        end

        function testArrayDotAssignWithLogicalFilterArray(testCase)
            % Test: arr.field(logicalMask) = arrayValue assigns element-wise
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(1).score = 100;
            arr(2).name = "Bob";
            % arr(2) has no score
            arr(3).name = "Charlie";
            arr(3).score = 85;

            hasScore = iskey(arr, "score");
            arr.score(hasScore) = [200, 300];  % Assign element-wise

            testCase.verifyEqual(arr(1).score, 200);
            testCase.verifyEqual(arr(3).score, 300);
            testCase.verifyFalse(iskey(arr(2), "score"));
        end

        function testScalarBehaviorUnchanged(testCase)
            % Test: scalar access still works as before
            arr = [yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(2).name = "Bob";

            % Index first, then access
            testCase.verifyEqual(arr(1).name, "Alice");
            testCase.verifyEqual(arr(2).name, "Bob");

            % iskey on scalar returns scalar logical
            testCase.verifyEqual(iskey(arr(1), "name"), true);
            testCase.verifySize(iskey(arr(1), "name"), [1, 1]);
        end

        %% Numeric and partial index tests
        function testArrayDotReferenceNumericSingle(testCase)
            % Test: arr.field(1) - single numeric index
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            result = arr.value(1);
            testCase.verifyEqual(result, 10);
        end

        function testArrayDotReferenceNumericRange(testCase)
            % Test: arr.field(1:2) - numeric range
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            result = arr.value(1:2);
            testCase.verifyEqual(result, [10, 20]);
        end

        function testArrayDotReferenceNumericArray(testCase)
            % Test: arr.field([1 3]) - numeric array index
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).name = "Alice";
            arr(2).name = "Bob";
            arr(3).name = "Charlie";

            result = arr.name([1 3]);
            testCase.verifyEqual(result, ["Alice", "Charlie"]);
        end

        function testArrayDotReferencePartialLogical(testCase)
            % Test: arr.field(partialMask) - logical mask of different size
            arr = [yamldata(), yamldata(), yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;
            arr(4).value = 40;
            arr(5).value = 50;

            % Get first 3 elements using partial logical mask
            mask = [true, false, true];  % Different size than array
            result = arr.value(mask);
            testCase.verifyEqual(result, [10, 30]);
        end

        function testArrayDotAssignNumericSingle(testCase)
            % Test: arr.field(1) = value - single numeric index assignment
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            arr.value(2) = 99;
            testCase.verifyEqual(arr(2).value, 99);
            testCase.verifyEqual(arr(1).value, 10);  % Unchanged
            testCase.verifyEqual(arr(3).value, 30);  % Unchanged
        end

        function testArrayDotAssignNumericRange(testCase)
            % Test: arr.field(1:2) = [values] - range assignment
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            arr.value(1:2) = [100, 200];
            testCase.verifyEqual(arr(1).value, 100);
            testCase.verifyEqual(arr(2).value, 200);
            testCase.verifyEqual(arr(3).value, 30);  % Unchanged
        end

        function testArrayDotAssignNumericBroadcast(testCase)
            % Test: arr.field([1 3]) = scalar - broadcast scalar
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).active = false;
            arr(2).active = false;
            arr(3).active = false;

            arr.active([1 3]) = true;  % Broadcast to indices 1 and 3
            testCase.verifyEqual(arr(1).active, true);
            testCase.verifyEqual(arr(2).active, false);  % Unchanged
            testCase.verifyEqual(arr(3).active, true);
        end

        function testArrayDotAssignAllElements(testCase)
            % Test: arr.field = arr.field (assign to ALL elements)
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).value = 10;
            arr(2).value = 20;
            arr(3).value = 30;

            % Read all values, modify, assign back
            arr.value = arr.value + 100;
            testCase.verifyEqual(arr(1).value, 110);
            testCase.verifyEqual(arr(2).value, 120);
            testCase.verifyEqual(arr(3).value, 130);
        end

        function testArrayDotAssignAllElementsBroadcast(testCase)
            % Test: arr.field = scalar (broadcast to ALL elements)
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).status = "old";
            arr(2).status = "old";
            arr(3).status = "old";

            arr.status = "new";  % Broadcast scalar to all
            testCase.verifyEqual(arr(1).status, "new");
            testCase.verifyEqual(arr(2).status, "new");
            testCase.verifyEqual(arr(3).status, "new");
        end

        function testArrayDotAssignChainedWithIndex(testCase)
            % Test: arr.field(idx).subfield = value
            % This was a bug - IndexingOperation concatenation error
            arr = [yamldata(), yamldata(), yamldata()];
            arr(1).nested = yamldata();
            arr(1).nested.value = 10;
            arr(2).nested = yamldata();
            arr(2).nested.value = 20;
            arr(3).nested = yamldata();
            arr(3).nested.value = 30;

            % Assign to subfield of indexed element
            arr.nested(2).value = 999;
            testCase.verifyEqual(arr(1).nested.value, 10);  % Unchanged
            testCase.verifyEqual(arr(2).nested.value, 999); % Modified
            testCase.verifyEqual(arr(3).nested.value, 30);  % Unchanged

            % Assign deeper chain
            arr.nested(1).deep = yamldata();
            arr.nested(1).deep.x = 42;
            testCase.verifyEqual(arr(1).nested.deep.x, 42);
        end

        %% No reserved key names
        function testDataAsKey(testCase)
            % "Data" should be usable as a configuration key
            config = yamldata();
            config.Data = "my value";
            testCase.verifyEqual(config.Data, "my value");
            testCase.verifyTrue(iskey(config, "Data"));
            testCase.verifyEqual(keys(config), "Data");
        end

        function testSourceFormatAsKey(testCase)
            % "SourceFormat" should be usable as a configuration key
            config = tomldata();
            config.SourceFormat = "custom";
            testCase.verifyEqual(config.SourceFormat, "custom");
            testCase.verifyTrue(iskey(config, "SourceFormat"));
        end

        function testDataAsNestedKey(testCase)
            % "Data" as a nested section key
            config = yamldata();
            config.Data.host = "localhost";
            config.Data.port = 5432;
            testCase.verifyEqual(config.Data.host, "localhost");
            testCase.verifyEqual(config.Data.port, 5432);
        end

        function testNoReservedNamesRoundTrip(testCase)
            % Keys named after internal properties survive write/read
            tempDir = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;

            config = yamldata();
            config.Data = "payload";
            config.SourceFormat = "original";
            config.keys = "skeleton";

            tempFile = fullfile(tempDir, "test.yaml");
            writeyaml(config, tempFile);
            loaded = readyaml(tempFile);

            testCase.verifyEqual(loaded.Data, "payload");
            testCase.verifyEqual(loaded.SourceFormat, "original");
            testCase.verifyEqual(loaded.keys, "skeleton");
        end
    end
end

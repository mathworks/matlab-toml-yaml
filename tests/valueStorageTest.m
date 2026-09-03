classdef valueStorageTest < matlab.unittest.TestCase
    % Tests for the value validation and storage layer: which types are
    % accepted, converted, or rejected on assignment; how vectors are
    % oriented; and how per-element values are concatenated when reading a
    % key across an object array.

    properties(TestParameter)
        constructor = struct( ...
            yaml = struct(make = @yamldata), ...
            toml = struct(make = @tomldata))

        % Types that are stored as they are given. The types that are
        % accepted but converted on the way in are tested individually
        % below, because each one has its own target type to check.
        supportedValue = struct( ...
            double = 42, ...
            string = "text", ...
            logical = true, ...
            int32 = int32(7), ...
            uint8 = uint8(3), ...
            single = single(1.5), ...
            datetime = datetime(2026, 1, 1), ...
            missingValue = missing, ...
            cellOfScalars = {{1, 2}})

        % Types that assignment rejects. calendarDuration is the one that
        % matches none of the specific cases in validateValue and so reaches
        % the mustBeA check at the end, which lists the supported types.
        unsupportedValue = struct( ...
            complexDouble = 1 + 2i, ...
            functionHandle = @sin, ...
            table = table(1), ...
            timetable = timetable(seconds(1), 1), ...
            categorical = categorical({'a'}), ...
            calendarDuration = calyears(1), ...
            containersMap = containers.Map("a", 1))
    end

    methods(Access = private)
        function pair = makePair(~, firstValue, secondValue)
            % Build a 1x2 object array whose elements both define key "a".
            first = yamldata();
            first.a = firstValue;
            second = yamldata();
            second.a = secondValue;
            pair = [first, second];
        end
    end

    methods(Test)
        % --- Accepted input types -----------------------------------------

        function testSupportedTypeIsStoredUnchanged(testCase, supportedValue)
            config = yamldata();

            config.x = supportedValue;

            testCase.verifyEqual(config.x, supportedValue, ...
                "A supported value should read back as it was assigned");
        end

        % --- Converted input types ----------------------------------------

        function testDurationConvertsToSeconds(testCase)
            config = yamldata();

            config.elapsed = minutes(1.5);

            testCase.verifyEqual(config.elapsed, 90, ...
                "A duration should be stored as a number of seconds");
        end

        function testDurationArrayConvertsElementwise(testCase)
            config = yamldata();

            config.elapsed = [seconds(1), seconds(2)];

            testCase.verifyEqual(config.elapsed, [1; 2], ...
                "Each duration converts, and the vector becomes a column");
        end

        function testCellValuedDictionaryBecomesNestedObject(testCase)
            config = yamldata();

            config.section = dictionary("inner", {42});

            testCase.verifyClass(config.section, "matlab.io.config.YAMLData");
            testCase.verifyEqual(config.section.inner, 42);
        end

        function testCharConvertsToString(testCase)
            config = yamldata();

            config.host = 'example.com';

            testCase.verifyClass(config.host, "string");
        end

        function testValuesInsideCellsAreConverted(testCase)
            % validateValue recurses into cell arrays, so a char inside a
            % cell is converted just like a bare char.
            config = yamldata();

            config.mixed = {'text', 1};

            testCase.verifyClass(config.mixed{1}, "string", ...
                "A char inside a cell should be converted to string");
        end

        % --- Rejected types -----------------------------------------------

        function testUnsupportedTypeIsRejected(testCase, unsupportedValue)
            config = yamldata();

            testCase.verifyError(@() setKey(config, unsupportedValue), ...
                "ConfigurationData:InvalidType", ...
                "A value no configuration format can represent should be " + ...
                "rejected on assignment");
        end

        % --- Vector orientation (issue #77) --------------------------------

        function testRowVectorIsNormalizedToColumn(testCase, constructor)
            config = constructor.make();

            config.ports = [80 443 8080];

            testCase.verifyEqual(config.ports, [80; 443; 8080], ...
                "Row vectors are normalized to columns for concatenation");
        end

        function testMatrixOrientationIsPreserved(testCase)
            % Only true vectors are reoriented; a matrix passes through.
            config = yamldata();

            config.grid = [1 2 3; 4 5 6];

            testCase.verifyEqual(config.grid, [1 2 3; 4 5 6]);
        end

        function testCellArrayOrientationIsPreserved(testCase)
            % Cells have no clear orientation semantics, so they are skipped.
            config = yamldata();

            config.items = {1, 2, 3};

            testCase.verifySize(config.items, [1 3], ...
                "A row cell array should not be transposed");
        end

        % --- Concatenating a key across an object array --------------------

        function testAllMissingValuesStayMissing(testCase)
            pair = testCase.makePair(missing, missing);

            result = pair.a;

            testCase.verifyClass(result, "missing");
            testCase.verifySize(result, [1 2], ...
                "The result should keep the shape of the object array");
        end

        function testMissingCoercesToNaNAlongsideDoubles(testCase)
            pair = testCase.makePair(5, missing);

            testCase.verifyEqual(pair.a, [5 NaN], ...
                "missing should coerce to NaN next to a double");
        end

        function testMissingWithIntegerTypeErrors(testCase)
            % Integer types cannot represent missing in MATLAB.
            pair = testCase.makePair(int8(3), missing);

            testCase.verifyError(@() pair.a, ...
                "ConfigurationData:MissingNotSupported");
        end

        function testMismatchedTypesError(testCase)
            pair = testCase.makePair(1, "text");

            testCase.verifyError(@() pair.a, ...
                "ConfigurationData:TypeMismatch");
        end

        function testMismatchedSizesError(testCase)
            pair = testCase.makePair([1 2 3], [1 2]);

            testCase.verifyError(@() pair.a, ...
                "ConfigurationData:SizeMismatch");
        end

        function testRowArrayOfVectorsConcatenatesAcrossColumns(testCase)
            % Column-oriented values from a 1xN array give an MxN matrix.
            pair = testCase.makePair([1 2 3], [4 5 6]);

            testCase.verifyEqual(pair.a, [1 4; 2 5; 3 6]);
        end

        function testColumnArrayOfVectorsConcatenatesDownRows(testCase)
            first = yamldata();
            first.a = [1 2 3];
            second = yamldata();
            second.a = [4 5 6];
            pair = [first; second];

            testCase.verifyEqual(pair.a, [1; 2; 3; 4; 5; 6], ...
                "A column object array concatenates along the first dimension");
        end

        % --- Assignment across object arrays -------------------------------

        function testScalarAssignmentBroadcastsAcrossArray(testCase)
            pair = testCase.makePair(1, 2);

            pair.b = 7;

            testCase.verifyEqual(pair.b, [7 7], ...
                "A scalar should be assigned to every element");
        end

        function testElementwiseAssignmentDistributesValues(testCase)
            pair = testCase.makePair(1, 2);

            pair.b = [10 20];

            testCase.verifyEqual(pair.b, [10 20], ...
                "A value per element should be distributed elementwise");
        end

        function testAssignmentWithWrongCountErrors(testCase)
            pair = testCase.makePair(1, 2);

            testCase.verifyError(@() setKeyNamed(pair, "b", [1 2 3]), ...
                "ConfigurationData:SizeMismatch", ...
                "Three values cannot be spread over two elements");
        end

        function testIndexedAssignmentSelectsArrayElements(testCase)
            pair = testCase.makePair(1, 2);

            pair(2).a = 99;

            testCase.verifyEqual(pair.a, [1 99], ...
                "Paren indexing should target a single element");
        end

        % --- Chained assignment over existing values -----------------------

        function testChainedAssignmentReplacesNonObjectValue(testCase)
            % Assigning into a subkey of a plain value discards that value
            % and creates a nested object in its place.
            config = yamldata();
            config.section = 5;

            config.section.inner = 1;

            testCase.verifyClass(config.section, "matlab.io.config.YAMLData");
            testCase.verifyEqual(config.section.inner, 1);
        end

        function testIndexingIntoMissingKeyErrors(testCase)
            config = yamldata();

            testCase.verifyError(@() indexAssign(config), ...
                "ConfigurationData:InvalidIndex", ...
                "Paren assignment cannot create a key that does not exist");
        end

        % --- struct() over arrays and cells --------------------------------

        function testStructOfObjectArrayReturnsStructArray(testCase)
            pair = testCase.makePair(1, 2);

            result = struct(pair);

            testCase.verifyClass(result, "struct");
            testCase.verifySize(result, [1 2]);
            testCase.verifyEqual([result.a], [1 2]);
        end

        function testStructDescendsIntoCellOfObjects(testCase)
            % Traversal checks each cell element for nested objects, so a
            % cell holding an object is converted rather than passed through.
            inner = yamldata();
            inner.value = 1;
            config = yamldata();
            config.items = {inner, inner};

            result = struct(config);

            testCase.verifyClass(result.items, "struct", ...
                "Objects inside a cell should be converted to structs");
            testCase.verifyEqual(result.items(1).value, 1);
        end
    end
end

function setKey(config, value)
    config.x = value;
end

function setKeyNamed(config, key, value)
    config.(key) = value;
end

function indexAssign(config)
    config.absent(1) = 5;
end

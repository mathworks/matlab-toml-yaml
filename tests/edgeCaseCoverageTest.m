classdef edgeCaseCoverageTest < matlab.unittest.TestCase
    % Tests exercising edge-case paths through public APIs.
    % Targets uncovered branches in: formatYAMLScalar (via writeyaml),
    % compact (via writeyaml/writetoml), expand/parseTOMLDatetime (via
    % readtoml), parseYAMLScalar (via readyaml), tryConcatenate (via array
    % dot-access), visitArray (via struct), display paths.

    properties (TestParameter)
        SpecialFloat = struct(NaN_val=NaN, Inf_val=Inf, NegInf_val=-Inf)
    end

    methods (Test)

        %% writeyaml — formatYAMLScalar edge cases

        function testWriteInteger(testCase)
            obj = yamldata(struct("count", int32(42)));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "42");
        end

        function testWriteSpecialFloats(testCase, SpecialFloat)
            obj = yamldata(struct("val", SpecialFloat));
            text = testCase.writeYAMLToString(obj);
            testCase.verifyTrue( ...
                contains(text, ".nan") || contains(text, ".inf") || contains(text, "-.inf"));
        end

        function testWriteWholeNumberFloat(testCase)
            obj = yamldata(struct("val", 42.0));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "42");
        end

        function testWriteSingleScalar(testCase)
            obj = yamldata(struct("rate", single(0.25)));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "0.25");
        end

        function testWriteSingleArray(testCase)
            obj = yamldata(struct("vals", single([1.5 2.5])));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "1.5");
            testCase.verifySubstring(text, "2.5");
        end

        function testWriteSingleScalarToml(testCase)
            obj = tomldata(struct("rate", single(0.25)));
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "0.25");
        end

        function testWriteDatetimeFractionalSeconds(testCase)
            obj = tomldata();
            obj.created = datetime(2026, 10, 16, 12, 30, 45.125, TimeZone="UTC");
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "45.125");
        end

        function testWriteDatetimeNoFractionalSeconds(testCase)
            obj = tomldata();
            obj.ts = datetime(2026, 10, 16, 12, 30, 45, TimeZone="UTC");
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "12:30:45Z");
        end

        function testWriteBooleanValueString(testCase)
            obj = yamldata(struct("label", "true"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"true"');
        end

        function testWriteDateLikeString(testCase)
            obj = yamldata(struct("stamp", "2024-01-15"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"2024-01-15"');
        end

        function testWriteNumericLikeString(testCase)
            obj = yamldata(struct("ver", "3.14"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"3.14"');
        end

        function testWriteSpecialPrefixString(testCase)
            obj = yamldata(struct("tag", "!bang"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"!bang"');
        end

        function testWriteEmptyString(testCase)
            obj = yamldata();
            obj.blank = "";
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '""');
        end

        function testWriteColonSpaceString(testCase)
            obj = yamldata(struct("msg", "key: value"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"key: value"');
        end

        function testWriteHexLikeString(testCase)
            obj = yamldata(struct("color", "0xFF"));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, '"0xFF"');
        end

        function testWriteMissingValue(testCase)
            obj = yamldata(struct("a", 1));
            obj.b = missing;
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "null");
        end

        function testWriteDatetime(testCase)
            obj = yamldata();
            obj.ts = datetime(2024, 1, 15);
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "2024");
        end

        function testWriteNestedObjectArray(testCase)
            inner = [yamldata(struct("x", 1)), yamldata(struct("x", 2))];
            obj = yamldata();
            obj.items = inner;
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "x:");
        end

        function testWriteCellArray(testCase)
            obj = yamldata(struct("items", {{1, "two", true}}));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "two");
        end

        function testWriteEmptyConfigData(testCase)
            obj = yamldata();
            obj.sub = matlab.io.config.YAMLData.empty;
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "null");
        end

        function testWriteCellWithNestedObject(testCase)
            inner = yamldata(struct("k", 1));
            obj = yamldata(struct("items", {{inner}}));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "k:");
        end

        function testWriteCellWithNestedCell(testCase)
            obj = yamldata(struct("matrix", {{{{1, 2}, {3, 4}}}}));
            text = testCase.writeYAMLToString(obj);
            testCase.verifyTrue(strlength(text) > 0);
        end

        function testWriteCellWithNestedObjectArray(testCase)
            inner = [yamldata(struct("a", 1)), yamldata(struct("a", 2))];
            obj = yamldata(struct("items", {{inner}}));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "a:");
        end

        function testWriteTOMLPreservesRawTypes(testCase)
            obj = tomldata(struct("name", "hello", "count", 42));
            file = [tempname, '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = fileread(file);
            testCase.verifySubstring(text, 'count = 42');
        end

        function testWriteTypedArray(testCase)
            obj = yamldata(struct("nums", [1 2 3]));
            text = testCase.writeYAMLToString(obj);
            testCase.verifySubstring(text, "1");
            testCase.verifySubstring(text, "3");
        end

        %% readtoml — expand/parseTOMLDatetime paths

        function testReadTOMLOffsetDatetime(testCase)
            text = testCase.writeTempFile("ts = 2024-01-15T10:30:00Z", '.toml');
            obj = readtoml(text);
            testCase.verifyClass(obj.ts, 'datetime');
        end

        function testReadTOMLLocalDatetime(testCase)
            text = testCase.writeTempFile("ts = 2024-01-15T10:30:00", '.toml');
            obj = readtoml(text);
            testCase.verifyClass(obj.ts, 'datetime');
        end

        function testReadTOMLDateOnly(testCase)
            text = testCase.writeTempFile("d = 2024-01-15", '.toml');
            obj = readtoml(text);
            testCase.verifyClass(obj.d, 'datetime');
        end

        function testReadTOMLTimeOnly(testCase)
            text = testCase.writeTempFile("t = 10:30:00", '.toml');
            obj = readtoml(text);
            testCase.verifyClass(obj.t, 'datetime');
        end

        %% parseTOMLDatetime — fractional seconds

        function testParseTOMLOffsetDatetimeFractional(testCase)
            dt = matlab.io.config.internal.read.parseTOMLDatetime("2026-10-16T12:30:45.125Z");
            testCase.verifyClass(dt, 'datetime');
            testCase.verifyEqual(second(dt), 45.125);
        end

        function testParseTOMLLocalDatetimeFractional(testCase)
            dt = matlab.io.config.internal.read.parseTOMLDatetime("2026-10-16T12:30:45.125");
            testCase.verifyClass(dt, 'datetime');
            testCase.verifyEqual(second(dt), 45.125);
        end

        function testParseTOMLTimeOnlyFractional(testCase)
            dt = matlab.io.config.internal.read.parseTOMLDatetime("12:30:45.125");
            testCase.verifyClass(dt, 'datetime');
            testCase.verifyEqual(second(dt), 45.125);
        end

        function testParseTOMLOffsetDatetimeSixDigitFractional(testCase)
            dt = matlab.io.config.internal.read.parseTOMLDatetime("2026-10-16T12:30:45.123456Z");
            testCase.verifyClass(dt, 'datetime');
            testCase.verifyEqual(second(dt), 45.123456, AbsTol=1e-9);
        end

        function testParseTOMLOffsetDatetimeFractionalWithOffset(testCase)
            dt = matlab.io.config.internal.read.parseTOMLDatetime("2026-10-16T12:30:45.125+05:30");
            testCase.verifyClass(dt, 'datetime');
            testCase.verifyFalse(isempty(dt.TimeZone));
        end

        %% readyaml — null in sequences

        function testReadYAMLNullInFlowSequence(testCase)
            file = testCase.writeTempFile('weights: [1, null, 3]', '.yaml');
            obj = readyaml(file);
            testCase.verifyTrue(ismissing(obj.weights{2}));
        end

        function testReadYAMLTildeInBlockSequence(testCase)
            file = testCase.writeTempFile(sprintf('items:\n  - 1\n  - ~\n  - 3'), '.yaml');
            obj = readyaml(file);
            testCase.verifyTrue(ismissing(obj.items{2}));
        end

        %% readyaml — parseYAMLScalar paths

        function testReadYAMLQuotedDateStaysString(testCase)
            file = testCase.writeTempFile('stamp: "2024-01-15"', '.yaml');
            obj = readyaml(file);
            testCase.verifyClass(obj.stamp, 'string');
        end

        function testReadYAMLQuotedNonDateStaysString(testCase)
            file = testCase.writeTempFile('label: "hello world"', '.yaml');
            obj = readyaml(file);
            testCase.verifyClass(obj.label, 'string');
        end

        function testReadYAMLUnquotedDate(testCase)
            file = testCase.writeTempFile('stamp: 2024-01-15', '.yaml');
            obj = readyaml(file);
            testCase.verifyTrue(isstring(obj.stamp) || isa(obj.stamp, 'datetime'));
        end

        function testReadYAMLQuotedDateAsDatetime(testCase)
            file = testCase.writeTempFile('stamp: "2024-01-15"', '.yaml');
            obj = readyaml(file, 'DatetimeType', 'datetime');
            testCase.verifyClass(obj.stamp, 'datetime');
        end

        function testReadYAMLUnquotedDateAsDatetime(testCase)
            file = testCase.writeTempFile('stamp: 2024-01-15', '.yaml');
            obj = readyaml(file, 'DatetimeType', 'datetime');
            testCase.verifyClass(obj.stamp, 'datetime');
        end

        function testReadYAMLUnquotedDatetimeAsDatetime(testCase)
            yaml = sprintf('ts: 2024-01-15T10:30:00');
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file, 'DatetimeType', 'datetime');
            testCase.verifyClass(obj.ts, 'datetime');
        end

        function testReadYAMLNullTilde(testCase)
            file = testCase.writeTempFile('val: ~', '.yaml');
            obj = readyaml(file);
            testCase.verifyTrue(ismissing(obj.val));
        end

        function testReadYAMLStringSequence(testCase)
            yaml = sprintf('items:\n  - hello\n  - world');
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file);
            testCase.verifyTrue(isstring(obj.items));
            testCase.verifyLength(obj.items, 2);
        end

        function testReadYAMLObjectArray(testCase)
            yaml = sprintf('items:\n  - name: a\n  - name: b');
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file);
            testCase.verifyLength(obj.items, 2);
        end

        %% Array dot-access — tryConcatenate non-scalar path

        function testArrayAccessNonScalarSameSize(testCase)
            arr = [yamldata(struct("v", [1 2 3])), yamldata(struct("v", [4 5 6]))];
            result = arr.v;
            testCase.verifyEqual(numel(result), 6);
        end

        %% struct() with array children — visitArray path

        function testStructConversionWithObjectArray(testCase)
            inner = [yamldata(struct("a", 1)), yamldata(struct("a", 2))];
            obj = yamldata();
            obj.items = inner;
            s = struct(obj);
            testCase.verifyTrue(isstruct(s));
            testCase.verifyLength(s.items, 2);
        end

        function testStructConversionHeterogeneousFields(testCase)
            file = testCase.writeTempFile( ...
                sprintf('[[svc]]\nname = "api"\nport = 8080\n[[svc]]\nname = "worker"\nqueue = "jobs"'), ...
                '.toml');
            config = readtoml(file);
            s = struct(config);
            testCase.verifyLength(s.svc, 2);
            testCase.verifyTrue(ismissing(s.svc(1).queue));
            testCase.verifyTrue(ismissing(s.svc(2).port));
        end

        function testStructConversionCollidingFieldNames(testCase)
            file = testCase.writeTempFile( ...
                sprintf('api-key: hyphen-secret\napi_key: underscore-secret'), ...
                '.yaml');
            config = readyaml(file);
            s = struct(config);
            testCase.verifyEqual(numel(fieldnames(s)), 2);
            values = string({s.api_key, s.api_key_1});
            testCase.verifyTrue(ismember("hyphen-secret", values));
            testCase.verifyTrue(ismember("underscore-secret", values));
        end

        function testMixedTypeSequenceAccessible(testCase)
            file = testCase.writeTempFile( ...
                sprintf('items:\n  - name: a\n  - 3\n  - hello'), '.yaml');
            config = readyaml(file);
            testCase.verifyClass(config.items, 'cell');
            testCase.verifyLength(config.items, 3);
            testCase.verifyClass(config.items{1}, 'matlab.io.config.YAMLData');
        end

        function testMixedTypeSequenceStructConversion(testCase)
            file = testCase.writeTempFile( ...
                sprintf('items:\n  - name: a\n  - 3'), '.yaml');
            config = readyaml(file);
            s = struct(config);
            testCase.verifyLength(s.items, 2);
            testCase.verifyEqual(s.items(1).name, "a");
            testCase.verifyEqual(s.items(2).Element, 3);
        end

        %% Display paths

        function testDisplayNonScalarArray(testCase)
            arr = [yamldata(struct("a", 1)), yamldata(struct("b", 2))];
            output = evalc('disp(arr)');
            testCase.verifyNotEmpty(output);
        end

        function testCompactColumnDisplay(testCase)
            obj = yamldata(struct("name", "test", "version", "1.0"));
            t = table(obj, 'VariableNames', "Config");
            output = evalc('disp(t)');
            testCase.verifyNotEmpty(output);
        end

        function testDisplayKeyWithSpace(testCase)
            yaml = "hello world: 42";
            file = [tempname, '.yaml'];
            testCase.addTeardown(@() delete(file));
            writelines(yaml, file);
            obj = readyaml(file);
            output = evalc('disp(obj)');
            testCase.verifySubstring(output, "hello world");
        end

        %% isequaln — ConfigurationData comparison paths

        function testIsequalnScalarMatch(testCase)
            a = yamldata(struct("x", 1));
            b = yamldata(struct("x", 1));
            testCase.verifyTrue(isequaln(a, b));
        end

        function testIsequalnScalarMismatch(testCase)
            a = yamldata(struct("x", 1));
            b = yamldata(struct("x", 2));
            testCase.verifyFalse(isequaln(a, b));
        end

        function testIsequalnDifferentClasses(testCase)
            a = yamldata(struct("x", 1));
            b = tomldata(struct("x", 1));
            testCase.verifyFalse(isequaln(a, b));
        end

        function testIsequalnDifferentSizes(testCase)
            a = yamldata(struct("x", {1, 2}));
            b = yamldata(struct("x", {1, 2, 3}));
            testCase.verifyFalse(isequaln(a, b));
        end

        function testIsequalnNonScalarMatch(testCase)
            a = yamldata(struct("x", {1, 2}));
            b = yamldata(struct("x", {1, 2}));
            testCase.verifyTrue(isequaln(a, b));
        end

        function testIsequalnThreeArguments(testCase)
            a = yamldata(struct("x", 1));
            b = yamldata(struct("x", 1));
            c = yamldata(struct("x", 1));
            testCase.verifyTrue(isequaln(a, b, c));
        end

        function testIsequalnDifferentKeys(testCase)
            a = yamldata(struct("x", 1));
            b = yamldata(struct("y", 1));
            testCase.verifyFalse(isequaln(a, b));
        end

        function testIsequalnNonScalarMismatch(testCase)
            a = yamldata(struct("x", {1, 2}));
            b = yamldata(struct("x", {1, 3}));
            testCase.verifyFalse(isequaln(a, b));
        end

        %% traverse — cell array visitor path

        function testStructConversionWithCellValue(testCase)
            obj = yamldata();
            obj.tags = {"alpha", "beta"};
            s = struct(obj);
            testCase.verifyEqual(s.tags, {"alpha", "beta"});
        end

        %% parseYAMLDatetime — strict format rejection

        function testYAMLDatetimeRejectsTzWithoutSeconds(testCase)
            yaml = "stamp: 2024-01-15T12:00+05:00";
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file, DatetimeType="datetime");
            testCase.verifyClass(obj.stamp, "string");
        end

        function testYAMLDatetimeRejectsLocalWithoutSeconds(testCase)
            yaml = "stamp: 2024-01-15T12:00";
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file, DatetimeType="datetime");
            testCase.verifyClass(obj.stamp, "string");
        end

        function testYAMLDatetimeRejectsDateWithTrailingText(testCase)
            yaml = "stamp: '2024-01-15extra'";
            file = testCase.writeTempFile(yaml, '.yaml');
            obj = readyaml(file, DatetimeType="datetime");
            testCase.verifyClass(obj.stamp, "string");
        end

        %% defaultStore — no-argument path

        function testDefaultStoreNoArgument(testCase)
            store = matlab.io.config.internal.defaultStore();
            testCase.verifyEqual(numKeys(store), 0);
        end

        %% valueToNode — datetime formatting

        function testRoundTripDatetimeWithTimezone(testCase)
            obj = tomldata();
            obj.stamp = datetime(2024, 6, 15, 10, 30, 0, TimeZone="UTC");
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "2024-06-15T10:30:00Z");
        end

        function testRoundTripLocalDatetime(testCase)
            obj = tomldata();
            obj.stamp = datetime(2024, 6, 15, 10, 30, 0);
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "2024-06-15T10:30:00");
        end

        function testRoundTripDatetimeWithNonUTCTimezone(testCase)
            obj = tomldata();
            obj.stamp = datetime(2024, 6, 15, 10, 30, 0, TimeZone="America/New_York");
            file = [tempname '.toml'];
            testCase.addTeardown(@() delete(file));
            writetoml(obj, file);
            text = string(fileread(file));
            testCase.verifySubstring(text, "2024-06-15");
            testCase.verifyTrue(~contains(text, "Z"));
        end

        %% getValue — DatetimeType="string" keeps datetime as string

        function testTomlDatetimeAsString(testCase)
            toml = "stamp = 2024-06-15T10:30:00Z";
            file = testCase.writeTempFile(toml, '.toml');
            obj = readtoml(file, DatetimeType="string");
            testCase.verifyClass(obj.stamp, "string");
        end

    end

    methods (Access = private)

        function text = writeYAMLToString(testCase, obj)
            file = [tempname, '.yaml'];
            testCase.addTeardown(@() delete(file));
            writeyaml(obj, file);
            text = string(fileread(file));
        end

        function file = writeTempFile(testCase, content, ext)
            file = [tempname, ext];
            testCase.addTeardown(@() delete(file));
            fid = fopen(file, 'w');
            fwrite(fid, content);
            fclose(fid);
        end

    end
end

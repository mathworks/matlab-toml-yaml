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

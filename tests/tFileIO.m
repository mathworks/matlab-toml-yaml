classdef tFileIO < matlab.unittest.TestCase
    % Tests for file I/O error handling in readtoml, readyaml, writetoml,
    % writeyaml. Validates that MATLAB-side file operations produce clear
    % error messages for common failure modes.

    methods (Test)

        %% readtoml — file errors

        function testReadTOMLFileNotFound(testCase)
            testCase.verifyError( ...
                @() readtoml("/nonexistent/path/missing.toml"), ...
                "MATLAB:validators:mustBeFile");
        end

        function testReadTOMLNoReadPermission(testCase)
            testCase.assumeTrue(isunix, "chmod requires a Unix platform");
            file = [tempname, '.toml'];
            fid = fopen(file, 'w');
            fprintf(fid, 'key = "value"');
            fclose(fid);
            testCase.addTeardown(@() delete(file));

            testCase.assertEqual(system("chmod 000 """ + file + """"), 0, ...
                "Could not change the file permissions");
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            testCase.assumeError(@() fileread(file), ?MException, ...
                "File is still readable (e.g. running as root)");

            testCase.verifyError(@() readtoml(file), ...
                "readtoml:FileOpenError");
        end

        function testReadTOMLEmptyFile(testCase)
            file = [tempname, '.toml'];
            fid = fopen(file, 'w');
            fclose(fid);
            testCase.addTeardown(@() delete(file));

            config = readtoml(file);
            testCase.verifyEmpty(keys(config));
        end

        %% readyaml — file errors

        function testReadYAMLFileNotFound(testCase)
            testCase.verifyError( ...
                @() readyaml("/nonexistent/path/missing.yaml"), ...
                "MATLAB:validators:mustBeFile");
        end

        function testReadYAMLNoReadPermission(testCase)
            testCase.assumeTrue(isunix, "chmod requires a Unix platform");
            file = [tempname, '.yaml'];
            fid = fopen(file, 'w');
            fprintf(fid, 'key: value');
            fclose(fid);
            testCase.addTeardown(@() delete(file));

            testCase.assertEqual(system("chmod 000 """ + file + """"), 0, ...
                "Could not change the file permissions");
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            testCase.assumeError(@() fileread(file), ?MException, ...
                "File is still readable (e.g. running as root)");

            testCase.verifyError(@() readyaml(file), ...
                "readyaml:FileOpenError");
        end

        function testReadYAMLEmptyFile(testCase)
            file = [tempname, '.yaml'];
            fid = fopen(file, 'w');
            fclose(fid);
            testCase.addTeardown(@() delete(file));

            config = readyaml(file);
            testCase.verifyEmpty(keys(config));
        end

        %% writetoml — file errors

        function testWriteTOMLNonexistentDirectory(testCase)
            config = tomldata();
            config.a = 1;

            testCase.verifyError( ...
                @() writetoml(config, "/nonexistent-dir/out.toml"), ...
                "writetoml:FileWriteError");
        end

        function testWriteTOMLNoWritePermission(testCase)
            testCase.assumeTrue(isunix, "chmod requires a Unix platform");
            file = [tempname, '.toml'];
            fid = fopen(file, 'w');
            fprintf(fid, 'placeholder');
            fclose(fid);
            testCase.addTeardown(@() delete(file));
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            testCase.assertEqual(system("chmod 444 """ + file + """"), 0, ...
                "Could not change the file permissions");

            config = tomldata();
            config.a = 1;

            testCase.verifyError(@() writetoml(config, file), ...
                "writetoml:FileWriteError");
        end

        %% writeyaml — file errors

        function testWriteYAMLNonexistentDirectory(testCase)
            config = yamldata();
            config.a = 1;

            testCase.verifyError( ...
                @() writeyaml(config, "/nonexistent-dir/out.yaml"), ...
                "writeyaml:FileWriteError");
        end

        function testWriteYAMLNoWritePermission(testCase)
            testCase.assumeTrue(isunix, "chmod requires a Unix platform");
            file = [tempname, '.yaml'];
            fid = fopen(file, 'w');
            fprintf(fid, 'placeholder');
            fclose(fid);
            testCase.addTeardown(@() delete(file));
            testCase.addTeardown(@() system("chmod 644 """ + file + """"));

            testCase.assertEqual(system("chmod 444 """ + file + """"), 0, ...
                "Could not change the file permissions");

            config = yamldata();
            config.a = 1;

            testCase.verifyError(@() writeyaml(config, file), ...
                "writeyaml:FileWriteError");
        end

        %% Round-trip — I/O path sanity

        function testTOMLRoundTrip(testCase)
            file = [tempname, '.toml'];
            testCase.addTeardown(@() delete(file));

            original = tomldata();
            original.name = "test";
            original.count = 42;
            writetoml(original, file);

            restored = readtoml(file);
            testCase.verifyEqual(restored.name, "test");
            testCase.verifyEqual(restored.count, 42);
        end

        function testYAMLRoundTrip(testCase)
            file = [tempname, '.yaml'];
            testCase.addTeardown(@() delete(file));

            original = yamldata();
            original.name = "test";
            original.count = 42;
            writeyaml(original, file);

            restored = readyaml(file);
            testCase.verifyEqual(restored.name, "test");
            testCase.verifyEqual(restored.count, 42);
        end

        function testUTF8RoundTrip(testCase)
            file = [tempname, '.yaml'];
            testCase.addTeardown(@() delete(file));

            original = yamldata();
            original.greeting = "こんにちは";
            original.emoji = "café ☕";
            writeyaml(original, file);

            restored = readyaml(file);
            testCase.verifyEqual(restored.greeting, "こんにちは");
            testCase.verifyEqual(restored.emoji, "café ☕");
        end

    end
end

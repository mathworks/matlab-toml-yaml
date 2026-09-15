function plan = buildfile
    %BUILDFILE Build tasks for the MATLAB Toolbox for TOML and YAML.
    %   Run with `buildtool` from the repo root. See `buildtool -tasks` for the
    %   available tasks.

    addpath("buildUtilities");
    addpath("toolbox");

    plan = buildplan(localfunctions);

    plan.DefaultTasks = ["mex", "lint", "test"];

    plan("test").Dependencies = ["lint" "mex"];
    plan("fixLint").Dependencies = "indent";
    plan("all").Dependencies = ["indent", "fixLint", "mex", "test"];

    mexOutputFolder = fullfile("toolbox", "derived");
    includeFolder   = fullfile("cpp", "include");

    mexOptions = ["-I" + includeFolder, staticLibcxxFlags()];

    mexSrcFolder = fullfile("cpp", "mexfunctions");
    allPaths = plan.files(fullfile(mexSrcFolder, "*.cpp")).paths;
    isMex = allPaths.endsWith("Mex.cpp");
    supportSrc = allPaths(~isMex);
    for cppFile = allPaths(isMex)
        [~, fileName] = fileparts(cppFile);
        plan("mex:" + fileName) = matlab.buildtool.tasks.MexTask( ...
            [cppFile, supportSrc], ...
            mexOutputFolder, ...
            Options=mexOptions);
    end
    plan("mex").Dependencies = "fetch";
    plan("mex").Description = "Build MEX functions";
    plan("clean") = matlab.buildtool.tasks.CleanTask;
end

function fetchTask(~)
    % Download pinned third-party single-header C++ libraries into cpp/include/.
    includeFolder = fullfile("cpp", "include");

    libs = struct( ...
        "toml11", struct( ...
        Version="v4.4.0", ...
        URL="https://raw.githubusercontent.com/ToruNiina/toml11/v4.4.0/single_include/toml.hpp", ...
        File=fullfile(includeFolder, "toml.hpp")), ...
        "rapidyaml", struct( ...
        Version="v0.16.0", ...
        URL="https://github.com/biojppm/rapidyaml/releases/download/v0.16.0/rapidyaml.v0.16.0.singlehdr.hpp", ...
        File=fullfile(includeFolder, "ryml.hpp")));

    names = string(fieldnames(libs));
    for i = 1:numel(names)
        lib = libs.(names(i));
        if isfile(lib.File)
            fprintf("  %s %s — already present\n", names(i), lib.Version);
            continue
        end
        fprintf("  Downloading %s %s ...\n", names(i), lib.Version);
        websave(lib.File, lib.URL);
    end
end

function testTask(~)
    % Run the shipped test suite in tests/ against the toolbox on the path.
    %   Measures coverage of the toolbox library code and writes two reports
    %   into coverage/: cobertura.xml for CI consumption and html/index.html to
    %   browse locally.
    %   On releases before R2023a only the Cobertura report is produced, because
    %   the CoverageReport (HTML) format was introduced in R2023a and R2022b is
    %   the minimum supported release.
    import matlab.unittest.TestSuite
    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.CodeCoveragePlugin
    import matlab.unittest.plugins.codecoverage.CoberturaFormat

    coverageFolder = "coverage";
    if ~isfolder(coverageFolder)
        mkdir(coverageFolder);
    end

    formats = CoberturaFormat(fullfile(coverageFolder, "cobertura.xml"));
    if ~isMATLABReleaseOlderThan("R2023a")
        coverageResult = matlab.unittest.plugins.codecoverage.CoverageResult;
        formats = [formats, ...
            matlab.unittest.plugins.codecoverage.CoverageReport( ...
            fullfile(coverageFolder, "html")), ...
            coverageResult];
    end

    suite = TestSuite.fromFolder("tests");
    runner = TestRunner.withTextOutput;
    runner.addPlugin(CodeCoveragePlugin.forFile(libraryFiles(), Producing=formats));
    results = runner.run(suite);
    assertSuccess(results);

    if ~isMATLABReleaseOlderThan("R2023a")
        result = coverageResult.Result; %#ok<NASGU>
        save(fullfile(coverageFolder, "result.mat"), "result");
    end
end

function mltbxTask(~)
    % Package toolbox/ into a .mltbx artifact.
    % Temporarily copy license.txt and README.md into toolbox/ so it is bundled in the .mltbx.
    sourcePath = ["license.txt" "README.md"];
    destPathFcn = @(filename) fullfile("toolbox", filename);
    arrayfun(@(filename) copyfile(filename, destPathFcn(filename)), sourcePath);
    cleanup = onCleanup(@() delete(destPathFcn(sourcePath)));

    opts = matlab.addons.toolbox.ToolboxOptions("toolbox", ...
        "1dd978f7-c76b-4b6c-a0f6-b1bf82118978", ...
        ToolboxName="MATLAB Toolbox for TOML and YAML");
    if ~isMATLABReleaseOlderThan("R2026b")
        opts.PackageName = "tomlyaml";
    end
    opts.ToolboxVersion = "0.1.0";
    opts.MinimumMatlabRelease = "R2022b";
    opts.OutputFile = fullfile("release", "MATLAB_Toolbox_for_TOML_and_YAML.mltbx");
    opts.Summary = "Read and write TOML and YAML configuration files with dot notation access.";
    opts.Description = fileread("README.md");
    opts.ToolboxImageFile = fullfile("images", "matlab-toml-yaml.png");
    opts.ToolboxGettingStartedGuide = fullfile("toolbox", "doc", "GettingStarted.mlx");
    opts.AuthorCompany = "MathWorks";
    opts.AuthorName = "Aylin Dmello, Jeremy Hughes, Michelle Hirsch";
    matlab.addons.toolbox.packageToolbox(opts);
end

%% ---- Formatting and static analysis ----------------------------------------

function indentTask(~)
    % Auto-indent all project .m files using MATLAB smart indentation.
    %   Uses the editor's smartIndentContents with 4-space indent to normalize
    %   whitespace across the codebase. Reports which files were modified.
    s = settings;
    s.matlab.editor.tab.IndentSize.TemporaryValue = 4;
    s.matlab.editor.tab.InsertSpaces.TemporaryValue = true;
    s.matlab.editor.language.matlab.FunctionIndentingFormat.TemporaryValue = ...
        "AllFunctionIndent";

    files = projectMatlabFiles();
    modified = files(arrayfun(@smartIndentFile, files));
    if isempty(modified)
        fprintf("All %d files already correctly indented.\n", numel(files));
    else
        fprintf("Re-indented %d of %d files:\n", numel(modified), numel(files));
        for i = 1:numel(modified)
            fprintf("  %s\n", modified(i));
        end
    end
end

function lintTask(~)
    % Report Code Analyzer issues in the toolbox library source.
    %   Displays all issues found by codeIssues on toolbox/, excluding example
    %   and doc scripts. Errors if any warnings are present.
    issues = codeIssues(libraryFiles());
    t = issues.Issues;

    if isempty(t)
        fprintf("No code issues found.\n");
        return
    end

    columns = ["Location", "Severity", "CheckID", "Description"];
    if ismember("Fixability", t.Properties.VariableNames)
        columns = ["Location", "Severity", "Fixability", "CheckID", "Description"];
    end
    disp(t(:, columns));
    nWarnings = sum(t.Severity == "warning");
    nInfo = height(t) - nWarnings;
    fprintf("\n%d warning(s), %d info\n", nWarnings, nInfo);

    if nWarnings > 0
        error("lint:warnings", "Code Analyzer found %d warning(s).", nWarnings);
    end
end

function fixLintTask(~)
    % Auto-fix Code Analyzer issues in the toolbox library source.
    %   Applies automatic fixes via codeIssues/fix (R2023a+) on toolbox/,
    %   excluding example and doc scripts. Remaining manual-fix issues are
    %   reported but not modified.
    if isMATLABReleaseOlderThan("R2023a")
        error("fixLint:release", "The fixLint task requires R2023a or later.");
    end

    issues = codeIssues(libraryFiles());
    t = issues.Issues;

    if isempty(t)
        fprintf("No code issues found.\n");
        return
    end

    autoFixable = t(t.Fixability == "auto", :);
    if ~isempty(autoFixable)
        [~, results] = fix(issues, autoFixable);
        fprintf("Auto-fixed %d of %d issue(s).\n", sum(results.Success), height(results));
    end

    manual = t(t.Fixability == "manual", :);
    if ~isempty(manual)
        fprintf("\nRemaining issues (require manual fix):\n");
        disp(manual(:, ["Location", "Severity", "CheckID", "Description"]));
    end
end

function allTask(~)
    % Auto-format, fix lint issues, and run the test suite.
    %   Orchestrated via dependencies: indent → fixLint → test (which includes lint).
end

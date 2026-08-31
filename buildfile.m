function plan = buildfile
%BUILDFILE Build tasks for the MATLAB Toolbox for TOML and YAML.
%   Run with `buildtool` from the repo root. See `buildtool -tasks` for the
%   available tasks.

plan = buildplan(localfunctions);

% Run the shipped (TOML/YAML) test suite by default.
plan.DefaultTasks = "test";
end

function testTask(~)
% Run the shipped test suite in tests/ against the toolbox on the path.
%   Measures coverage of the toolbox library code and writes two reports
%   into coverage/: cobertura.xml for CI consumption and html/index.html to
%   browse locally.
import matlab.unittest.TestSuite
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin
import matlab.unittest.plugins.codecoverage.CoberturaFormat
import matlab.unittest.plugins.codecoverage.CoverageReport

coverageFolder = "coverage";
if ~isfolder(coverageFolder)
    mkdir(coverageFolder);
end

suite = TestSuite.fromFolder("tests");
runner = TestRunner.withTextOutput;
runner.addPlugin(CodeCoveragePlugin.forFile(libraryFiles(), ...
    Producing=[CoberturaFormat(fullfile(coverageFolder, "cobertura.xml")), ...
               CoverageReport(fullfile(coverageFolder, "html"))]));
results = runner.run(suite);
assertSuccess(results);
end

function files = libraryFiles()
% List the toolbox library files to measure coverage against.
%   Everything under toolbox/ except the examples and documentation. The
%   example scripts are run by tests/exampleScriptsTest.m, but from a
%   temporary copy, so the originals can never register as covered no matter
%   how thorough the suite gets. The library lines those examples exercise
%   are still counted here, via the files below. Measuring the examples
%   themselves would only add several hundred permanently unreachable lines
%   to the denominator.
%
%   forFile is used rather than forFolder because forFolder's
%   IncludingSubfolders option is all-or-nothing and cannot skip a subfolder.
excludedFolders = fullfile(pwd, "toolbox", ["examples", "doc"]) + filesep;

found = dir(fullfile("toolbox", "**", "*.m"));
files = string(fullfile({found.folder}, {found.name}))';
files = files(~startsWith(files, excludedFolders));
end

function mltbxTask(~)
% Package toolbox/ into a .mltbx artifact.
opts = matlab.addons.toolbox.ToolboxOptions("toolbox", ...
    "1dd978f7-c76b-4b6c-a0f6-b1bf82118978", ...
    ToolboxName="MATLAB Toolbox for TOML and YAML");
opts.PackageName = "tomlyaml";
opts.ToolboxVersion = "0.1.0";
opts.MinimumMatlabRelease = "R2022b";
opts.OutputFile = fullfile("release", "MATLAB_Toolbox_for_TOML_and_YAML.mltbx");
opts.Summary = "Read and write TOML and YAML configuration files with dot notation access.";
opts.Description = fileread("README.md");
if isfile(fullfile("images", "matlab-toml-yaml.png"))
    opts.ToolboxImageFile = fullfile("images", "matlab-toml-yaml.png");
end
opts.ToolboxGettingStartedGuide = fullfile("toolbox", "doc", "GettingStarted.mlx");
matlab.addons.toolbox.packageToolbox(opts);
end

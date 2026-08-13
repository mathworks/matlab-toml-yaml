function plan = buildfile
%BUILDFILE Build tasks for the TOML and YAML Toolbox for MATLAB.
%   Run with `buildtool` from the repo root. See `buildtool -tasks` for the
%   available tasks.
%
%   Because JSON/INI support lives in experimental/ (never shipped), the
%   toolbox/ folder is exactly the installable ship set: the packaging task
%   below needs no per-file exclusion logic.

plan = buildplan(localfunctions);

% Run the shipped (TOML/YAML) test suite by default.
plan.DefaultTasks = "test";
end

function testTask(~)
% Run the shipped test suite in tests/ against the toolbox on the path.
suite = matlab.unittest.TestSuite.fromFolder("tests");
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);
assertSuccess(results);
end

function mltbxTask(~)
% Package toolbox/ into a .mltbx artifact in release/.
opts = matlab.addons.toolbox.ToolboxOptions("toolbox", ...
    "e3b8a7d2-5c14-4f6e-9a01-3d7f82c6b9e4");
opts.ToolboxName = "TOML and YAML Toolbox for MATLAB";
opts.ToolboxVersion = "0.1.0";
opts.MinimumMatlabRelease = "R2022b";
opts.OutputFile = fullfile("release", "TOML_and_YAML_Toolbox_for_MATLAB.mltbx");
opts.Summary = "Read and write YAML and TOML configuration files with dot notation access.";
opts.Description = "Pure MATLAB toolbox for reading and writing YAML and TOML " + ...
    "configuration files. Includes custom data types with dot notation access, " + ...
    "full round-trip support, and configurable formatting. No external dependencies.";
if isfile(fullfile("images", "matlab-toml-yaml.png"))
    opts.ToolboxImageFile = fullfile("images", "matlab-toml-yaml.png");
end
opts.ToolboxGettingStartedGuide = fullfile("toolbox", "GettingStarted.m");
matlab.addons.toolbox.packageToolbox(opts);
end

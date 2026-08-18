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
suite = matlab.unittest.TestSuite.fromFolder("tests");
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);
assertSuccess(results);
end

function mltbxTask(~)
% Package toolbox/ into a .mltbx artifact.
opts = matlab.addons.toolbox.ToolboxOptions("toolbox", ...
    "1dd978f7-c76b-4b6c-a0f6-b1bf82118978", ...
    ToolboxName="MATLAB Toolbox for TOML and YAML");
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

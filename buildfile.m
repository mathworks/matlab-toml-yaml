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
% Package toolbox/ into a .mltbx artifact.
%
% SKELETON: this proves toolbox/ is the ship set but is not yet wired up for
% release. Before enabling, decide and set: toolbox identity GUID, version,
% supported release range, and output path. See:
% https://www.mathworks.com/help/matlab/ref/matlab.addons.toolbox.toolboxoptions.html

error("buildfile:mltbxNotConfigured", ...
    ["The mltbx packaging task is a skeleton. Configure ToolboxOptions " ...
     "(identifier GUID, version, release compatibility) before use."]);

%#ok<UNRCH> Reference implementation, intentionally after the guard:
% opts = matlab.addons.toolbox.ToolboxOptions("toolbox", "<toolbox-guid>");
% opts.ToolboxName = "TOML and YAML Toolbox for MATLAB";
% opts.ToolboxVersion = "1.0.0";
% opts.OutputFile = fullfile("release", "TomlYamlToolbox.mltbx");
% matlab.addons.toolbox.packageToolbox(opts);
end

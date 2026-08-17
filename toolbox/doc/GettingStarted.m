%[text] #  Getting Started with MATLAB Toolbox for TOML and YAML
%[text] Learn how to read and write YAML and TOML configuration files in MATLAB with intuitive dot notation access.
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Setup
%[text] Locate the sample files shipped with the toolbox.
examplesFolder = fileparts(which("readyamlExample"));
%%
%[text] ## Reading TOML and YAML Files
%[text] Read a YAML file:
config = readyaml(fullfile(examplesFolder, "basic_config.yaml"))
%%
%[text] Read a TOML file:
settings = readtoml(fullfile(examplesFolder, "basic_settings.toml"))
%%
%[text] ## Accessing Data with Dot Notation
%[text] Use dot notation to access values — works the same for both formats:
config.port
settings.port
%%
%[text] Keys with hyphens use parentheses notation:
config.("app-name")
settings.("max-connections")
%%
%[text] As a convenience, hyphenated keys also work with underscores:
config.app_name
settings.max_connections
%%
%[text] ## Modifying Configuration Data
%[text] Change values and add new keys:
config.port = 9000;
config.debug = false;
settings.port = 3000;
settings.("max-connections") = 200;
%%
%[text] Build nested structure from scratch:
config.database.host = "localhost";
config.database.port = 5432;
config
%%
%[text] ## Writing TOML and YAML Files
%[text] Write back to YAML:
writeyaml(config, "my_config.yaml");
type("my_config.yaml")
%%
%[text] Write back to TOML:
writetoml(settings, "my_settings.toml");
type("my_settings.toml")
%%
%[text] ## Next Steps
%[text] For more, see the example scripts:
%[text] - `readyamlExample.m` — YAML reading, arrays, and type conversion
%[text] - `writeyamlExample.m` — YAML formatting options (`ArrayStyle`, `SectionSpacing`)
%[text] - `readtomlExample.m` — TOML reading and data types
%[text] - `writetomlExample.m` — TOML formatting options (`ArrayStyle`, `StringEscapeStyle`)
%[text] - `yamlWorkflowExample.m` — End-to-end read/modify/write workflow
%%
%[text] ## Cleanup
delete("my_config.yaml", "my_settings.toml");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

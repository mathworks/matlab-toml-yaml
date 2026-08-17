%[text] #  Getting Started with MATLAB Toolbox for TOML and YAML
%[text] Learn how to read and write YAML and TOML configuration files in MATLAB with intuitive dot notation access.
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Setup
%[text] Locate the sample files shipped with the toolbox.
examplesFolder = fileparts(which("readyamlExample"));
%%
%[text] ## Reading Files
%[text] Read a YAML file:
server = readyaml(fullfile(examplesFolder, "server_config.yaml"))
%%
%[text] Read a TOML file:
project = readtoml(fullfile(examplesFolder, "simple_project.toml"))
%%
%[text] ## Accessing Data
%[text] Use dot notation to access values — works the same for both formats:
server.database.host
project.project.name
%%
%[text] Keys with hyphens use parentheses notation:
project.("build-system").requires
%%
%[text] As a convenience, hyphenated keys also work with underscores:
project.build_system.requires
%%
%[text] ## Modifying Data
%[text] Change values, add new keys, or build nested structure:
server.database.port = 3306;
server.cache.enabled = true;
project.project.version = "2.0.0";
project.project.("new-field") = "new value";
%%
%[text] Build new data objects from scratch:
config = yamldata();
config.name = "MyApp";
config.database.host = "localhost";
config.database.port = 5432;

settings = tomldata();
settings.owner.name = "Alice";
settings.owner.email = "alice@example.com";
%%
%[text] ## Writing Files
%[text] Write YAML:
writeyaml(config, "my_config.yaml");
type("my_config.yaml")
%%
%[text] Write TOML:
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

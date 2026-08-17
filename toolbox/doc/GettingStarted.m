%[text] #  Getting Started with MATLAB Toolbox for TOML and YAML
%[text] Learn how to read and write YAML and TOML configuration files in MATLAB with intuitive dot notation access.
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Setup
%[text] Locate the sample files shipped with the toolbox.
examplesFolder = fileparts(which("readyamlExample"));
%%
%[text] ## Reading TOML and YAML Files
%[text] Read a YAML file:
config = readyaml(fullfile(examplesFolder, "basic_config.yaml")) %[output:730e7104]
%%
%[text] Read a TOML file:
settings = readtoml(fullfile(examplesFolder, "basic_settings.toml")) %[output:6da613ab]
%%
%[text] ## Accessing Data with Dot Notation
%[text] Use dot notation to access values — works the same for both formats:
config.port %[output:289d2f8e]
settings.port %[output:29cb7ed1]
%%
%[text] Keys with hyphens use parentheses notation:
config.("app-name") %[output:58a64da4]
settings.("max-connections") %[output:4fb28e11]
%%
%[text] As a convenience, hyphenated keys also work with underscores:
config.app_name %[output:84d33879]
settings.max_connections %[output:25b46b6a]
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
config %[output:2b15e0d3]
%%
%[text] ## Writing TOML and YAML Files
%[text] Write back to YAML:
writeyaml(config, "my_config.yaml");
type("my_config.yaml") %[output:265a71c5]
%%
%[text] Write back to TOML:
writetoml(settings, "my_settings.toml");
type("my_settings.toml") %[output:8beb5f62]
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
%[output:730e7104]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"MyApplication\"\n    version: \"1.2.0\"\n    port: 8080\n    debug: true\n    author: \"Jane Doe\"\n"}}
%---
%[output:6da613ab]
%   data: {"dataType":"textualVariable","outputData":{"name":"settings","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    title: \"My Application\"\n    version: \"2.0.0\"\n    port: 9090\n    debug: false\n    max-connections: 100\n"}}
%---
%[output:289d2f8e]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"8080"}}
%---
%[output:29cb7ed1]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"9090"}}
%---
%[output:58a64da4]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"MyApplication\""}}
%---
%[output:4fb28e11]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"100"}}
%---
%[output:84d33879]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"MyApplication\""}}
%---
%[output:25b46b6a]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"100"}}
%---
%[output:2b15e0d3]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"MyApplication\"\n    version: \"1.2.0\"\n    port: 9000\n    debug: false\n    author: \"Jane Doe\"\n    database: [1x1 YAMLData with 2 keys]\n\n    <a href=\"matlab:show(config)\">Show all values<\/a>\n"}}
%---
%[output:265a71c5]
%   data: {"dataType":"text","outputData":{"text":"\napp-name: MyApplication\n\nversion: 1.2.0\n\nport: 9000\n\ndebug: false\n\nauthor: Jane Doe\n\ndatabase:\n  host: localhost\n  port: 5432\n","truncated":false}}
%---
%[output:8beb5f62]
%   data: {"dataType":"text","outputData":{"text":"\ntitle = \"My Application\"\nversion = \"2.0.0\"\nport = 3000\ndebug = false\nmax-connections = 200\n","truncated":false}}
%---

%[text] #  Getting Started with MATLAB Toolbox for TOML and YAML
%[text] Learn how to read and write YAML and TOML configuration files in MATLAB with intuitive dot notation access.
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Reading YAML Files
%%
%[text] ### Reading a Basic YAML File
%[text] Start by reading a simple configuration file with no hierarchy. Locate the sample files shipped with the toolbox:
examplesFolder = fullfile(fileparts(mfilename("fullpath")), "..", "examples");
type(fullfile(examplesFolder, "basic_config.yaml")) %[output:0b5d0dfa]
config = readyaml(fullfile(examplesFolder, "basic_config.yaml")) %[output:3680055a]
%%
%[text] ### Understanding YAMLData
%[text] The data is returned as a `YAMLData` object - a custom type designed to work naturally with YAML files. It works mostly like a struct, but preserves key order and handles special characters in field names.
%[text] Access individual values using dot notation:
port = config.port %[output:368f9e26]
%%
%[text] ### Modifying Values
%[text] Change values just like you would with a struct:
config.port = 9000;
config.debug = false;
config %[output:58278f27]
%%
%[text] ### Handling Keys with Hyphens
%[text] Unlike MATLAB names, YAML names might include a hyphen. You can access these using the same syntax that table uses for referencing variables that aren"t valid MATLAB names:
appName = config.("app-name") %[output:6a69a37d]
%[text] As a convenience, you can also refer to these names using underscore (\_) instead of hyphen (-):
appName = config.app_name %[output:4875e157]
%%
%[text] ### Working with Hierarchical YAML data
%[text] Most configuration files have nested structure. Let's read a more complex example:
type(fullfile(examplesFolder, "server_config.yaml")) %[output:3997f889]
server = readyaml(fullfile(examplesFolder, "server_config.yaml")) %[output:7c245bae]
%%
%[text] Just like struct, read nested values with dot:
creds = server.database.credentials %[output:68fcc874]
%[text] Write with dot:
server.database.credentials.username = "Michelle";
server.database.credentials %[output:794df1dd]
%%
%[text] ### Formatted display
%[text] Especially for deeply nested data, it can be convenient to see the all of the data at once. Either click on the "Show all values" hyperlink, or call `show`.
show(server) %[output:8edd4b91]
%%
%[text] When data gets complex, `describe` gives a compact structural overview — especially useful when data contains arrays, since it shows sizes and types rather than printing all elements:
arrays = readyaml(fullfile(examplesFolder, "arrays_config.yaml")) %[output:7c182cfe]
describe(arrays) %[output:2072aa20]
%%
%[text] ### Introspection
%[text] Get all top-level keys:
topKeys = keys(server) %[output:91b4b57b]
%[text] Check if a key is defined:
tf = iskey(server.application,"name") %[output:9c111a52]
%%
%[text] ### Add and remove keys
%[text] Add new keys or remove existing ones:
server.cache.enabled = true;
server.cache.size = 1000;
server = remove(server, "logging");  % Like struct, server.logging = [] sets logging to empty
keys(server) %[output:7864df86]
%%
%[text] ### Building Hierarchy Programmatically
%[text] There are two ways to create nested configuration from scratch.
%[text] **Method 1: Assign to dot paths directly.** Intermediate objects are created automatically:
fresh = yamldata();
fresh.database.host = "localhost";
fresh.database.port = 5432;
fresh.database.credentials.username = "admin" %[output:787fb2d0]
%%
%[text] **Method 2: Build sub-objects separately, then compose.** Useful when constructing sections independently or conditionally:
fresh2 = yamldata();

% Create a sub-object
db = yamldata();
db.host = "localhost";
db.port = 5432;
db.credentials.username = "admin";

% Add it to main object
fresh2.database = db %[output:4f1f05ce]
%%
%[text] ### Data Type Conversion
%[text] YAML data types automatically map to corresponding MATLAB types:
%[text:table]
%[text] | **YAML Type** | **MATLAB Type** |
%[text] | --- | --- |
%[text] | String | string |
%[text] | Integer | double |
%[text] | Float | double |
%[text] | Boolean (true/false) | logical |
%[text] | Null | missing |
%[text] | Sequence of numbers | double array |
%[text] | Sequence of strings | string array |
%[text] | Sequence of mixed types | cell array |
%[text] | Sequence of mappings | YAMLData array |
%[text:table]
%%
%[text] ## Writing YAML Files
%[text] After modifying configuration, write it back. Let"s read, modify, and save:
config = readyaml(fullfile(examplesFolder, "basic_config.yaml"));
config.port = 9000;
config.("max-connections") = 100;
writeyaml(config, "modified_config.yaml");
disp("Configuration saved!") %[output:0e5878c8]
%%
%[text] View what was written:
type("modified_config.yaml") %[output:0109587c]
%%
%[text] ## Working with TOML Files
%[text] TOML files work similarly. Data is returned as `TOMLData`, which is like `YAMLData` but specialized for TOML.
%[text] Read a simple TOML file:
project = readtoml(fullfile(examplesFolder, "simple_project.toml")) %[output:5a80e9c4]
%%
%[text] Access nested values:
projectName = project.project.name %[output:56e61a72]
%%
%[text] TOML also handles keys with hyphens:
buildSystem = project.("build-system") %[output:0dc03941]
requires = project.("build-system").requires %[output:40eac79d]
%%
%[text] Modify and write back:
project.project.version = "2.0.0";
project.project.("new-field") = "new value";
writetoml(project, "modified_project.toml");
type("modified_project.toml") %[output:6d54641a]
%%
%[text] ## Next Steps
%[text] For more focused examples, see:
%[text] - `readyamlExample.m` - YAML reading and array handling
%[text] - `writeyamlExample.m` - YAML formatting options (`ArrayStyle`, `SectionSpacing`)
%[text] - `readtomlExample.m` - Advanced TOML reading features
%[text] - `writetomlExample.m` - TOML formatting options (`ArrayStyle`, `StringEscapeStyle`)
%%
%[text] ## Cleanup
delete("modified_config.yaml", "modified_project.toml");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:0b5d0dfa]
%   data: {"dataType":"text","outputData":{"text":"\napp-name: MyApplication\nversion: 1.2.0\nport: 8080\ndebug: true\nauthor: Jane Doe\n","truncated":false}}
%---
%[output:3680055a]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"MyApplication\"\n    version: \"1.2.0\"\n    port: 8080\n    debug: true\n    author: \"Jane Doe\"\n"}}
%---
%[output:368f9e26]
%   data: {"dataType":"textualVariable","outputData":{"name":"port","value":"8080"}}
%---
%[output:58278f27]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"MyApplication\"\n    version: \"1.2.0\"\n    port: 9000\n    debug: false\n    author: \"Jane Doe\"\n"}}
%---
%[output:6a69a37d]
%   data: {"dataType":"textualVariable","outputData":{"name":"appName","value":"\"MyApplication\""}}
%---
%[output:4875e157]
%   data: {"dataType":"textualVariable","outputData":{"name":"appName","value":"\"MyApplication\""}}
%---
%[output:3997f889]
%   data: {"dataType":"text","outputData":{"text":"\napplication:\n  name: WebServer\n  version: 2.0.0\n  environment: production\ndatabase:\n  host: localhost\n  port: 5432\n  name: mydb\n  credentials:\n    username: admin\n    password: secret123\nlogging:\n  level: info\n  file: \/var\/log\/app.log\n","truncated":false}}
%---
%[output:7c245bae]
%   data: {"dataType":"textualVariable","outputData":{"name":"server","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    application: [1x1 YAMLData with 3 keys]\n    database: [1x1 YAMLData with 4 keys]\n    logging: [1x1 YAMLData with 2 keys]\n\n    <a href=\"matlab:show(server)\">Show all values<\/a>\n"}}
%---
%[output:68fcc874]
%   data: {"dataType":"textualVariable","outputData":{"name":"creds","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    username: \"admin\"\n    password: \"secret123\"\n"}}
%---
%[output:794df1dd]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    username: \"Michelle\"\n    password: \"secret123\"\n"}}
%---
%[output:8edd4b91]
%   data: {"dataType":"text","outputData":{"text":"application:\n  name: WebServer\n  version: 2.0.0\n  environment: production\n\ndatabase:\n  host: localhost\n  port: 5432\n  name: mydb\n  credentials:\n    username: Michelle\n    password: secret123\n\nlogging:\n  level: info\n  file: \/var\/log\/app.log\n\n","truncated":false}}
%---
%[output:7c182cfe]
%   data: {"dataType":"textualVariable","outputData":{"name":"arrays","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    web: [1x1 YAMLData with 3 keys]\n    services: [3x1 string]\n    mixed: [1x2 YAMLData]\n\n    <a href=\"matlab:show(arrays)\">Show all values<\/a>\n"}}
%---
%[output:2072aa20]
%   data: {"dataType":"text","outputData":{"text":"\n  YAMLData with 3 keys\n\n    web:\n        ports:              3x1 double\n        hosts:              3x1 string\n        settings:           3x1 cell\n    services:           3x1 string\n    mixed:              1x2 array\n        name:               string\n        port:               double\n\n","truncated":false}}
%---
%[output:91b4b57b]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"topKeys","rows":1,"type":"string","value":[["application","database","logging"]]}}
%---
%[output:9c111a52]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"tf","value":"   1\n"}}
%---
%[output:7864df86]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["application","database","cache"]]}}
%---
%[output:787fb2d0]
%   data: {"dataType":"textualVariable","outputData":{"name":"fresh","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    database: [1x1 YAMLData with 3 keys]\n\n    <a href=\"matlab:show(fresh)\">Show all values<\/a>\n"}}
%---
%[output:4f1f05ce]
%   data: {"dataType":"textualVariable","outputData":{"name":"fresh2","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    database: [1x1 YAMLData with 3 keys]\n\n    <a href=\"matlab:show(fresh2)\">Show all values<\/a>\n"}}
%---
%[output:0e5878c8]
%   data: {"dataType":"text","outputData":{"text":"Configuration saved!\n","truncated":false}}
%---
%[output:0109587c]
%   data: {"dataType":"text","outputData":{"text":"\napp-name: MyApplication\n\nversion: 1.2.0\n\nport: 9000\n\ndebug: true\n\nauthor: Jane Doe\n\nmax-connections: 100\n","truncated":false}}
%---
%[output:5a80e9c4]
%   data: {"dataType":"textualVariable","outputData":{"name":"project","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    project: [1x1 TOMLData with 4 keys]\n    build-system: [1x1 TOMLData with 2 keys]\n\n    <a href=\"matlab:show(project)\">Show all values<\/a>\n"}}
%---
%[output:56e61a72]
%   data: {"dataType":"textualVariable","outputData":{"name":"projectName","value":"\"example-package\""}}
%---
%[output:0dc03941]
%   data: {"dataType":"textualVariable","outputData":{"name":"buildSystem","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    requires: [1x2 string]\n    build-backend: \"setuptools.build_meta\"\n"}}
%---
%[output:40eac79d]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 string array","name":"requires","rows":1,"type":"string","value":[["setuptools>=61.0","wheel"]]}}
%---
%[output:6d54641a]
%   data: {"dataType":"text","outputData":{"text":"\n[project]\nname = \"example-package\"\nversion = \"2.0.0\"\ndescription = \"An example project\"\nnew-field = \"new value\"\n\n[project.urls]\nhomepage = \"https:\/\/github.com\/example\/project\"\nrepository = \"https:\/\/github.com\/example\/project.git\"\n\n[build-system]\nrequires = [\"setuptools>=61.0\", \"wheel\"]\nbuild-backend = \"setuptools.build_meta\"\n","truncated":false}}
%---

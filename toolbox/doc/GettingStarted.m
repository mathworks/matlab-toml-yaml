%[text] #  Configuration File I/O - Getting Started
%[text] Learn how to read and write YAML and TOML configuration files in MATLAB with intuitive dot notation access. The example files are provided with the toolbox. `cd` MATLAB to the toolbox root (the location of this file) to access the examples.
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] ## Reading YAML Files
%%
%[text] ### Reading a Basic YAML File
%[text] Start by reading a simple configuration file with no hierarchy.
type("examples/basic_config.yaml") %[output:0b5d0dfa]
config = readyaml("examples/basic_config.yaml") %[output:3680055a]
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
%[text] ### Dynamic Indexing
%[text] Just like a struct, use dynamic field access when the field name is in a variable:
fieldName = "version";
currentVersion = config.(fieldName) %[output:744a8ccb]
%%
%[text] ### Handling Keys with Hyphens
%[text] Unlike MATLAB names, YAML names might include a hyphen. You can access these using the same syntax that table uses for referencing variables that aren"t valid MATLAB names:
appName = config.("app-name") %[output:6a69a37d]
%[text] As a convenience, you can also refer to these names using undescore (\_) instead of hyphen (-):
appName = config.app_name %[output:4875e157]
%%
%[text] ### Reading Hierarchical YAML
%[text] Most configuration files have nested structure. Let's read a more complex example:
type("examples/server_config.yaml") %[output:3997f889]
server = readyaml("examples/server_config.yaml") %[output:7c245bae]
%%
%[text] ### Multi-Level Dot Indexing
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
arrays = readyaml("examples/arrays_config.yaml") %[output:7c182cfe]
describe(arrays) %[output:2072aa20]
%%
%[text] ### Introspection
%[text] Get all top-level keys:
topKeys = keys(server) %[output:91b4b57b]
%[text] Check if a key is defined:
tf = iskey(server.application,"name") %[output:9c111a52]
%%
%[text] ### Reading Missing Keys
%[text] When you read a key that doesn't exist, you get `missing` instead of an error. This is a read-only convenience — the key isn't actually added:
value = server.nonexistent_key  %[output:new]
%%
%[text] The key wasn't actually added:
iskey(server, "nonexistent_key")  %[output:new]
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
%[text] ### Using familiar MATLAB struct functions
%[text] Familiar MATLAB struct functions `fieldnames`, `rmfield` and `isfield` are also supported. These functions behave identically to `keys` and `iskey`.
fieldnames(server) %[output:480a4b3d]
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
%[text] Read a file with various array types:
arrays = readyaml("examples/arrays_config.yaml") %[output:03fb2519]
%%
%[text] Numeric arrays convert to MATLAB numeric arrays:
ports = arrays.web.ports %[output:8868c3e2]
class(ports) %[output:5b7ba6c0]
%%
%[text] String arrays convert to MATLAB string arrays:
hosts = arrays.web.hosts %[output:41aa417d]
class(hosts) %[output:7c2463f4]
%%
%[text] Mixed-type arrays become cell arrays:
settings = arrays.web.settings %[output:5987c58e]
class(settings) %[output:8a101afa]
%%
%[text] ### Force YAML arrays to convert to cell arrays with SequenceRule
%[text] By default, arrays are converted based on their content (auto mode). If you want consistent behavior regardless of content, set `SequenceRule` `=` "`cell"` to always get cell arrays
arraysCell = readyaml("examples/arrays_config.yaml", SequenceRule="cell");
portsCell = arraysCell.web.ports %[output:80f9ff28]
class(portsCell) %[output:36ee49f0]
%%
%[text] ### Indexing into Arrays of Objects
%[text] When a YAML sequence of mappings is read, it becomes a YAMLData array. You can index into it and then use dot notation to access fields:
services = arrays.mixed %[output:30ff37cf]
firstName = services(1).name %[output:821971b8]
secondPort = services(2).port %[output:93752ded]
%[text] You can also chain the index directly:
arrays.mixed(1).name %[output:4faff471]
%%
%[text] ### Filtering Arrays by Field Value
%[text] The `mixed` array has heterogeneous structure — not all elements have the same keys. You can filter directly without pre-checking:
%[text] Even if only some elements have a `port` key, you can filter directly. For elements without `port`, the comparison `missing == 8081` returns `false`, so they're naturally excluded:
withPort = arrays.mixed(arrays.mixed.port == 8081)  %[output:new]
%%
%[text] Compare this to the explicit `iskey()` approach:
hasPort = iskey(arrays.mixed, "port");
withPortExplicit = arrays.mixed(hasPort);
withPortExplicit(withPortExplicit.port == 8081)  %[output:new]
%%
%[text] Both work. Use the simplified pattern when it reads clearly; use `iskey()` when you need to distinguish "missing" from legitimate values.
%%
%[text] `describe` is particularly useful when data contains arrays — it shows sizes and types at a glance instead of expanding every element:
describe(arrays) %[output:86ed8348]
%%
%[text] ## Writing YAML Files
%[text] After modifying configuration, write it back. Let"s read, modify, and save:
config = readyaml("examples/basic_config.yaml");
config.port = 9000;
config.("max-connections") = 100;
writeyaml(config, "examples/modified_config.yaml");
disp("Configuration saved!") %[output:0e5878c8]
%%
%[text] View what was written:
type("examples/modified_config.yaml") %[output:0109587c]
%%
%[text] ### Controlling YAML Output Format
%[text] YAML supports two styles of arrays: flow (inline) and block. Use `ArrayStyle` to control how arrays are formatted:
yml = yamldata();
yml.ports = [8080, 8443, 9000];
%[text] Flow style (inline):
writeyaml(yml, "examples/flow_style.yaml", ArrayStyle="flow");
type("examples/flow_style.yaml") %[output:5b400e05]
%%
%[text] Block style (vertical list; default):
writeyaml(yml, "examples/block_style.yaml", ArrayStyle="block");
type("examples/block_style.yaml") %[output:87c06074]
%%
%[text] Remove spacing between sections:
writeyaml(config, "examples/compact.yaml", SectionSpacing="compact");
type("examples/compact.yaml") %[output:14fbb691]
%%
%[text] ## Working with TOML Files
%[text] TOML files work similarly. Data is returned as `TOMLData`, which is like `YAMLData` but specialized for TOML.
%[text] Read a simple TOML file:
project = readtoml("examples/simple_project.toml") %[output:5a80e9c4]
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
writetoml(project, "examples/modified_project.toml");
type("examples/modified_project.toml") %[output:6d54641a]
%%
%[text] ### TOML Formatting Options
%[text] `writetoml` offers extensive formatting control. Here are common options:
%[text] TOML also supports flow and block array styles. The default for `ArrayStyle` is `auto`, which users heuristics to write small arrays with flow style and larger arrays with block. Use `ArrayStyle` `"flow"` or `"block"` to force one style.
%[text] Control array style:
project = tomldata();
project.dependencies = ["export_fig", "guilayout", "fsda"];
writetoml(project, "examples/array_flow.toml", ArrayStyle="flow")
type("examples/array_flow.toml") %[output:32f66a45]
writetoml(project, "examples/array_block.toml", ArrayStyle="block")
type("examples/array_block.toml") %[output:02fb2a7b]
%[text] TOML has multiple string styles. Use literal strings (`''`) to avoid the need to escape special characters. Control string formatting for paths (useful for Windows paths):
project.paths.data = 'C:\Users\Data';
writetoml(project, "examples/literal_strings.toml", StringEscapeStyle="literal")
type("examples/literal_strings.toml") %[output:2ec04d0c]
%%
%[text] ## Summary
%[text] You've learned how to:
%[text] - Read YAML and TOML files into intuitive data objects
%[text] - Access values with dot notation, including keys with special characters
%[text] - Use automatic aliasing for hyphenated keys
%[text] - Read missing keys safely — returns `missing` without error, enabling simplified filtering
%[text] - Explore configuration files with `keys` and `isfield`
%[text] - Modify configurations programmatically
%[text] - Understand how arrays are converted (`SequenceRule`)
%[text] - Write files with formatting control (`ArrayStyle`, `SectionSpacing`, `StringEscapeStyle`) \
%[text] For more focused examples, see:
%[text] - `examples/readtomlExample.m` - Advanced TOML reading features
%[text] - `examples/writetomlExample.m` - Complete TOML formatting options
%[text] - `examples/readyamlExample.m` - YAML reading and array handling
%[text] - `examples/writeyamlExample.m` - YAML formatting options \
%%
%[text] ## Cleanup
delete("examples/modified_config.yaml", "examples/flow_style.yaml", ...
       "examples/block_style.yaml", "examples/compact.yaml", ...
       "examples/modified_project.toml", "examples/array_flow.toml", ...
       "examples/array_block.toml", "examples/literal_strings.toml");

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
%[output:744a8ccb]
%   data: {"dataType":"textualVariable","outputData":{"name":"currentVersion","value":"\"1.2.0\""}}
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
%[output:480a4b3d]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["application","database","cache"]]}}
%---
%[output:03fb2519]
%   data: {"dataType":"textualVariable","outputData":{"name":"arrays","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    web: [1x1 YAMLData with 3 keys]\n    services: [3x1 string]\n    mixed: [1x2 YAMLData]\n\n    <a href=\"matlab:show(arrays)\">Show all values<\/a>\n"}}
%---
%[output:8868c3e2]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ports","rows":3,"type":"double","value":[["8080"],["8443"],["9000"]]}}
%---
%[output:5b7ba6c0]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'double'"}}
%---
%[output:41aa417d]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"3×1 string array","name":"hosts","rows":3,"type":"string","value":[["alpha"],["beta"],["gamma"]]}}
%---
%[output:7c2463f4]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'string'"}}
%---
%[output:5987c58e]
%   data: {"dataType":"tabular","outputData":{"columns":1,"header":"3×1 cell array","name":"settings","rows":3,"type":"cell","value":[["\"production\""],["8080"],["1"]]}}
%---
%[output:8a101afa]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'cell'"}}
%---
%[output:80f9ff28]
%   data: {"dataType":"tabular","outputData":{"columns":1,"header":"3×1 cell array","name":"portsCell","rows":3,"type":"cell","value":[["8080"],["8443"],["9000"]]}}
%---
%[output:36ee49f0]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"'cell'"}}
%---
%[output:30ff37cf]
%   data: {"dataType":"textualVariable","outputData":{"name":"services","value":"  1x2 <a href=\"matlab:helpPopup matlab.io.config.YAMLData\">YAMLData<\/a> array with keys:\n\n    name\n    port\n\n    <a href=\"matlab:show(services)\">Show all values<\/a>\n"}}
%---
%[output:821971b8]
%   data: {"dataType":"textualVariable","outputData":{"name":"firstName","value":"\"service1\""}}
%---
%[output:93752ded]
%   data: {"dataType":"textualVariable","outputData":{"name":"secondPort","value":"8081"}}
%---
%[output:4faff471]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"service1\""}}
%---
%[output:86ed8348]
%   data: {"dataType":"text","outputData":{"text":"\n  YAMLData with 3 keys\n\n    web:\n        ports:              3x1 double\n        hosts:              3x1 string\n        settings:           3x1 cell\n    services:           3x1 string\n    mixed:              1x2 array\n        name:               string\n        port:               double\n\n","truncated":false}}
%---
%[output:0e5878c8]
%   data: {"dataType":"text","outputData":{"text":"Configuration saved!\n","truncated":false}}
%---
%[output:0109587c]
%   data: {"dataType":"text","outputData":{"text":"\napp-name: MyApplication\n\nversion: 1.2.0\n\nport: 9000\n\ndebug: true\n\nauthor: Jane Doe\n\nmax-connections: 100\n","truncated":false}}
%---
%[output:5b400e05]
%   data: {"dataType":"text","outputData":{"text":"\nports: [8080, 8443, 9000]\n","truncated":false}}
%---
%[output:87c06074]
%   data: {"dataType":"text","outputData":{"text":"\nports:\n  - 8080\n  - 8443\n  - 9000\n","truncated":false}}
%---
%[output:14fbb691]
%   data: {"dataType":"text","outputData":{"text":"\napp-name: MyApplication\nversion: 1.2.0\nport: 9000\ndebug: true\nauthor: Jane Doe\nmax-connections: 100\n","truncated":false}}
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
%[output:32f66a45]
%   data: {"dataType":"text","outputData":{"text":"\ndependencies = [\"export_fig\", \"guilayout\", \"fsda\"]\n","truncated":false}}
%---
%[output:02fb2a7b]
%   data: {"dataType":"text","outputData":{"text":"\ndependencies = [\n  \"export_fig\",\n  \"guilayout\",\n  \"fsda\"\n]\n","truncated":false}}
%---
%[output:2ec04d0c]
%   data: {"dataType":"text","outputData":{"text":"\ndependencies = ['export_fig', 'guilayout', 'fsda']\n\n[paths]\ndata = 'C:\\Users\\Data'\n","truncated":false}}
%---

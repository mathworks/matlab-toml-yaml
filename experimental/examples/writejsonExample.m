%[text] # WriteJSONExample - Comprehensive guide to writing JSON files
%[text] This example demonstrates all formatting options available in writejson, showing how to control the appearance and style of your JSON output files.
%%
%[text] ## Setup: Create Sample Data
%[text] Create a sample jsondata() object for our demonstrations.
project = jsondata();
project.name = "my-package";
project.version = "1.0.0";
project.description = "A demonstration project";
project.keywords = ["example", "demo", "json"];
project.author.name = "Alice Smith";
project.author.email = "alice@example.com";
project.dependencies.lodash = "^4.17.21";
project.dependencies.express = "^4.18.2";
%%
%[text] ## Basic Writing
%[text] Write JSON file with default settings (pretty printed).
writejson(project, "output_default.json");
type("output_default.json")
%%
%[text] ## PrettyPrint Option - True (Default)
%[text] Control output formatting. PrettyPrint=true adds indentation and newlines for human readability.
writejson(project, "output_pretty.json", PrettyPrint=true);
type("output_pretty.json")
%%
%[text] ## PrettyPrint Option - False
%[text] Compact single-line output. Best for machine consumption or minimizing file size.
writejson(project, "output_compact.json", PrettyPrint=false);
type("output_compact.json")
%%
%[text] ## EmptyValue Option - Array (Default)
%[text] Control how empty arrays ([]) are written. 'array' (default) writes them as empty JSON arrays.
data = jsondata();
data.name = "test";
data.required = "value";
data.optional = [];  % empty value
writejson(data, "output_array.json", EmptyValue="array");
type("output_array.json")
%%
%[text] ## EmptyValue Option - Null
%[text] 'null' writes empty arrays as JSON null.
writejson(data, "output_null.json", EmptyValue="null");
type("output_null.json")
%%
%[text] ## EmptyValue Option - Omit
%[text] 'omit' removes keys with empty values entirely from output. Best for cleaner output when empty values are optional fields.
writejson(data, "output_omit.json", EmptyValue="omit");
type("output_omit.json")
%%
%[text] ## Writing Explicit Null Values
%[text] Use JSONNull to explicitly write JSON null values (distinct from empty arrays).
nullData = jsondata();
nullData.name = "test";
nullData.explicitNull = matlab.io.config.JSONNull();
nullData.emptyArray = [];
writejson(nullData, "output_explicit_null.json");
type("output_explicit_null.json")
%%
%[text] ## Working with Arrays
%[text] JSON arrays are formatted inline or multiline based on PrettyPrint setting.
arrayData = jsondata();
arrayData.numbers = [1, 2, 3, 4, 5];
arrayData.strings = ["apple", "banana", "cherry"];
arrayData.matrix = [1 2; 3 4];
writejson(arrayData, "output_arrays.json");
type("output_arrays.json")
%%
%[text] ## Working with Array of Objects
%[text] Create an array of JSONData objects for complex structures.
config = jsondata();
step1 = jsondata();
step1.name = "Checkout";
step1.uses = "actions/checkout@v4";
step2 = jsondata();
step2.name = "Build";
step2.run = "make build";
step3 = jsondata();
step3.name = "Test";
step3.run = "make test";
config.steps = [step1; step2; step3];
writejson(config, "output_steps.json");
type("output_steps.json")
%%
%[text] ## Working with Booleans
%[text] MATLAB logical values are written as JSON true/false.
settings = jsondata();
settings.enabled = true;
settings.debug = false;
settings.features.autoUpdate = true;
settings.features.telemetry = false;
writejson(settings, "output_booleans.json");
type("output_booleans.json")
%%
%[text] ## Working with Special Characters in Keys
%[text] Keys with hyphens, dots, or spaces are preserved in output.
special = jsondata();
special.("simple-key") = "value1";
special.("another.key") = "value2";
special.("with spaces") = "value3";
special.normal_key = "value4";
writejson(special, "output_special_keys.json");
type("output_special_keys.json")
%%
%[text] ## Converting from Struct
%[text] writejson accepts standard MATLAB structs as input.
myStruct.name = "from-struct";
myStruct.version = "1.0.0";
myStruct.nested.value = 42;
writejson(myStruct, "output_struct.json");
type("output_struct.json")
%%
%[text] ## Converting from Dictionary
%[text] writejson also accepts MATLAB dictionary objects.
myDict = dictionary(["name", "version", "count"], {"my-app", "2.0.0", 100});
writejson(myDict, "output_dict.json");
type("output_dict.json")
%%
%[text] ## Cross-Format Conversion
%[text] Read from one format and write to JSON. ConfigurationData objects are interchangeable.
tomlContent = [
    "[project]"
    "name = ""converted-project"""
    "version = ""1.0.0"""
    ""
    "[project.metadata]"
    "author = ""Jane Doe"""
    "license = ""MIT"""];
writelines(tomlContent, "input.toml");
tomlData = readtoml("input.toml");
%[text] Write TOML data as JSON:
writejson(tomlData, "output_from_toml.json");
type("output_from_toml.json")
%%
%[text] ## Round-Trip: Read and Modify
%[text] Read a JSON file, modify it, and write it back.
originalJson = sprintf('{\n  "name": "original",\n  "version": "1.0.0",\n  "count": 10\n}');
writelines(originalJson, "original.json");
%[text] Read the file:
config = readjson("original.json");
%[text] Modify values:
config.version = "1.1.0";
config.count = config.count + 5;
config.updated = true;
%[text] Write back:
writejson(config, "modified.json");
type("modified.json")
%%
%[text] ## Real-World Example: VS Code Settings
%[text] Create a VS Code settings.json file.
settings = jsondata();
settings.("editor.fontSize") = 14;
settings.("editor.tabSize") = 2;
settings.("editor.formatOnSave") = true;
settings.("files.autoSave") = "afterDelay";
settings.("files.autoSaveDelay") = 1000;
settings.("workbench.colorTheme") = "One Dark Pro";
settings.("terminal.integrated.fontSize") = 12;
writejson(settings, "vscode_settings.json");
type("vscode_settings.json")
%%
%[text] ## Real-World Example: package.json
%[text] Create a complete Node.js package.json file.
pkg = jsondata();
pkg.name = "my-awesome-app";
pkg.version = "1.0.0";
pkg.description = "An awesome application";
pkg.main = "index.js";
pkg.scripts.test = "jest";
pkg.scripts.build = "tsc";
pkg.scripts.start = "node dist/index.js";
pkg.keywords = ["awesome", "app", "typescript"];
pkg.author.name = "Developer";
pkg.author.email = "dev@example.com";
pkg.license = "MIT";
pkg.dependencies.express = "^4.18.2";
pkg.dependencies.("body-parser") = "^1.20.0";
pkg.devDependencies.typescript = "^5.0.0";
pkg.devDependencies.jest = "^29.0.0";
pkg.devDependencies.("@types/node") = "^20.0.0";
pkg.repository.type = "git";
pkg.repository.url = "https://github.com/dev/my-awesome-app.git";
pkg.private = false;
writejson(pkg, "my_package.json");
type("my_package.json")
%%
%[text] ## Best Practices
%[text] Recommended settings by use case:
%[text] - **Human-readable config files**: PrettyPrint=true (default)
%[text] - **API responses/data transfer**: PrettyPrint=false
%[text] - **Optional fields handling**: EmptyValue="omit" to remove empty values
%[text] - **Empty arrays as arrays**: EmptyValue="array" (default)
%[text] - **Explicit null values**: Use matlab.io.config.JSONNull()
%[text] - **Cross-format workflows**: Read with readyaml/readtoml, write with writejson
%%
%[text] ## Cleanup
%[text] Delete temporary output files.
delete("output_default.json", "output_pretty.json", "output_compact.json", ...
    "output_array.json", "output_null.json", "output_omit.json", ...
    "output_explicit_null.json", "output_arrays.json", ...
    "output_steps.json", "output_booleans.json", "output_special_keys.json", ...
    "output_struct.json", "output_dict.json", "input.toml", ...
    "output_from_toml.json", "original.json", "modified.json", ...
    "vscode_settings.json", "my_package.json");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

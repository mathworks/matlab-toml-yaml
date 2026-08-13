%[text] # ReadJSONExample - Comprehensive guide to reading JSON files
%[text] This example demonstrates readjson functionality, showing how to work with JSON configuration files, access data with dot notation, handle special characters, and work with complex nested structures.
%%
%[text] ## Basic JSON Reading
%[text] Read a simple JSON file and access its contents.
%[text] First, create a sample JSON file.
jsonContent = sprintf('{\n  "name": "my-package",\n  "version": "1.0.0",\n  "description": "A sample project",\n  "enabled": true\n}');
writelines(jsonContent, "simple.json");
%[text] Read the JSON file. The output is returned as JSONData, which is a struct-like object specialized for working with JSON data.
config = readjson("simple.json") %[output:80525f4f]
%%
%[text] Access values using dot notation.
config.name %[output:8f83a587]
%%
%[text] ## Working with Nested Objects
%[text] JSON objects create nested structures.
jsonNested = sprintf('{\n  "project": {\n    "name": "my-package",\n    "version": "2.0.0",\n    "urls": {\n      "homepage": "https://github.com/user/project",\n      "repository": "https://github.com/user/project.git"\n    }\n  }\n}') %[output:467057b8]
writelines(jsonNested, "nested.json");
proj = readjson("nested.json") %[output:1e019286]
%[text] Navigate through the structure with dot notation:
proj.project %[output:6f85d4ee]
proj.project.urls.homepage %[output:86d72c5b]
%%
%[text] ## Keys with Special Characters
%[text] Use dynamic field access for keys that are not valid MATLAB identifiers
jsonSpecial = sprintf('{\n  "build-system": {\n    "requires": ["setuptools>=61.0", "wheel"],\n    "build-backend": "setuptools.build_meta"\n  }\n}');
writelines(jsonSpecial, "special.json");
data = readjson("special.json") %[output:3af7f262]
%[text] Access keys with special characters using quoted syntax.
data.("build-system") %[output:88e2ae3f]
%[text] Build backend:
data.("build-system").("build-backend") %[output:82d5309a]
%%
%[text] ## Working with Arrays
%[text] JSON arrays are converted to MATLAB arrays.
jsonArrays = sprintf('{\n  "numbers": [1, 2, 3, 4, 5],\n  "strings": ["apple", "banana", "cherry"],\n  "mixed": [1, "two", true, null]\n}');
writelines(jsonArrays, "arrays.json");
arrays = readjson("arrays.json");
%[text] Numeric arrays stay numeric:
arrays.numbers %[output:0e71d841]
%%
%[text] String arrays stay as strings:
arrays.strings %[output:121920ab]
%%
%[text] Mixed arrays become cell arrays:
arrays.mixed %[output:23ce6447]
%%
%[text] ## SequenceRule Option
%[text] Control how arrays are converted to MATLAB types. With `"auto"` (default), homogeneous arrays map to the appropriate MATLAB array type:
arraysAuto = readjson("arrays.json", SequenceRule="auto") %[output:723a6c5d]
%%
%[text] Use `"cell"` to force all arrays to become cell arrays:
arraysCell = readjson("arrays.json", SequenceRule="cell") %[output:0826add7]
%[text] `SequenceRule="cell"` is useful for two specific scenarios:
%[text] - It preserves the array-ness of JSON arrays with a single value when writing back to JSON. Without this, the value will write to JSON as a scalar.
%[text] - It provides a more stable return type for data that is sometimes homogeneous and sometimes heterogeneous \
%%
%[text] ## Array of Objects
%[text] Arrays of objects are common in JSON configuration files.
jsonArrayOfObjects = sprintf('{\n  "steps": [\n    {"name": "Checkout", "uses": "actions/checkout@v4"},\n    {"name": "Build", "run": "make build"},\n    {"name": "Test", "run": "make test"}\n  ]\n}');
writelines(jsonArrayOfObjects, "workflow.json");
workflow = readjson("workflow.json") %[output:50b8d446]
%[text] `steps` is a 3x1 array of `JSONData`. JSONData arrays behave slightly differently from struct arrays, because all elements in a JSONData array are not required to have the same keys:
steps = workflow.steps %[output:474d7614]
%%
%[text] Since keys might not be the same, you can't generate a comma-separated list of all values of the same key:
%[text] ```matlabCodeExample
%[text] >> workflow.steps.name
%[text] 
%[text] Error using  .  (line 378)
%[text] Cannot access field 'name' on a [3 1] array of matlab.io.config.JSONData objects.
%[text] Index into the array first, e.g., obj(1).name or use:
%[text]   arrayfun(@(x) x.name, obj)
%[text] ```
%[text] Access values for a single array element at a time:
steps(1).name %[output:8b61e85a]
%[text] Following the hint in the error message, use `arrayfun` to access or operate on values across the array. This works if all array elements have the same key:
allnames = arrayfun(@(x) x.name, steps) %[output:29eb553d]
%[text] This errors if you request a key that is not in all array elements:
%[text] ```
%[text] >> arrayfun(@(x) x.run, steps)
%[text] 
%[text] Error using  .  (line 446)
%[text] Key "run" does not exist.
%[text] ```
%%
%[text] ## Exploring Unknown JSON Files
%[text] Use keys and iskey to explore JSON structure.
%[text] Keys in project:
keys(proj) %[output:1b165e65]
%%
%[text] Check if specific fields exist.
if iskey(proj, "project") %[output:group:3589c8b9]
    disp("Project section exists") %[output:4a3b1678]
    if iskey(proj.project, "urls")
        disp("URLs section exists") %[output:9da43adb]
    end
end %[output:group:3589c8b9]
%%
%[text] Use show for formatted display:
show(proj) %[output:3836e79c]
%%
%[text] ### Reading Potentially Missing Keys
%[text] You can read keys directly without checking existence first — missing keys return `missing`:
value = proj.nonexistent  %[output:new]
%%
%[text] This is useful for filtering and comparisons, especially with arrays. Elements without optional fields are excluded naturally:
%[text] ```matlab
%[text] % Filter array by optional field value
%[text] filtered = items(items.optional_field == "value")
%[text] % Elements without optional_field return missing, and missing == "value" is false
%[text] ```
%[text] Use `iskey()` when you need to distinguish "missing" from "exists but doesn't match."
%%
%[text] ## Data Types in JSON
%[text] JSON supports various data types.
jsonTypes = sprintf('{\n  "string_val": "Hello, World!",\n  "integer_val": 42,\n  "float_val": 3.14159,\n  "boolean_true": true,\n  "boolean_false": false,\n  "null_val": null,\n  "array_val": [1, 2, 3],\n  "object_val": {"nested": "value"}\n}');
writelines(jsonTypes, "types.json");
types = readjson("types.json") %[output:41548ba0]
%[text] 
%%
%[text] ## Handling Null Values
%[text] Empty values in JSON are converted to empty double arrays in MATLAB. `null` values in JSON are converted to `JSONNull`. Successful round-trip behavior requires distinguishing between JSON null and empty in MATLAB. 
%[text] null is converted to empty double array (\[\]).
jsonWithNull = sprintf('{\n  "name": "test",\n  "null_value": null,\n  "empty_value": []\n}') %[output:7c016aa4]
writelines(jsonWithNull, "nulls.json");
nullData = readjson("nulls.json") %[output:349792b0]
%[text] `JSONNull` is always considered empty:
isempty(nullData.null_value) %[output:74868f49]
%%
%[text] ## Converting to Struct
%[text] Convert JSONData to standard MATLAB struct when needed.
% jsonSimple = sprintf('{\n  "server": {\n    "host": "localhost",\n    "port": 8080\n  }\n}');
jsonSimple = sprintf('{\n    "host": "localhost",\n    "@port": 8080\n  }');
writelines(jsonSimple, "server.json");
serverConfig = readjson("server.json");
%[text] Convert to struct. Keys are [converted to valid MATLAB identifiers](https://www.mathworks.com/help/matlab/ref/matlab.lang.makevalidname.html) if needed.
serverStruct = struct(serverConfig) %[output:128fa2aa] %[output:8b5c05bb] %[output:9b1f3849] %[output:59f92ec6] %[output:1d83c352] %[output:7518965b] %[output:0bb150d9] %[output:28dd07a8]
%%
%[text] ## Summary of Tips
%[text] Summary of tips for reading JSON files:
%[text] - Use dot notation for simple keys: `config.name`
%[text] - Use quoted syntax for special characters: `config.("build-system")`
%[text] - Use `keys` to explore unknown structures
%[text] - Use `iskey` to check for optional fields
%[text] - Direct filtering with potentially missing keys: `arr(arr.field == value)` works naturally
%[text] - Use `show` for formatted display during debugging
%[text] - Use `SequenceRule="cell"` when you need consistent array handling \
%%
%[text] ## Cleanup
%[text] Delete temporary JSON files.
delete("simple.json", "nested.json", "special.json", "arrays.json", ...
    "workflow.json", "types.json", "nulls.json", "server.json", "package.json");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:80525f4f]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    name: \"my-package\"\n    version: \"1.0.0\"\n    description: \"A sample project\"\n    enabled: true\n"}}
%---
%[output:8f83a587]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"my-package\""}}
%---
%[output:467057b8]
%   data: {"dataType":"textualVariable","outputData":{"name":"jsonNested","value":"    '{\n       \"project\": {\n         \"name\": \"my-package\",\n         \"version\": \"2.0.0\",\n         \"urls\": {\n           \"homepage\": \"https:\/\/github.com\/user\/project\",\n           \"repository\": \"https:\/\/github.com\/user\/project.git\"\n         }\n       }\n     }'\n"}}
%---
%[output:1e019286]
%   data: {"dataType":"textualVariable","outputData":{"name":"proj","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    project: [1x1 JSONData with 3 keys]\n\n    <a href=\"matlab:show(proj)\">Show all values<\/a>\n"}}
%---
%[output:6f85d4ee]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    name: \"my-package\"\n    version: \"2.0.0\"\n    urls: [1x1 JSONData with 2 keys]\n\n    <a href=\"matlab:show(ans)\">Show all values<\/a>\n"}}
%---
%[output:86d72c5b]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"https:\/\/github.com\/user\/project\""}}
%---
%[output:3af7f262]
%   data: {"dataType":"textualVariable","outputData":{"name":"data","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    build-system: [1x1 JSONData with 2 keys]\n\n    <a href=\"matlab:show(data)\">Show all values<\/a>\n"}}
%---
%[output:88e2ae3f]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    requires: [2x1 string]\n    build-backend: \"setuptools.build_meta\"\n"}}
%---
%[output:82d5309a]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"setuptools.build_meta\""}}
%---
%[output:0e71d841]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":5,"type":"double","value":[["1"],["2"],["3"],["4"],["5"]]}}
%---
%[output:121920ab]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"3×1 string array","name":"ans","rows":3,"type":"string","value":[["apple"],["banana"],["cherry"]]}}
%---
%[output:23ce6447]
%   data: {"dataType":"tabular","outputData":{"columns":1,"header":"4×1 cell array","name":"ans","rows":4,"type":"cell","value":[["1"],["\"two\""],["1"],["[ ]"]]}}
%---
%[output:723a6c5d]
%   data: {"dataType":"textualVariable","outputData":{"name":"arraysAuto","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    numbers: [1 2 3 4 5]\n    strings: [3x1 string]\n    mixed: [4x1 cell]\n"}}
%---
%[output:0826add7]
%   data: {"dataType":"textualVariable","outputData":{"name":"arraysCell","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    numbers: [5x1 cell]\n    strings: [3x1 cell]\n    mixed: [4x1 cell]\n"}}
%---
%[output:50b8d446]
%   data: {"dataType":"textualVariable","outputData":{"name":"workflow","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    steps: [3x1 JSONData]\n\n    <a href=\"matlab:show(workflow)\">Show all values<\/a>\n"}}
%---
%[output:474d7614]
%   data: {"dataType":"textualVariable","outputData":{"name":"steps","value":"  3x1 <a href=\"matlab:helpPopup matlab.io.config.JSONData\">JSONData<\/a> array with keys:\n\n    name\n    uses\n    run\n\n    (keys vary by element)\n\n    <a href=\"matlab:show(steps)\">Show all values<\/a>\n"}}
%---
%[output:8b61e85a]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"Checkout\""}}
%---
%[output:29eb553d]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"3×1 string array","name":"allnames","rows":3,"type":"string","value":[["Checkout"],["Build"],["Test"]]}}
%---
%[output:1b165e65]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"project\""}}
%---
%[output:4a3b1678]
%   data: {"dataType":"text","outputData":{"text":"Project section exists\n","truncated":false}}
%---
%[output:9da43adb]
%   data: {"dataType":"text","outputData":{"text":"URLs section exists\n","truncated":false}}
%---
%[output:3836e79c]
%   data: {"dataType":"text","outputData":{"text":"{\n  \"project\": {\n    \"name\": \"my-package\",\n    \"version\": \"2.0.0\",\n    \"urls\": {\n      \"homepage\": \"https:\/\/github.com\/user\/project\",\n      \"repository\": \"https:\/\/github.com\/user\/project.git\"\n    }\n  }\n}\n","truncated":false}}
%---
%[output:41548ba0]
%   data: {"dataType":"textualVariable","outputData":{"name":"types","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    string_val: \"Hello, World!\"\n    integer_val: 42\n    float_val: 3.14159\n    boolean_true: true\n    boolean_false: false\n    null_val: [1x1 matlab.io.config.JSONNull]\n    array_val: [1 2 3]\n    object_val: [1x1 JSONData with 1 key]\n\n    <a href=\"matlab:show(types)\">Show all values<\/a>\n"}}
%---
%[output:7c016aa4]
%   data: {"dataType":"textualVariable","outputData":{"name":"jsonWithNull","value":"    '{\n       \"name\": \"test\",\n       \"null_value\": null,\n       \"empty_value\": []\n     }'\n"}}
%---
%[output:349792b0]
%   data: {"dataType":"textualVariable","outputData":{"name":"nullData","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    name: \"test\"\n    null_value: [1x1 matlab.io.config.JSONNull]\n    empty_value: []\n"}}
%---
%[output:74868f49]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:128fa2aa]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"serverStruct","value":"      host: \"localhost\"\n    x_port: 8080\n"}}
%---
%[output:8b5c05bb]
%   data: {"dataType":"textualVariable","outputData":{"name":"pkg","value":"  <a href=\"matlab:helpPopup('matlab.io.config.JSONData')\" style=\"font-weight:bold\">JSONData<\/a> with keys:\n\n    name: \"example-package\"\n    version: \"2.1.0\"\n    description: \"An example package for testing JSON support\"\n    main: \"index.js\"\n    scripts: [1x1 JSONData with 3 keys]\n    keywords: [3x1 string]\n    author: [1x1 JSONData with 2 keys]\n    license: \"MIT\"\n    dependencies: [1x1 JSONData with 2 keys]\n    devDependencies: [1x1 JSONData with 2 keys]\n    repository: [1x1 JSONData with 2 keys]\n    private: false\n\n    <a href=\"matlab:show(pkg)\">Show all values<\/a>\n"}}
%---
%[output:9b1f3849]
%   data: {"dataType":"text","outputData":{"text":"Name: example-package\n","truncated":false}}
%---
%[output:59f92ec6]
%   data: {"dataType":"text","outputData":{"text":"Version: 2.1.0\n","truncated":false}}
%---
%[output:1d83c352]
%   data: {"dataType":"text","outputData":{"text":"Description: An example package for testing JSON support\n","truncated":false}}
%---
%[output:7518965b]
%   data: {"dataType":"text","outputData":{"text":"License: MIT\n","truncated":false}}
%---
%[output:0bb150d9]
%   data: {"dataType":"text","outputData":{"text":"Scripts:\n","truncated":false}}
%---
%[output:28dd07a8]
%   data: {"dataType":"text","outputData":{"text":"  test: jest\n  build: tsc\n  lint: eslint src\/\n","truncated":false}}
%---

%[text] # ReadTOMLExample - Comprehensive guide to reading TOML files
%[text] This example demonstrates readtoml functionality, showing how to work with TOML configuration files, access data with dot notation, handle special characters, and work with complex nested structures.
%%
%[text] ## Basic TOML Reading
%[text] Read a simple TOML file and access its contents
%[text] First, create a sample TOML file
tomlContent = [
    "name = ""my-package"""
    "version = ""1.0.0"""
    "description = ""A sample project"""
    "enabled = true"];
writelines(tomlContent,"simple.toml");
%[text] Read the TOML file. The output is returned as TOMLData, which is a struct-like object specialized for working with TOML Data.
config = readtoml("simple.toml") %[output:17a8cbcf]
%%
%[text] Access values using dot notation
config.name %[output:234e1394]
%%
%[text] ## Working with Nested Tables
%[text] TOML tables create nested structures
tomlNested = [
    "[project]"
    "name = ""my-package"""
    "version = ""2.0.0"""
    ""
    "[project.urls]"
    "homepage = ""https://github.com/user/project"""
    "repository = ""https://github.com/user/project.git"""];
writelines(tomlNested,"nested.toml");
project = readtoml("nested.toml");
%[text] Nested structure:
project %[output:83527759]
%%
%[text] Navigate nested tables with dot notation
project.project.urls.homepage %[output:46d15637]
%%
%[text] ## Keys with Special Characters
%[text] Use dynamic field access for keys with hyphens, dots, or spaces
tomlSpecial = [
    "[build-system]"
    "requires = [""setuptools>=61.0"", ""wheel""]"
    "build-backend = ""setuptools.build_meta"""];
writelines(tomlSpecial,"special.toml");
data = readtoml("special.toml");
%[text] Access keys with special characters using quoted syntax
buildSystem = data.("build-system");
%[text] Build system requires:
buildSystem.requires %[output:79ec0d68]
%[text] Build backend:
buildSystem.("build-backend") %[output:8199a88c]
%%
%[text] ## Working with Arrays
%[text] TOML supports both inline and multi-line arrays
tomlArrays = [
    "numbers = [1, 2, 3, 4, 5]"
    "strings = [""apple"", ""banana"", ""cherry""]"
    ""
    "multiline = ["
    "  ""first"","
    "  ""second"","
    "  ""third"""
    "]"];
writelines(tomlArrays,"arrays.toml");
arrays = readtoml("arrays.toml");
%[text] Arrays:
arrays.numbers %[output:0245598b]
%%
%[text] ## Array of Tables - GitHub Actions Style
%[text] Arrays of tables are common in configuration files
tomlArrayOfTables = [
    "[[steps]]"
    "name = ""Checkout"""
    "uses = ""actions/checkout@v4"""
    ""
    "[[steps]]"
    "name = ""Build"""
    "run = ""make build"""
    ""
    "[[steps]]"
    "name = ""Test"""
    "run = ""make test"""];
writelines(tomlArrayOfTables,"workflow.toml");
workflow = readtoml("workflow.toml");
%[text] Workflow steps:
%[text] Access array of tables with indexing
for i = 1:numel(workflow.steps) %[output:group:88d5d06b]
    fprintf("Step %d: %s\n", i, workflow.steps(i).name); %[output:911bd527]
end %[output:group:88d5d06b]
%%
%[text] Access individual step properties
workflow.steps(1).uses %[output:5cd3d5c3]
%%
%[text] Extract all values from an array using arrayfun
%[text] To get all names from the array at once:
allNames = arrayfun(@(x) x.name, workflow.steps) %[output:0b4a0710]
%%
%[text] ## Exploring Unknown TOML Files
%[text] Use keys and isfield to explore TOML structure
%[text] Keys in project:
keys(project) %[output:70b5246a]
%%
%[text] Check if specific fields exist
if isfield(project, "project") %[output:group:94bc2248]
    disp("Project section exists") %[output:3fecba4f]
    if isfield(project.project, "urls")
        disp("URLs section exists") %[output:65df9433]
    end
end %[output:group:94bc2248]
%%
%[text] Use show for formatted display (function syntax required)
%[text] Project structure:
show(project) %[output:82e03ecb]
%%
%[text] ### Reading Potentially Missing Keys
%[text] You can read keys directly without checking existence first — missing keys return `missing`:
value = project.nonexistent 
%%
%[text] This is useful for filtering and comparisons, especially with arrays. Elements without optional fields are excluded naturally:
%[text] ```
%[text] % Filter array by optional field value
%[text] filtered = items(items.optional_field == "value")
%[text] % Elements without optional_field return missing, and missing == "value" is false
%[text] ```
%[text] Use `iskey()` when you need to distinguish "missing" from "exists but doesn't match."
%%
%[text] ## Data Types in TOML
%[text] TOML supports various data types
tomlTypes = [
    "string_val = ""Hello, World!"""
    "integer_val = 42"
    "float_val = 3.14159"
    "boolean_true = true"
    "boolean_false = false"
    "date_val = 2024-01-15T10:30:00Z"];
writelines(tomlTypes,"types.toml");
types = readtoml("types.toml");
%[text] Data types:
fprintf("String: %s (class: %s)\n", types.string_val, class(types.string_val)); %[output:62c346d0]
fprintf("Integer: %d (class: %s)\n", types.integer_val, class(types.integer_val)); %[output:46398b3c]
fprintf("Float: %.5f (class: %s)\n", types.float_val, class(types.float_val)); %[output:40ea9fdc]
fprintf("Boolean true: %d (class: %s)\n", types.boolean_true, class(types.boolean_true)); %[output:6ee79ac1]
fprintf("Boolean false: %d (class: %s)\n", types.boolean_false, class(types.boolean_false)); %[output:7124caca]
fprintf("Date: %s (class: %s)\n", string(types.date_val), class(types.date_val)); %[output:99f09580]
%%
%[text] ## Converting to Struct
%[text] Convert TOMLData to standard MATLAB struct when needed
tomlSimple = [
    "[server]"
    "host = ""localhost"""
    "port = 8080"];
writelines(tomlSimple,"server.toml");
serverConfig = readtoml("server.toml");
%[text] Convert to struct
serverStruct = struct(serverConfig);
%[text] Converted to struct:
serverStruct %[output:17a076f7]
%%
%[text] ## Real-World Example: Python pyproject.toml
%[text] Read a realistic Python project configuration
pyprojectContent = [
    "[project]"
    "name = ""example-package"""
    "version = ""1.0.0"""
    "description = ""An example Python package"""
    "authors = ["
    "    ""Alice Smith <alice@example.com>"","
    "    ""Bob Jones <bob@example.com>"""
    "]"
    "dependencies = ["
    "    ""numpy>=1.20"","
    "    ""pandas>=1.3"","
    "    ""matplotlib>=3.4"""
    "]"
    ""
    "[project.urls]"
    "homepage = ""https://github.com/example/package"""
    "repository = ""https://github.com/example/package.git"""
    "documentation = ""https://example-package.readthedocs.io"""
    ""
    "[build-system]"
    "requires = [""setuptools>=61.0"", ""wheel""]"
    "build-backend = ""setuptools.build_meta"""];
writelines(pyprojectContent,"pyproject.toml");
pyproject = readtoml("pyproject.toml");
%[text] Access project metadata
%[text] Python Project Configuration:
fprintf("Name: %s\n", pyproject.project.name); %[output:2400d8eb]
fprintf("Version: %s\n", pyproject.project.version); %[output:39dd9f16]
fprintf("Description: %s\n", pyproject.project.description); %[output:4e923df1]
%%
%[text] Work with arrays
disp("Authors:") %[output:671f3dd4]
for i = 1:numel(pyproject.project.authors) %[output:group:38b21bc0]
    fprintf("  - %s\n", pyproject.project.authors(i)); %[output:4929a4d1]
end %[output:group:38b21bc0]
disp("Dependencies:") %[output:82fc69d3]
for i = 1:numel(pyproject.project.dependencies) %[output:group:120a3394]
    fprintf("  - %s\n", pyproject.project.dependencies(i)); %[output:8f9de3c4]
end %[output:group:120a3394]
%%
%[text] Access nested configuration
disp("Project URLs:") %[output:2f4a0607]
fprintf("  Homepage: %s\n", pyproject.project.urls.homepage); %[output:14afaa9b]
fprintf("  Repository: %s\n", pyproject.project.urls.repository); %[output:9a08f710]
fprintf("  Documentation: %s\n", pyproject.project.urls.documentation); %[output:92e0ac02]
%%
%[text] Build system configuration
buildSys = pyproject.("build-system");
disp("Build System:") %[output:5058f720]
fprintf("  Backend: %s\n", buildSys.("build-backend")); %[output:85b36b21]
fprintf("  Requires: %s\n", strjoin(buildSys.requires, ", ")); %[output:9b12b670]
%%
%[text] ## Best Practices
%[text] Best practices for reading TOML files:
%[text] - Use dot notation for simple keys: config.name
%[text] - Use quoted syntax for special characters: config.("build-system")
%[text] - Use keys to explore unknown structures
%[text] - Use isfield to check for optional fields
%[text] - Missing keys return `missing` for convenience; use `iskey()` for explicit existence checks
%[text] - Use show for formatted display during debugging
%[text] - Convert to struct when interfacing with code expecting structs\\ \
%%
%[text] ## Cleanup
%[text] Delete temporary TOML files
delete("simple.toml", "nested.toml", "special.toml", "arrays.toml", ...
    "workflow.toml", "types.toml", "server.toml", "pyproject.toml");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:17a8cbcf]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    name: \"my-package\"\n    version: \"1.0.0\"\n    description: \"A sample project\"\n    enabled: true\n"}}
%---
%[output:234e1394]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"my-package\""}}
%---
%[output:83527759]
%   data: {"dataType":"textualVariable","outputData":{"name":"project","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    project: [1x1 TOMLData with 3 keys]\n\n    <a href=\"matlab:show(project)\">Show all values<\/a>\n"}}
%---
%[output:46d15637]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"https:\/\/github.com\/user\/project\""}}
%---
%[output:79ec0d68]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 string array","name":"ans","rows":1,"type":"string","value":[["setuptools>=61.0","wheel"]]}}
%---
%[output:8199a88c]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"setuptools.build_meta\""}}
%---
%[output:0245598b]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"ans","rows":1,"type":"double","value":[["1","2","3","4","5"]]}}
%---
%[output:911bd527]
%   data: {"dataType":"text","outputData":{"text":"Step 1: Checkout\nStep 2: Build\nStep 3: Test\n","truncated":false}}
%---
%[output:5cd3d5c3]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"actions\/checkout@v4\""}}
%---
%[output:0b4a0710]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"allNames","rows":1,"type":"string","value":[["Checkout","Build","Test"]]}}
%---
%[output:70b5246a]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"project\""}}
%---
%[output:3fecba4f]
%   data: {"dataType":"text","outputData":{"text":"Project section exists\n","truncated":false}}
%---
%[output:65df9433]
%   data: {"dataType":"text","outputData":{"text":"URLs section exists\n","truncated":false}}
%---
%[output:82e03ecb]
%   data: {"dataType":"text","outputData":{"text":"[project]\nname = \"my-package\"\nversion = \"2.0.0\"\n\n[project.urls]\nhomepage = \"https:\/\/github.com\/user\/project\"\nrepository = \"https:\/\/github.com\/user\/project.git\"\n\n","truncated":false}}
%---
%[output:62c346d0]
%   data: {"dataType":"text","outputData":{"text":"String: Hello, World! (class: string)\n","truncated":false}}
%---
%[output:46398b3c]
%   data: {"dataType":"text","outputData":{"text":"Integer: 42 (class: double)\n","truncated":false}}
%---
%[output:40ea9fdc]
%   data: {"dataType":"text","outputData":{"text":"Float: 3.14159 (class: double)\n","truncated":false}}
%---
%[output:6ee79ac1]
%   data: {"dataType":"text","outputData":{"text":"Boolean true: 1 (class: logical)\n","truncated":false}}
%---
%[output:7124caca]
%   data: {"dataType":"text","outputData":{"text":"Boolean false: 0 (class: logical)\n","truncated":false}}
%---
%[output:99f09580]
%   data: {"dataType":"text","outputData":{"text":"Date: 15-Jan-2024 10:30:00 (class: datetime)\n","truncated":false}}
%---
%[output:17a076f7]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"serverStruct","value":"    server: [1×1 struct]\n"}}
%---
%[output:2400d8eb]
%   data: {"dataType":"text","outputData":{"text":"Name: example-package\n","truncated":false}}
%---
%[output:39dd9f16]
%   data: {"dataType":"text","outputData":{"text":"Version: 1.0.0\n","truncated":false}}
%---
%[output:4e923df1]
%   data: {"dataType":"text","outputData":{"text":"Description: An example Python package\n","truncated":false}}
%---
%[output:671f3dd4]
%   data: {"dataType":"text","outputData":{"text":"Authors:\n","truncated":false}}
%---
%[output:4929a4d1]
%   data: {"dataType":"text","outputData":{"text":"  - Alice Smith <alice@example.com>\n  - Bob Jones <bob@example.com>\n","truncated":false}}
%---
%[output:82fc69d3]
%   data: {"dataType":"text","outputData":{"text":"Dependencies:\n","truncated":false}}
%---
%[output:8f9de3c4]
%   data: {"dataType":"text","outputData":{"text":"  - numpy>=1.20\n  - pandas>=1.3\n  - matplotlib>=3.4\n","truncated":false}}
%---
%[output:2f4a0607]
%   data: {"dataType":"text","outputData":{"text":"Project URLs:\n","truncated":false}}
%---
%[output:14afaa9b]
%   data: {"dataType":"text","outputData":{"text":"  Homepage: https:\/\/github.com\/example\/package\n","truncated":false}}
%---
%[output:9a08f710]
%   data: {"dataType":"text","outputData":{"text":"  Repository: https:\/\/github.com\/example\/package.git\n","truncated":false}}
%---
%[output:92e0ac02]
%   data: {"dataType":"text","outputData":{"text":"  Documentation: https:\/\/example-package.readthedocs.io\n","truncated":false}}
%---
%[output:5058f720]
%   data: {"dataType":"text","outputData":{"text":"Build System:\n","truncated":false}}
%---
%[output:85b36b21]
%   data: {"dataType":"text","outputData":{"text":"  Backend: setuptools.build_meta\n","truncated":false}}
%---
%[output:9b12b670]
%   data: {"dataType":"text","outputData":{"text":"  Requires: setuptools>=61.0, wheel\n","truncated":false}}
%---

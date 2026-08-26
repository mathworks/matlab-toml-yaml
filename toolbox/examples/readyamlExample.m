%[text] # ReadYAMLExample - Comprehensive guide to reading YAML files
%[text] This example demonstrates readyaml functionality, showing how to work with YAML configuration files, handle different array types, use the SequenceRule option, and work with GitHub Actions-style configurations.
%%
%[text] ## Basic YAML Reading
%[text] Read a simple YAML file and access its contents
%[text] Create a sample YAML file
yamlContent = [
    "app-name: MyApplication"
    "version: 1.2.0"
    "port: 8080"
    "debug: true"];
writelines(yamlContent,"basic_config.yaml");
%[text] Read the YAML file
config = readyaml("basic_config.yaml");
%[text] YAMLData object:
config %[output:9d2914d0]
%%
%[text] Access values using dot notation
config.("app-name") %[output:870f5a7b]
%%
%[text] ## Nested YAML Structures
%[text] YAML supports nested mappings (dictionaries)
yamlNested = [
    "database:"
    "  host: localhost"
    "  port: 5432"
    "  credentials:"
    "    username: admin"
    "    password: secret"];
writelines(yamlNested,"nested_config.yaml");
dbConfig = readyaml("nested_config.yaml");
%[text] Navigate nested structures
dbConfig.database.credentials.username %[output:878829ce]
%%
%[text] ## YAML Arrays - Flow Style
%[text] Flow-style arrays use \[item1, item2, item3\] syntax
yamlFlowArrays = [
    "ports: [8080, 8443, 9000]"
    "hosts: [localhost, api.example.com, db.example.com]"];
writelines(yamlFlowArrays,"flow_arrays.yaml");
flowData = readyaml("flow_arrays.yaml");
%[text] Arrays are converted to MATLAB arrays based on type
flowData.ports %[output:7d48cbf4]
%%
%[text] ## YAML Arrays - Block Style
%[text] Block-style arrays use dash notation
yamlBlockArrays = [
    "ports:"
    "  - 8080"
    "  - 8443"
    "  - 9000"
    "hosts:"
    "  - localhost"
    "  - api.example.com"
    "  - db.example.com"];
writelines(yamlBlockArrays,"block_arrays.yaml");
blockData = readyaml("block_arrays.yaml");
%[text] Block-style arrays work the same as flow-style
blockData.ports %[output:6396fa3d]
%%
%[text] ## Mixed-Type Arrays
%[text] Arrays with mixed types become cell arrays
yamlMixed = [
    "mixed:"
    "  - 42"
    "  - ""text"""
    "  - true"
    "  - 3.14"];
writelines(yamlMixed,"mixed_array.yaml");
mixedData = readyaml("mixed_array.yaml");
%[text] Mixed-type arrays become cell arrays
mixedData.mixed %[output:9e77c6aa]
%%
%[text] ## SequenceRule Option - Auto vs Cell
%[text] Control how arrays are converted
yamlArrayTypes = [
    "numbers: [1, 2, 3]"
    "strings: [apple, banana, cherry]"
    "single: [value]"];
writelines(yamlArrayTypes,"array_types.yaml");
%[text] Default: SequenceRule="auto" - use specialized arrays when possible
autoData = readyaml("array_types.yaml");
%[text] With SequenceRule="auto" (default):
autoData.numbers %[output:948071b5]
%%
%[text] SequenceRule="cell" - always use cell arrays for consistency
cellData = readyaml("array_types.yaml", SequenceRule="cell");
%[text] With SequenceRule="cell":
cellData.numbers %[output:89327b5e]
%%
%[text] Why use SequenceRule="cell"?
%[text] Use SequenceRule='cell' when:
%[text] - You need consistent types regardless of content
%[text] - A file might change from single value to multiple values
%[text] - You want predictable behavior for dynamic configurations\\ \
%%
%[text] ## Sequence of Mappings - GitHub Actions Style
%[text] Arrays where each item is a mapping (dictionary)
yamlSteps = [
    "steps:"
    "  - name: Checkout"
    "    uses: actions/checkout@v4"
    "  - name: Setup MATLAB"
    "    uses: matlab-actions/setup-matlab@v2"
    "  - name: Run tests"
    "    uses: matlab-actions/run-tests@v2"];
writelines(yamlSteps,"workflow_steps.yaml");
workflow = readyaml("workflow_steps.yaml");
%[text] Access array of mappings with indexing
%[text] GitHub Actions workflow steps:
for i = 1:numel(workflow.steps) %[output:group:1cdb82b5]
    fprintf("Step %d: %s\n", i, workflow.steps(i).name); %[output:9efc0758] %[output:83292f4d] %[output:772f2ecb]
    fprintf("  Uses: %s\n", workflow.steps(i).uses); %[output:9717da0e] %[output:4b24b677] %[output:15015521]
end %[output:group:1cdb82b5]
%%
%[text] Access individual step properties
workflow.steps(1).name %[output:1a3af68f]
%%
%[text] Extract all values from an array using arrayfun
%[text] To get all names from the array at once:
allNames = arrayfun(@(x) x.name, workflow.steps) %[output:59183ee0]
%%
%[text] ## Complex GitHub Actions Workflow
%[text] Real-world GitHub Actions YAML with nested structures
yamlGitHubActions = [
    "name: CI"
    "on:"
    "  push:"
    "    branches: [main, develop]"
    "  pull_request:"
    "    branches: [main]"
    ""
    "jobs:"
    "  build:"
    "    runs-on: ubuntu-latest"
    "    steps:"
    "      - name: Checkout"
    "        uses: actions/checkout@v4"
    "      - name: Build"
    "        run: make build"
    "  test:"
    "    runs-on: ubuntu-latest"
    "    steps:"
    "      - name: Checkout"
    "        uses: actions/checkout@v4"
    "      - name: Run tests"
    "        run: make test"];
writelines(yamlGitHubActions,"github_workflow.yaml");
ghActions = readyaml("github_workflow.yaml");
%[text] Navigate complex nested structure
%[text] GitHub Actions workflow:
fprintf("Workflow name: %s\n", ghActions.name); %[output:53a439e4]
disp("Trigger on push branches:") %[output:15be4dcb]
for i = 1:numel(ghActions.on.push.branches) %[output:group:5849a603]
    fprintf("  - %s\n", ghActions.on.push.branches(i)); %[output:3c3c2a08]
end %[output:group:5849a603]
disp("Jobs:") %[output:905779f4]
disp("  Build job runs on: " + ghActions.jobs.build.("runs-on")) %[output:8606f38b]
disp("  Test job runs on: " + ghActions.jobs.test.("runs-on")) %[output:9370f1f1]
%%
%[text] ## Keys with Special Characters
%[text] Use dynamic field access for keys with hyphens, underscores, or dots
yamlSpecialKeys = [
    "pull-request:"
    "  target-branch: main"
    "  auto-merge: true"
    "push_event:"
    "  enabled: false"];
writelines(yamlSpecialKeys,"special_keys.yaml");
special = readyaml("special_keys.yaml");
%[text] Access keys with special characters using quoted syntax
special.("pull-request").("target-branch") %[output:72ed3579]
%%
%[text] ## Exploring Unknown YAML Files
%[text] Use keys, iskey, and show to explore structure
%[text] Top-level keys in GitHub Actions workflow:
keys(ghActions) %[output:8097bbab]
%%
%[text] Check for specific keys
iskey(ghActions, "jobs") %[output:788cfd40]
%%
%[text] ## Use show and describe for formatted display
%[text] Database configuration structure:
show(dbConfig) %[output:5360cd8e]
%%
%[text] Use `describe` for a compact structural overview showing types and sizes:
describe(dbConfig)
%%
%[text] ## Data Types in YAML
%[text] YAML supports various data types
yamlTypes = [
    "string_val: Hello, World!"
    "quoted_string: ""Quoted text"""
    "integer_val: 42"
    "float_val: 3.14159"
    "boolean_true: true"
    "boolean_false: false"
    "yes_val: yes"
    "no_val: no"
    "null_val: null"];
writelines(yamlTypes,"types.yaml");
types = readyaml("types.yaml") %[output:9c05f12e]
%%
%[text] ## Converting to Struct
%[text] Convert YAMLData to standard MATLAB struct when needed
serverYaml = [
    "server:"
    "  host: localhost"
    "  port: 8080"
    "  ssl: true"];
writelines(serverYaml,"server.yaml");
serverConfig = readyaml("server.yaml");
%[text] Convert to struct
serverStruct = struct(serverConfig);
%[text] Converted to struct:
serverStruct %[output:26964a0f]
%%
%[text] ## Best Practices
%[text] Best practices for reading YAML files:
%[text] - Use dot notation for simple keys: config.name
%[text] - Use quoted syntax for special characters: config.("app-name")
%[text] - Use SequenceRule='cell' for dynamic configurations
%[text] - Use keys to explore unknown structures
%[text] - Use iskey to check for optional fields
%[text] - Reading missing keys returns `missing` — enables simplified filtering without `iskey()` guards
%[text] - Use show for formatted display during debugging
%[text] - Remember: arrays are column vectors by default \
%%
%[text] ## Cleanup
%[text] Delete temporary YAML files
delete("basic_config.yaml", "nested_config.yaml", "flow_arrays.yaml", ... %[output:group:702a57a9] %[output:0e15cbfb]
    "block_arrays.yaml", "mixed_array.yaml", "array_types.yaml", ... %[output:0e15cbfb]
    "workflow_steps.yaml", "github_workflow.yaml", "special_keys.yaml", ... %[output:0e15cbfb]
    "types.yaml", "server.yaml"); %[output:group:702a57a9] %[output:0e15cbfb]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:9d2914d0]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"MyApplication\"\n    version: \"1.2.0\"\n    port: 8080\n    debug: true\n"}}
%---
%[output:870f5a7b]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"MyApplication\""}}
%---
%[output:878829ce]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"admin\""}}
%---
%[output:7d48cbf4]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":3,"type":"double","value":[["8080"],["8443"],["9000"]]}}
%---
%[output:6396fa3d]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":3,"type":"double","value":[["8080"],["8443"],["9000"]]}}
%---
%[output:9e77c6aa]
%   data: {"dataType":"tabular","outputData":{"columns":1,"header":"4×1 cell array","name":"ans","rows":4,"type":"cell","value":[["42"],["\"text\""],["1"],["3.1400"]]}}
%---
%[output:948071b5]
%   data: {"dataType":"matrix","outputData":{"columns":1,"name":"ans","rows":3,"type":"double","value":[["1"],["2"],["3"]]}}
%---
%[output:89327b5e]
%   data: {"dataType":"tabular","outputData":{"columns":1,"header":"3×1 cell array","name":"ans","rows":3,"type":"cell","value":[["1"],["2"],["3"]]}}
%---
%[output:9efc0758]
%   data: {"dataType":"text","outputData":{"text":"Step 1: Checkout\n","truncated":false}}
%---
%[output:9717da0e]
%   data: {"dataType":"text","outputData":{"text":"  Uses: actions\/checkout@v4\n","truncated":false}}
%---
%[output:83292f4d]
%   data: {"dataType":"text","outputData":{"text":"Step 2: Setup MATLAB\n","truncated":false}}
%---
%[output:4b24b677]
%   data: {"dataType":"text","outputData":{"text":"  Uses: matlab-actions\/setup-matlab@v2\n","truncated":false}}
%---
%[output:772f2ecb]
%   data: {"dataType":"text","outputData":{"text":"Step 3: Run tests\n","truncated":false}}
%---
%[output:15015521]
%   data: {"dataType":"text","outputData":{"text":"  Uses: matlab-actions\/run-tests@v2\n","truncated":false}}
%---
%[output:1a3af68f]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"Checkout\""}}
%---
%[output:59183ee0]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"allNames","rows":1,"type":"string","value":[["Checkout","Setup MATLAB","Run tests"]]}}
%---
%[output:53a439e4]
%   data: {"dataType":"text","outputData":{"text":"Workflow name: CI\n","truncated":false}}
%---
%[output:15be4dcb]
%   data: {"dataType":"text","outputData":{"text":"Trigger on push branches:\n","truncated":false}}
%---
%[output:3c3c2a08]
%   data: {"dataType":"text","outputData":{"text":"  - main\n  - develop\n","truncated":false}}
%---
%[output:905779f4]
%   data: {"dataType":"text","outputData":{"text":"Jobs:\n","truncated":false}}
%---
%[output:8606f38b]
%   data: {"dataType":"text","outputData":{"text":"  Build job runs on: ubuntu-latest\n","truncated":false}}
%---
%[output:9370f1f1]
%   data: {"dataType":"text","outputData":{"text":"  Test job runs on: ubuntu-latest\n","truncated":false}}
%---
%[output:72ed3579]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"main\""}}
%---
%[output:8097bbab]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["name","on","jobs"]]}}
%---
%[output:788cfd40]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:5360cd8e]
%   data: {"dataType":"text","outputData":{"text":"database:\n  host: localhost\n  port: 5432\n  credentials:\n    username: admin\n    password: secret\n\n","truncated":false}}
%---
%[output:9c05f12e]
%   data: {"dataType":"textualVariable","outputData":{"name":"types","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    string_val: \"Hello, World!\"\n    quoted_string: \"Quoted text\"\n    integer_val: 42\n    float_val: 3.14159\n    boolean_true: true\n    boolean_false: false\n    yes_val: true\n    no_val: false\n    null_val: []\n"}}
%---
%[output:26964a0f]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"serverStruct","value":"    server: [1×1 struct]\n"}}
%---

%[text] # File Analysis with configdata — Struct Arrays Without the Friction
%[text] MATLAB's `dir()` returns a struct array, but working with that struct array is awkward. This example shows how `configdata()` eliminates the friction.
%[text] **ConfigurationData features used:**
%[text] - **Dot access returns arrays** — No need to wrap field access in {} or \[\]
%[text] - **Logical indexing** — Filter arrays by field values in a single expression
%[text] - **Sorting and indexing** — Use numeric array operations directly on field values \
%%
%[text] ## The Classic Struct Array Problem
%[text] `dir()` returns a struct array. When you index into a field across all elements, MATLAB returns a comma-separated list — not an array. You have to wrap it in `{}` or `string({...})` to get something you can actually work with.
d = dir("*.m");
% This returns a comma-separated list, not an array:
%   d.name        % multiple outputs, not indexable
% You have to write this instead:
names = string({d.name}) %[output:0b0466bd]
%%
%[text] Filtering requires the same ceremony. There is no clean way to write `d(d.bytes > 5000)` — you have to extract the field first, build a logical index, and apply it manually.
bytes = [d.bytes];
large = d(bytes > 5000);
string({large.name}) %[output:0b0b7dfc]
%%
%[text] ## The configdata Approach
%[text] Wrap the struct array in `configdata()` and the friction disappears. Dot access on the array returns a proper string array, and logical indexing works exactly like it does on numeric arrays.
files = configdata(dir("*.m"));
files.name %[output:56abfc01]
%%
%[text] Filtering is now a one-liner. The result is a `ConfigurationData` array you can keep working with.
large = files(files.bytes > 5000);
large.name %[output:4d5129ca]
%%
%[text] ## Sorting by a Field
%[text] To find the largest files, sort on the `bytes` field and index into the result. `files.bytes` returns a numeric array, so `sort` works directly.
[~, idx] = sort(files.bytes, "descend");
largest = files(idx(1:3));
largest.name %[output:4ec57efa] %[output:6a26a5d4]
%%
%[text] ## Hierarchical File Structure
%[text] Projects have nested folders. A better `dir()` would return a data structure that mirrors that hierarchy. Here's what that could look like with configdata — folders become nested objects, files are arrays at each level, and you can navigate with dot notation or flatten to analyze across the entire tree.
%[text] **Additional features demonstrated:**
%[text] - **Nested object creation** — Folder structure becomes nested configdata
%[text] - **Mixed structure** — Each folder has data (fileCount) and nested objects (subfolders)
%[text] - **describe() for hierarchy** — Visualize tree structure without printing all values
%[text] - **Recursive traversal** — Flatten hierarchy back to single array
%[text] - **Cross-folder analysis** — Filter/aggregate across entire tree \
%%
%[text] ### A Prototype of Better dir()
%[text] `exampleBuildDirectoryTree()` is a prototype showing what a hierarchical `dir()` could return. It builds a nested configdata tree where each folder is an object with a `.files` array and nested subfolder objects.
tree = exampleBuildDirectoryTree("..", MaxDepth=3, FilePattern="*.m") %[output:34ace230]
%%
%[text] ### Visualize the Hierarchy with describe()
%[text] Before working with the data, use `describe()` to see the tree structure. This shows which folders are nested where, without printing all the values.
describe(tree, Depth=3) %[output:65743e4c]
%%
%[text] ### Navigate the Hierarchy
%[text] Use dot notation to navigate into subfolders. Each level is a configdata object with its own `.files` array and metadata.
tree.examples.fileCount %[output:83a90de2]
%%
examplesFiles = tree.examples.files;
examplesFiles.name %[output:43c1f319]
%%
%[text] ### Access Files at Multiple Levels
%[text] Each folder level has its own `.files` array. Compare top-level files vs nested subfolder files.
tree.files.name %[output:5e590296]
%%
tree.("+matlab").("+io").("+config").files.name %[output:4ac0e086]
%%
%[text] ### Flatten the Hierarchy for Cross-Folder Analysis
%[text] To work with all files across all folders, use `exampleCollectFiles()` to flatten the tree. This returns a single array containing every file from every level, which you can then filter, sort, or aggregate.
allFiles = exampleCollectFiles(tree);
numel(allFiles) %[output:3782b292]
%%
%[text] Find the largest .m files anywhere in the project.
[~, idx] = sort(allFiles.bytes, "descend");
topFiles = allFiles(idx(1:5));
topFiles.name %[output:25aaaf7a]
%%
%[text] ### Filter Across All Levels
%[text] Once flattened, you can apply the same logical indexing from earlier — but now it spans the entire directory tree.
largeFiles = allFiles(allFiles.bytes > 10000);
largeFiles.name %[output:6d7c4839]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:0b0466bd]
%   data: {"dataType":"matrix","outputData":{"columns":15,"header":"1×15 string array","name":"names","rows":1,"type":"string","value":[["ConfigurationDataDemo.m","conversionExample.m","eventLogExample.m","experimentTrackingExample.m","fileAnalysisExample.m","readiniExample.m","readjsonExample.m","readtomlExample.m","readyamlExample.m","tomlPyprojectExample.m","writeiniExample.m","writejsonExample.m","writetomlExample.m","writeyamlExample.m","yamlWorkflowExample.m"]]}}
%---
%[output:0b0b7dfc]
%   data: {"dataType":"matrix","outputData":{"columns":10,"header":"1×10 string array","name":"ans","rows":1,"type":"string","value":[["ConfigurationDataDemo.m","eventLogExample.m","fileAnalysisExample.m","readjsonExample.m","readtomlExample.m","readyamlExample.m","writejsonExample.m","writetomlExample.m","writeyamlExample.m","yamlWorkflowExample.m"]]}}
%---
%[output:56abfc01]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"15×1 string array","name":"ans","rows":15,"type":"string","value":[["ConfigurationDataDemo.m"],["conversionExample.m"],["eventLogExample.m"],["experimentTrackingExample.m"],["fileAnalysisExample.m"],["readiniExample.m"],["readjsonExample.m"],["readtomlExample.m"],["readyamlExample.m"],["tomlPyprojectExample.m"]]}}
%---
%[output:4d5129ca]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"10×1 string array","name":"ans","rows":10,"type":"string","value":[["ConfigurationDataDemo.m"],["eventLogExample.m"],["fileAnalysisExample.m"],["readjsonExample.m"],["readtomlExample.m"],["readyamlExample.m"],["writejsonExample.m"],["writetomlExample.m"],["writeyamlExample.m"],["yamlWorkflowExample.m"]]}}
%---
%[output:4ec57efa]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"3×1 string array","name":"ans","rows":3,"type":"string","value":[["ConfigurationDataDemo.m"],["readjsonExample.m"],["writetomlExample.m"]]}}
%---
%[output:6a26a5d4]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 string array","name":"ans","rows":1,"type":"string","value":[["alpha.m","gamma.m"]]}}
%---
%[output:34ace230]
%   data: {"dataType":"textualVariable","outputData":{"name":"tree","value":"  <a href=\"matlab:helpPopup('matlab.io.config.ConfigurationData')\" style=\"font-weight:bold\">ConfigurationData<\/a> with keys:\n\n    files: [18x1 ConfigurationData]\n    path: \"\/path\/to\/matlab-toml-yaml\/toolbox\"\n    fileCount: 18\n    +matlab: [1x1 ConfigurationData with 3 keys]\n    doc: [1x1 ConfigurationData with 2 keys]\n    examples: [1x1 ConfigurationData with 3 keys]\n\n    <a href=\"matlab:show(tree)\">Show all values<\/a>\n"}}
%---
%[output:65743e4c]
%   data: {"dataType":"text","outputData":{"text":"\n  ConfigurationData with 6 keys\n\n    files:              18x1 array\n        name:               char\n        folder:             char\n        date:               char\n        bytes:              double\n        isdir:              logical\n        datenum:            double\n    path:               \"\/path\/to\/matlab-toml-yaml\/toolbox\" (string)\n    fileCount:          18 (double)\n    +matlab:\n        path:               \"\/path\/to\/matlab-toml-yaml\/toolbox\" (string)\n        fileCount:          0 (double)\n        +io:\n            path:               \"\/path\/to\/matlab-toml-yaml\/toolbox\" (string)\n            fileCount:          0 (double)\n            +config:            (3 keys)\n    doc:\n        path:               \"\/path\/to\/matlab-toml-yaml\/toolbox\" (string)\n        fileCount:          0 (double)\n    examples:\n        files:              15x1 array\n            name:               char\n            folder:             char\n            date:               char\n            bytes:              double\n            isdir:              logical\n            datenum:            double\n        path:               \"\/path\/to\/matlab-toml-yaml\/toolbox\" (string)\n        fileCount:          15 (double)\n\n","truncated":false}}
%---
%[output:83a90de2]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"15"}}
%---
%[output:43c1f319]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"15×1 string array","name":"ans","rows":15,"type":"string","value":[["ConfigurationDataDemo.m"],["conversionExample.m"],["eventLogExample.m"],["experimentTrackingExample.m"],["fileAnalysisExample.m"],["readiniExample.m"],["readjsonExample.m"],["readtomlExample.m"],["readyamlExample.m"],["tomlPyprojectExample.m"]]}}
%---
%[output:5e590296]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"18×1 string array","name":"ans","rows":18,"type":"string","value":[["GettingStarted.m"],["configdata.m"],["exampleBuildDirectoryTree.m"],["exampleCollectFiles.m"],["inidata.m"],["jsondata.m"],["merge.m"],["readini.m"],["readjson.m"],["readtoml.m"]]}}
%---
%[output:4ac0e086]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"5×1 string array","name":"ans","rows":5,"type":"string","value":[["ConfigurationData.m"],["INIData.m"],["JSONData.m"],["TOMLData.m"],["YAMLData.m"]]}}
%---
%[output:3782b292]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"38"}}
%---
%[output:25aaaf7a]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"5×1 string array","name":"ans","rows":5,"type":"string","value":[["ConfigurationData.m"],["readtoml.m"],["writetoml.m"],["GettingStarted.m"],["ConfigurationDataDemo.m"]]}}
%---
%[output:6d7c4839]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"14×1 string array","name":"ans","rows":14,"type":"string","value":[["GettingStarted.m"],["readjson.m"],["readtoml.m"],["readyaml.m"],["writejson.m"],["writetoml.m"],["writeyaml.m"],["ConfigurationData.m"],["ConfigurationDataDemo.m"],["readjsonExample.m"]]}}
%---

%[text] # Working with TOML Arrays: Package Author Management
%[text] Python `pyproject.toml` files are quickly becoming one of the most popular uses of TOML. This example shows how to read, query, modify, and write such a file.
type pyproject.toml %[output:96068141]
%%
%[text] ## Read the Package File
%[text] Read `pyproject.toml`.
pkg = readtoml("pyproject.toml") %[output:32488b5f]
%%
%[text] ## We are interested in the authors
%[text] Authors are stored as an array:
pkg.project.authors %[output:4f240179]
%%
%[text] ## Collect All Author Names at Once
%[text] Dot notation on a TOMLData array gathers the named field from every element. Unlike struct, there's no need to manually pack a comma-separated list into an array.
pkg.project.authors.name %[output:42deb65a]
%%
%[text] ## Find an Author by Name
%[text] Logical indexing works on TOMLData arrays just like MATLAB arrays.
isBob = pkg.project.authors.name == "Bob Martinez";
pkg.project.authors(isBob).email %[output:9024a996]
%%
%[text] ## Update a Nested Field with Chained Assignment
%[text] A single chained expression handles array indexing and nested field access together.
pkg.project.authors(isBob).email = "bob.martinez@newuniversity.edu";
pkg.project.authors.email %[output:73badfb6]
%%
%[text] ## Add a New Author
%[text] Growing an array through a chained path (e.g., `pkg.project.authors(end+1) = ...`) is not supported. Instead, extract the array, append to it, then reassign.
authors = pkg.project.authors;
newAuthor = tomldata();
newAuthor.name = "Diana Torres";
newAuthor.email = "dtorres@lab.org";
authors(end+1) = newAuthor;
pkg.project.authors = authors;
pkg.project.authors.name %[output:5bbb5f19]
%%
%[text] ## Write Back to File
%[text] Write the updated package file. The writer automatically uses `[[project.authors]]` array-of-tables format for the authors array.
writetoml(pkg, "pyproject_updated.toml");
type("pyproject_updated.toml") %[output:336b6a4c]
%%
%[text] ## Cleanup
delete("pyproject_updated.toml")
%[text]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:96068141]
%   data: {"dataType":"text","outputData":{"text":"\n[project]\nname = \"matlab-py-bridge\"\nversion = \"0.3.0\"\ndescription = \"Utilities for calling MATLAB from Python\"\nrequires-python = \">=3.9\"\nlicense = {text = \"MIT\"}\n\n[[project.authors]]\nname = \"Alice Chen\"\nemail = \"achen@university.edu\"\n\n[[project.authors]]\nname = \"Bob Martinez\"\nemail = \"bmartinez@company.com\"\n\n[[project.authors]]\nname = \"Carol Singh\"\nemail = \"csingh@university.edu\"\n\n[build-system]\nrequires = [\"setuptools>=61.0\", \"wheel\"]\nbuild-backend = \"setuptools.build_meta\"\n","truncated":false}}
%---
%[output:32488b5f]
%   data: {"dataType":"textualVariable","outputData":{"name":"pkg","value":"  <a href=\"matlab:helpPopup('matlab.io.config.TOMLData')\" style=\"font-weight:bold\">TOMLData<\/a> with keys:\n\n    project: [1x1 TOMLData with 6 keys]\n    build-system: [1x1 TOMLData with 2 keys]\n\n    <a href=\"matlab:show(pkg)\">Show all values<\/a>\n"}}
%---
%[output:4f240179]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"  1x3 <a href=\"matlab:helpPopup matlab.io.config.TOMLData\">TOMLData<\/a> array with keys:\n\n    name\n    email\n\n    <a href=\"matlab:show(ans)\">Show all values<\/a>\n"}}
%---
%[output:42deb65a]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["Alice Chen","Bob Martinez","Carol Singh"]]}}
%---
%[output:9024a996]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"bmartinez@company.com\""}}
%---
%[output:73badfb6]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["achen@university.edu","bob.martinez@newuniversity.edu","csingh@university.edu"]]}}
%---
%[output:5bbb5f19]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["Alice Chen","Bob Martinez","Carol Singh","Diana Torres"]]}}
%---
%[output:336b6a4c]
%   data: {"dataType":"text","outputData":{"text":"\n[project]\nname = \"matlab-py-bridge\"\nversion = \"0.3.0\"\ndescription = \"Utilities for calling MATLAB from Python\"\nrequires-python = \">=3.9\"\nlicense = {text = \"MIT\"}\n\n[[project.authors]]\nname = \"Alice Chen\"\nemail = \"achen@university.edu\"\n\n[[project.authors]]\nname = \"Bob Martinez\"\nemail = \"bob.martinez@newuniversity.edu\"\n\n[[project.authors]]\nname = \"Carol Singh\"\nemail = \"csingh@university.edu\"\n\n[[project.authors]]\nname = \"Diana Torres\"\nemail = \"dtorres@lab.org\"\n\n[build-system]\nrequires = [\"setuptools>=61.0\", \"wheel\"]\nbuild-backend = \"setuptools.build_meta\"\n","truncated":false}}
%---

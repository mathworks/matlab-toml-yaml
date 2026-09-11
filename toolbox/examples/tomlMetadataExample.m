%[text] # TOML Metadata Example - Inspect and control TOML formatting
%[text] This example demonstrates how to use format metadata to inspect, preserve, and control the style of TOML output using getformat, setformat, and resetformat.
%%
%[text] ## Read TOML with Special Formatting
%[text] Write a sample TOML string with hex integers, scientific floats, literal strings, comments, and an inline table, then read it.
tomlContent = [
    "# Server config"
    "port = 8080"
    "color = 0xFF"
    "threshold = 1.5e-3"
    "path = 'C:\tools\bin'"
    "point = {x = 1, y = 2}"];
writelines(tomlContent, "metadata_demo.toml");
data = readtoml("metadata_demo.toml");
data
%%
%[text] ## Inspect Metadata with getformat
%[text] The summary table shows all top-level keys and their styles:
getformat(data)
%%
%[text] Inspect the hex integer:
meta = getformat(data, "color");
meta.IntegerFormat
%%
%[text] Inspect the scientific float:
meta = getformat(data, "threshold");
meta.FloatFormat
%%
%[text] Inspect the literal string:
meta = getformat(data, "path");
meta.ScalarStyle
%%
%[text] Inspect the comment:
meta = getformat(data, "port");
meta.Comments
%%
%[text] ## Round-Trip Preserves Formatting
%[text] Writing the data back to a file preserves the original formatting automatically.
writetoml(data, "metadata_roundtrip.toml");
type("metadata_roundtrip.toml")
%%
%[text] Compare with a fresh struct written without metadata (decimal, default float, basic string):
s = struct(data);
freshData = tomldata(s);
writetoml(freshData, "metadata_fresh.toml");
type("metadata_fresh.toml")
%%
%[text] ## Set Metadata Programmatically
%[text] Create a TOMLData from a struct and set formatting on specific keys.
config = tomldata();
config.color = 255;
config.threshold = 0.0015;
config.path = "C:\tools\bin";
config.port = 8080;
%[text] Hex integer:
config = setformat(config, "color", IntegerFormat="hex");
%[text] Scientific notation:
config = setformat(config, "threshold", FloatFormat="scientific");
%[text] Literal (single-quoted) string:
config = setformat(config, "path", ScalarStyle="single-quoted");
%[text] Add a comment:
config = setformat(config, "port", Comments="# HTTP server port");
writetoml(config, "metadata_set.toml");
type("metadata_set.toml")
%%
%[text] ## Inline Tables and Dotted Keys
%[text] Read a TOML file containing an inline table:
tomlInline = "point = {x = 1, y = 2}";
writelines(tomlInline, "inline_demo.toml");
inlineData = readtoml("inline_demo.toml");
getformat(inlineData, "point").TableFormat
%%
%[text] Programmatically create an inline table:
config = tomldata();
config.origin.x = 0;
config.origin.y = 0;
config = setformat(config, "origin", TableFormat="inline");
writetoml(config, "inline_set.toml");
type("inline_set.toml")
%%
%[text] ## Reset Metadata
%[text] Reset a single key — integer reverts to decimal:
data = resetformat(data, "color");
getformat(data, "color").IntegerFormat
%%
%[text] Reset all metadata:
data = resetformat(data);
writetoml(data, "metadata_reset.toml");
type("metadata_reset.toml")
%%
%[text] ## Real-World Use Case: pyproject.toml
%[text] Read a pyproject.toml that uses comments and an inline license table, modify a dependency, and write back with formatting preserved.
pkg = readtoml("pyproject.toml");
pkg.project.version
%%
%[text] Add a new dependency:
pkg.project.dependencies = ["numpy>=1.20.0"; "pandas>=1.3.0"];
writetoml(pkg, "pyproject_updated.toml");
type("pyproject_updated.toml")
%%
%[text] ## Cleanup
delete("metadata_demo.toml", "metadata_roundtrip.toml", "metadata_fresh.toml", ...
    "metadata_set.toml", "inline_demo.toml", "inline_set.toml", ...
    "metadata_reset.toml", "pyproject_updated.toml");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

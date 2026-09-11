%[text] # YAML Metadata Example - Inspect and control YAML formatting
%[text] This example demonstrates how to use format metadata to inspect, preserve, and control the style of YAML output using getformat, setformat, and resetformat.
%%
%[text] ## Read YAML with Mixed Styles
%[text] Write a sample YAML string with flow sequences, flow maps, and quoted strings to a temp file, then read it.
yamlContent = [
    "name: my-application"
    "version: '1.0.0'"
    "ports: [8080, 8443]"
    "options: {timeout: 30, retries: 3}"
    "database:"
    "  host: localhost"
    "  port: 5432"];
writelines(yamlContent, "metadata_demo.yaml");
data = readyaml("metadata_demo.yaml");
data
%%
%[text] ## Inspect Metadata with getformat
%[text] The summary table shows all top-level keys and their styles:
getformat(data)
%%
%[text] Inspect a single key to see its full metadata:
meta = getformat(data, "ports");
meta.ContainerStyle
%%
meta.IsArray
%%
%[text] Inspect the flow map:
meta = getformat(data, "options");
meta.ContainerStyle
%%
%[text] Inspect the quoted string:
meta = getformat(data, "version");
meta.ScalarStyle
%%
%[text] ## Round-Trip Preserves Styles
%[text] Writing the data back to a file preserves the original styles automatically.
writeyaml(data, "metadata_roundtrip.yaml");
type("metadata_roundtrip.yaml")
%%
%[text] Compare with a fresh struct written without metadata (everything becomes block style):
s = struct(data);
freshData = yamldata(s);
writeyaml(freshData, "metadata_fresh.yaml");
type("metadata_fresh.yaml")
%%
%[text] ## Set Metadata Programmatically
%[text] Create a YAMLData from a struct and set formatting on specific keys.
config = yamldata();
config.name = "MyApp";
config.ports = [8080; 8443; 9000];
config.hosts = ["localhost"; "api.example.com"];
%[text] Mark ports as a flow-style array:
config = setformat(config, "ports", ContainerStyle="flow", IsArray=true);
%[text] Mark name as single-quoted:
config = setformat(config, "name", ScalarStyle="single-quoted");
writeyaml(config, "metadata_set.yaml");
type("metadata_set.yaml")
%%
%[text] ## Nested Key Paths
%[text] Dot-path syntax navigates into nested objects.
config = yamldata();
config.server.host = "localhost";
config.server.ports = [8080; 8443];
%[text] Set metadata on the nested ports key:
config = setformat(config, "server.ports", ContainerStyle="flow", IsArray=true);
%[text] Query it back:
meta = getformat(config, "server.ports");
meta.ContainerStyle
%%
writeyaml(config, "metadata_nested.yaml");
type("metadata_nested.yaml")
%%
%[text] ## Reset Metadata
%[text] Reset a single key to revert it to default formatting:
config = resetformat(config, "server.ports");
getformat(config, "server.ports").ContainerStyle
%%
%[text] Reset all metadata on the object:
data = resetformat(data);
writeyaml(data, "metadata_reset.yaml");
type("metadata_reset.yaml")
%%
%[text] ## Cleanup
delete("metadata_demo.yaml", "metadata_roundtrip.yaml", "metadata_fresh.yaml", ...
    "metadata_set.yaml", "metadata_nested.yaml", "metadata_reset.yaml");

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

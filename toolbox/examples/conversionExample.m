%% conversionExample - Converting between struct, dictionary, and data objects
% This example demonstrates how to convert data between MATLAB's native
% types (struct, dictionary, containers.Map) and YAMLData/TOMLData objects.

%% Creating a Data Object from Struct
% Convert a MATLAB struct to YAMLData or TOMLData

% Create a nested struct
s = struct();
s.name = "MyApplication";
s.version = "1.0.0";
s.database.host = "localhost";
s.database.port = 5432;
s.database.credentials.username = "admin";
s.database.credentials.password = "secret";

% Convert to YAMLData
yamlConfig = yamldata(s);
disp("YAMLData created from struct:")
disp(yamlConfig)

% Convert to TOMLData
tomlConfig = tomldata(s);
disp("TOMLData created from struct:")
disp(tomlConfig)

% Nested structs become nested data objects of the same class
disp("Nested data preserves class type:")
disp("  database type: " + class(yamlConfig.database))
disp("  credentials type: " + class(yamlConfig.database.credentials))

%% Creating a Data Object from Dictionary
% Convert a MATLAB dictionary to a YAMLData or TOMLData object

% Create a dictionary (requires R2022b+)
d = configureDictionary("string", "cell");
d("title") = {"My Project"};
d("version") = {"2.0.0"};
d("ports") = {[8080, 8443, 9000]};

% Convert to TOMLData
config = tomldata(d);
disp("TOMLData created from dictionary:")
disp(config)

%% Creating a Data Object Programmatically
% Build nested configuration from scratch

fresh = yamldata();
fresh.server.host = "localhost";
fresh.server.port = 8080;
fresh.debug = true;
disp("YAMLData created programmatically:")
disp(fresh)

%% Converting a Data Object to Dictionary
% Use the dictionary() method to convert back to a MATLAB dictionary

% Read a configuration file
config = yamldata();
config.project.name = "demo";
config.project.version = "1.0";
config.settings.debug = true;
config.settings.timeout = 30;

% Convert to dictionary
d = dictionary(config);
disp("Converted to dictionary:")
disp(d)

% Access dictionary values
disp("Project name: " + d{"project"}{"name"})

%% Converting a Data Object to Struct
% Use the struct() method to convert to a standard MATLAB struct

configStruct = struct(config);
disp("Converted to struct:")
disp(configStruct)
disp(configStruct.project)

%% Writing Struct Directly
% You can pass structs directly to write functions

s = struct();
s.app.name = "DirectWrite";
s.app.enabled = true;
s.server.port = 3000;

% Write struct directly to YAML
tempYaml = tempname + ".yaml";
writeyaml(s, tempYaml);
disp("Struct written directly to YAML:")
type(tempYaml)
delete(tempYaml)

% Write struct directly to TOML
tempToml = tempname + ".toml";
writetoml(s, tempToml);
disp("Struct written directly to TOML:")
type(tempToml)
delete(tempToml)

%% Writing Dictionary Directly
% You can also pass dictionaries directly to write functions

d = configureDictionary("string", "cell");
d("title") = {"Dictionary Example"};
d("count") = {42};

tempYaml = tempname + ".yaml";
writeyaml(d, tempYaml);
disp("Dictionary written directly to YAML:")
type(tempYaml)
delete(tempYaml)

%% Round-Trip Verification
% Verify data integrity through conversions

% Original struct
original = struct();
original.name = "RoundTrip";
original.values = [1, 2, 3, 4, 5];
original.nested.key = "value";

% Convert to YAMLData
config = yamldata(original);

% Convert back to struct
roundTripped = struct(config);

% Compare
disp("Round-trip verification:")
disp("  Original name: " + original.name)
disp("  Round-tripped name: " + roundTripped.name)
disp("  Values match: " + mat2str(isequal(original.values, roundTripped.values)))
disp("  Nested key: " + roundTripped.nested.key)

%% Struct Array to Data Object Array
% Convert arrays of structs to arrays of data objects

clear steps
steps(1).name = "Checkout";
steps(1).uses = "actions/checkout@v4";
steps(2).name = "Build";
steps(2).run = "make build";
steps(3).name = "Test";
steps(3).run = "make test";

% Convert each element
yamlSteps = arrayfun(@(s) yamldata(s), steps);

disp("Array of YAMLData objects:")
for i = 1:numel(yamlSteps)
    disp("  Step " + i + ": " + yamlSteps(i).name)
end

%% Best Practices Summary
%
% 1. Use wrapper functions for conversion:
%    config = yamldata(myStruct)
%    config = tomldata(myDict)
%
% 2. Use methods for export:
%    s = struct(config)
%    d = dictionary(config)
%
% 3. Write native types directly:
%    writeyaml(myStruct, "file.yaml")
%    writetoml(myDict, "file.toml")
%
% 4. Nested data is converted recursively:
%    Nested structs become nested data objects of the same class
%    Nested dicts become nested data objects of the same class

# YAMLData

**YAML configuration data container**

YAMLData represents structured configuration data from YAML files with dot notation access and support for special characters in field names.

## Creation

### Syntax

```matlab
data = yamldata()
data = yamldata(s)
data = yamldata(d)
data = yamldata(m)
data = readyaml(filename)
```

### Description

`data = yamldata()` creates an empty YAMLData object.

`data = yamldata(s)` converts struct `s` to YAMLData. Nested structs become nested YAMLData objects.

`data = yamldata(d)` converts dictionary `d` to YAMLData.

`data = yamldata(m)` converts containers.Map `m` to YAMLData.

`data = readyaml(filename)` creates a YAMLData object by reading from a YAML file. See [readyaml](readyaml.md).

## Object Functions

### Data Access
- [`keys`](#keys) — Get list of keys
- [`isfield`](#isfield) — Check if field exists
- [`fieldnames`](#fieldnames) — Get field names (alias for keys)
- [`iskey`](#iskey) — Check if key exists (alias for isfield)
- [`properties`](#properties) — Get list of dynamic properties

### Data Conversion
- [`struct`](#struct) — Convert to standard MATLAB&reg; struct
- [`dictionary`](#dictionary) — Convert to MATLAB dictionary
- [`map`](#map) — Convert to containers.Map

### Data Modification
- [`rmfield`](#rmfield) — Remove a field
- [`remove`](#remove) — Remove a key (alias for rmfield)
- [`copy`](#copy) — Create deep copy of object

### Display
- [`show`](#show) — Display contents as YAML text

## Usage

### Dot Notation Access

Access fields using dot notation:

```matlab
data = yamldata();
data.app.name = "MyApp";
data.app.version = "1.0.0";
value = data.app.name;  % "MyApp"
```

### Special Character Keys

Use dynamic field names for keys with special characters:

```matlab
data = yamldata();
data.("app-name") = "MyApp";
data.("build-system").requires = ["setuptools"; "wheel"];
appName = data.("app-name");  % "MyApp"
```

### Array Indexing

YAMLData objects can contain arrays:

```matlab
data = yamldata();
data.ports = [8080; 8443; 9000];
firstPort = data.ports(1);  % 8080
```

## Examples

### Create and Populate YAMLData

Build configuration data programmatically:

```matlab
% Create empty YAMLData
config = yamldata();

% Add fields using dot notation
config.database.host = "localhost";
config.database.port = 5432;
config.cache.enabled = true;
config.cache.ttl = 3600;

% Display as YAML
show(config);
```

### Read from YAML File

Load configuration from file:

```matlab
% Read YAML file
config = readyaml("config.yaml");

% Access nested data
host = config.database.host;
port = config.database.port;

% Check if field exists
if isfield(config, "cache")
    ttl = config.cache.ttl;
end
```

### Convert to Struct

Work with standard MATLAB structs:

```matlab
% Read YAML
data = readyaml("config.yaml");

% Convert to struct
s = struct(data);

% Now use as regular struct
host = s.database.host;
```

### Value Class Behavior

YAMLData uses value semantics - assignment creates independent copies:

```matlab
% Create original
original = readyaml("config.yaml");

% Assignment creates independent copy
copied = original;
copied.database.port = 5433;  % Does NOT modify original

% copy() method also works
another = copy(original);
another.database.port = 5434;  % Does NOT modify original
```

### Create from Struct

Convert existing structs to YAMLData:

```matlab
% Create struct
s = struct('name', 'MyApp', 'database', struct('host', 'localhost', 'port', 5432));

% Convert to YAMLData
config = yamldata(s);
config.name           % "MyApp"
config.database.host  % "localhost"

% Write struct directly (auto-converted)
writeyaml(s, 'config.yaml');
```

### Modify and Save

Read, modify, and write back:

```matlab
% Read configuration
config = readyaml("config.yaml");

% Modify values
config.database.port = 5433;
config.cache.ttl = 7200;

% Write back to file
writeyaml(config, "config_updated.yaml");
```

For comprehensive examples, see [readyamlExample.m](../../examples/readyamlExample.m).

## Tips

- YAMLData is a value class. Assignment creates independent copies automatically.
- Create from struct: `config = yamldata(myStruct)`.
- Use `show` to view the YAML representation without writing to a file.
- Access fields with special characters using dynamic field names: `data.("field-name")`.
- Convert to struct with `struct(data)`, to dictionary with `dictionary(data)`.
- YAMLData preserves field order for consistent file output.

## More About

### Value Class Semantics

YAMLData is a value class:
- Assignment creates independent copies
- Modifications to one copy do not affect others
- The `copy()` method is provided for compatibility but is equivalent to assignment

```matlab
data1 = yamldata();
data2 = data1;          % Independent copy
data3 = copy(data1);    % Also independent copy
```

### Dot Notation Implementation

YAMLData uses `matlab.mixin.indexing.RedefinesDot` to enable dot notation access to dynamic fields.

### Key Aliasing

Keys with special characters (hyphens, spaces, dots) are automatically aliased for valid MATLAB name access:

```matlab
data.("app-name") = "MyApp";
% Creates alias: appname -> app-name
% Both data.("app-name") and data.appname work
```

### Field Order Preservation

YAMLData maintains insertion order internally, ensuring consistent YAML output when writing files.

## Limitations

- Very deeply nested structures may impact performance due to recursive object creation.
- Field names are case-sensitive, matching YAML behavior.

## See Also

[readyaml](readyaml.md), [writeyaml](writeyaml.md), [TOMLData](TOMLData.md), [ConfigurationData](ConfigurationData.md), [containers.Map](https://www.mathworks.com/help/matlab/ref/containers.map.html)

## Version History

- Introduced in 2025a

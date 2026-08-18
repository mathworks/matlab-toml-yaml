# TOMLData

**TOML configuration data container**

TOMLData represents structured configuration data from TOML files with dot notation access and support for special characters in field names.

## Creation

### Syntax

```matlab
data = tomldata()
data = tomldata(s)
data = tomldata(d)
data = tomldata(m)
data = readtoml(filename)
```

### Description

`data = tomldata()` creates an empty TOMLData object.

`data = tomldata(s)` converts struct `s` to TOMLData. Nested structs become nested TOMLData objects.

`data = tomldata(d)` converts dictionary `d` to TOMLData.

`data = tomldata(m)` converts containers.Map `m` to TOMLData.

`data = readtoml(filename)` creates a TOMLData object by reading from a TOML file. See [readtoml](readtoml.md).

## Object Functions

### Data Access
- [`keys`](#keys) — Get list of keys
- [`iskey`](#iskey) — Check if key exists
- [`fieldnames`](#fieldnames) — Get field names (alias for keys)
- [`isfield`](#isfield) — Check if field exists (alias for iskey)
- [`properties`](#properties) — Get list of dynamic properties

### Data Conversion
- [`struct`](#struct) — Convert to standard MATLAB struct
- [`dictionary`](#dictionary) — Convert to MATLAB dictionary
- [`map`](#map) — Convert to containers.Map

### Data Modification
- [`rmfield`](#rmfield) — Remove a field
- [`remove`](#remove) — Remove a key (alias for rmfield)
- [`copy`](#copy) — Create deep copy of object

### Display
- [`show`](#show) — Display contents as TOML text

## Usage

### Dot Notation Access

Access fields using dot notation:

```matlab
data = tomldata();
data.project.name = "my-package";
data.project.version = "1.0.0";
name = data.project.name;  % "my-package"
```

### Special Character Keys

Use dynamic field names for keys with special characters:

```matlab
data = tomldata();
data.("build-system").requires = ["setuptools"; "wheel"];
data.("build-system").("build-backend") = "setuptools.build_meta";
backend = data.("build-system").("build-backend");
```

### Datetime Values

TOMLData handles TOML datetime types:

```matlab
data = tomldata();
data.created = datetime("now");
data.updated = datetime("2025-01-08");
```

## Examples

### Create Python Project Configuration

Build a pyproject.toml programmatically:

```matlab
% Create TOMLData
project = tomldata();

% Build system configuration
project.("build-system").requires = ["setuptools>=61.0"; "wheel"];
project.("build-system").("build-backend") = "setuptools.build_meta";

% Project metadata
project.project.name = "my-package";
project.project.version = "1.0.0";
project.project.authors = ["Alice <alice@example.com>"; "Bob <bob@example.com>"];

% Dependencies
project.project.dependencies = ["numpy>=1.20.0"; "pandas>=1.3.0"];

% Write to file
writetoml(project, "pyproject.toml");
```

### Read and Modify TOML File

Load, modify, and save configuration:

```matlab
% Read existing TOML
config = readtoml("pyproject.toml");

% Modify values
config.project.version = "1.1.0";
config.project.dependencies = [config.project.dependencies; "scipy>=1.7.0"];

% Write updated configuration
writetoml(config, "pyproject_updated.toml");
```

### Access Nested Tables

Navigate complex TOML structures:

```matlab
% Read TOML with nested tables
config = readtoml("config.toml");

% Access nested data
host = config.database.connection.host;
port = config.database.connection.port;
poolSize = config.database.pool.size;

% Check for optional sections
if isfield(config, "cache")
    ttl = config.cache.ttl;
end
```

### Display as TOML

Preview TOML output:

```matlab
% Create configuration
config = tomldata();
config.server.host = "localhost";
config.server.port = 8080;
config.debug = true;

% Display as TOML
show(config);
% [server]
% host = "localhost"
% port = 8080
%
% debug = true
```

### Value Class Behavior

TOMLData uses value semantics - assignment creates independent copies:

```matlab
% Read original
original = readtoml("config.toml");

% Assignment creates independent copy
copied = original;
copied.server.port = 8081;  % Does NOT modify original

% copy() method also works
another = copy(original);
another.server.port = 8082;  % Does NOT modify original
```

### Create from Struct

Convert existing structs to TOMLData:

```matlab
% Create struct
s = struct('project', struct('name', 'my-package', 'version', '1.0.0'));

% Convert to TOMLData
config = tomldata(s);
config.project.name     % "my-package"
config.project.version  % "1.0.0"

% Write struct directly (auto-converted)
writetoml(s, 'pyproject.toml');
```

For comprehensive examples, see [readtomlExample.m](../../examples/readtomlExample.m).

## Tips

- TOMLData is a value class. Assignment creates independent copies automatically.
- Create from struct: `config = tomldata(myStruct)`.
- Use `show` to preview TOML output without writing to a file.
- TOML commonly uses hyphens in keys; access them with dynamic field names: `data.("field-name")`.
- Convert to struct with `struct(data)`, to dictionary with `dictionary(data)`.
- TOMLData preserves field insertion order for consistent file output.

## More About

### Value Class Semantics

TOMLData is a value class:
- Assignment creates independent copies
- Modifications to one copy do not affect others
- The `copy()` method is provided for compatibility but is equivalent to assignment

```matlab
data1 = tomldata();
data2 = data1;          % Independent copy
data3 = copy(data1);    % Also independent copy
```

### TOML-Specific Features

TOMLData is optimized for TOML format:
- Preserves key order for reproducible output
- Handles TOML-specific types (datetime, inline tables, arrays of tables)
- Supports both bare keys and quoted keys

### Key Aliasing for Special Characters

TOML frequently uses hyphens and dots in keys. TOMLData handles these with key aliasing:

```matlab
data.("build-system") = "value";
% Creates alias: buildsystem -> build-system
```

### Common TOML Patterns

**Python projects (pyproject.toml):**
```matlab
config.("build-system").requires = ["setuptools"; "wheel"];
config.project.name = "package-name";
config.project.dependencies = ["numpy"; "pandas"];
```

**Configuration files:**
```matlab
config.database.host = "localhost";
config.database.credentials.username = "admin";
config.logging.level = "INFO";
```

## Limitations

- Very deeply nested structures may impact performance due to recursive object creation.
- Field names are case-sensitive, matching TOML behavior.

## See Also

[readtoml](readtoml.md), [writetoml](writetoml.md), [YAMLData](YAMLData.md)

## Version History

- Introduced in 2025a

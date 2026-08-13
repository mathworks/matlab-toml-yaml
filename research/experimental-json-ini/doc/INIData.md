# IniData

**INI configuration data container**

IniData represents structured configuration data from INI files with dot notation access and support for special characters in field names.

## Creation

### Syntax

```matlab
data = inidata()
data = inidata(s)
data = inidata(d)
data = inidata(m)
data = readini(filename)
```

### Description

`data = inidata()` creates an empty INIData object.

`data = inidata(s)` converts struct `s` to INIData. Nested structs become sections.

`data = inidata(d)` converts dictionary `d` to INIData.

`data = inidata(m)` converts containers.Map `m` to INIData.

`data = readini(filename)` creates an INIData object by reading from an INI file. See [readini](readini.md).

## Object Functions

### Data Access
- [`keys`](#keys) — Get list of field names
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
- [`show`](#show) — Display contents as INI text

## Usage

### Dot Notation Access

Access fields using dot notation:

```matlab
data = inidata();
data.server.host = 'localhost';
data.server.port = 8080;
host = data.server.host;  % 'localhost'
```

### Special Character Keys

Use dynamic field names for keys with special characters:

```matlab
data = inidata();
data.("database-pool").("max-size") = 20;
data.("database-pool").("min-size") = 5;
maxSize = data.("database-pool").("max-size");
```

## Examples

### Create Application Configuration

Build an application config programmatically:

```matlab
% Create INIData
config = inidata();

% Server section
config.server.host = 'localhost';
config.server.port = 8080;
config.server.ssl = 'false';

% Database section
config.database.host = 'db.example.com';
config.database.port = 5432;
config.database.name = 'myapp';

% Write to file
writeini(config, 'app.ini');
```

### Read and Modify INI File

Load, modify, and save configuration:

```matlab
% Read existing INI
config = readini('app.ini');

% Modify values
config.server.port = 9000;
config.database.name = 'myapp_prod';

% Write updated configuration
writeini(config, 'app_updated.ini');
```

### Access Nested Sections

Navigate configuration sections:

```matlab
% Read INI with sections
config = readini('config.ini');

% Access section values
host = config.database.host;
port = config.database.port;

% Check for optional sections
if isfield(config, 'cache')
    ttl = config.cache.ttl;
end
```

### Display as INI

Preview INI output:

```matlab
% Create configuration
config = inidata();
config.app.name = 'MyApp';
config.app.version = '1.0.0';
config.server.host = 'localhost';
config.server.port = 8080;

% Display as INI
show(config);
% [app]
% name=MyApp
% version=1.0.0
%
% [server]
% host=localhost
% port=8080
```

### Value Class Behavior

INIData uses value semantics - assignment creates independent copies:

```matlab
% Read original
original = readini('config.ini');

% Assignment creates independent copy
copied = original;
copied.server.port = 9000;  % Does NOT modify original

% copy() method also works
another = copy(original);
another.server.port = 9001;  % Does NOT modify original
```

### Create from Struct

Convert existing structs to INIData:

```matlab
% Create struct
s = struct('database', struct('host', 'localhost', 'port', 5432));

% Convert to INIData
config = inidata(s);
config.database.host  % 'localhost'
config.database.port  % 5432

% Write struct directly (auto-converted)
writeini(s, 'config.ini');
```

## Tips

- INIData is a value class. Assignment creates independent copies automatically.
- Create from struct: `config = inidata(myStruct)`.
- Use `show` to preview INI output without writing to a file.
- INI keys with special characters are accessed via dynamic field names: `data.("field-name")`.
- Convert to struct with `struct(data)`, to dictionary with `dictionary(data)`.
- INIData preserves field insertion order for consistent file output.

## More About

### Value Class Semantics

INIData is a value class:
- Assignment creates independent copies
- Modifications to one copy do not affect others
- The `copy()` method is provided for compatibility but is equivalent to assignment

```matlab
data1 = inidata();
data2 = data1;          % Independent copy
data3 = copy(data1);    % Also independent copy
```

### Windows INI Dialect

IniData implements the Windows INI format with:
- Sections: `[SectionName]`
- Key-value pairs: `key=value` or `key:value`
- Comments: Lines starting with `;` or `#`
- One level of nesting (sections with keys)
- All values are strings (no type conversion on read)

### Common INI Patterns

**Application settings:**
```matlab
config.application.name = 'MyApp';
config.application.version = '1.0.0';
config.application.debug = 'false';
```

**Server/database configuration:**
```matlab
config.server.host = '0.0.0.0';
config.server.port = 8080;
config.database.url = 'postgresql://localhost/mydb';
config.database.pool_size = 20;
```

## Limitations

- No support for deep nesting (only one section level).
- No type preservation (all values read as strings; write as strings unless MATLAB type detected).
- No support for multiline values.
- No support for escaped characters in keys/values.

## See Also

[readini](readini.md), [writeini](writeini.md), [ConfigurationData](ConfigurationData.md), [YAMLData](YAMLData.md), [TOMLData](TOMLData.md)

## Version History

- Introduced in 2026a

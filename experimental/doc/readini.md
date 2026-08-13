# readini

**Read INI file**

## Syntax

```matlab
data = readini(filename)
data = readini(filename, 'SequenceRule', 'auto')
```

## Description

`data = readini(filename)` reads the INI file and returns an IniData object containing the parsed configuration data.

The function parses Windows INI format with sections and key-value pairs. Sections are denoted by `[SectionName]` headers. Key-value pairs use `key=value` or `key:value` syntax. Lines starting with `;` or `#` are treated as comments.

## Input Arguments

### `filename`

Path to the INI file to read.

*Type:* string scalar or character array

## Output Arguments

### `data`

Parsed INI data.

*Type:* IniData object

## Name-Value Arguments

### `'SequenceRule'`

Control how comma-separated values are converted.

*Values:* `'auto'` (default) | `'cell'`

- `'auto'`: Convert numeric sequences to arrays, string sequences to string arrays
- `'cell'`: Keep all sequences as cell arrays

*Default:* `'auto'`

## Examples

### Read Basic Configuration

Read a simple INI file:

```matlab
% config.ini:
% [server]
% host=localhost
% port=8080

config = readini('config.ini');
host = config.server.host;      % 'localhost'
port = config.server.port;      % '8080'
```

### Read with Multiple Sections

```matlab
% app.ini:
% [application]
% name=MyApp
% version=1.0.0
%
% [database]
% host=db.example.com
% port=5432
% ssl=true

config = readini('app.ini');
appName = config.application.name;
dbHost = config.database.host;
dbPort = config.database.port;     % Numeric
dbSSL = config.database.ssl;       % Logical
```

### Handle Special Characters in Keys

INI keys with hyphens or spaces are aliased for MATLAB:

```matlab
% [pool]
% max-size=20
% min-size=5

config = readini('config.ini');
maxSize = config.pool.("max-size");  % Using dynamic field name
minSize = config.pool.max_size;       % Using aliased name (underscore)
```

### Parse Comma-Separated Values

The function auto-detects and parses comma-separated values:

```matlab
% [settings]
% ports=8080,8443,9000
% hosts=alpha,beta,gamma
% enabled=true,false,true

config = readini('settings.ini');
ports = config.settings.ports;       % [8080 8443 9000]
hosts = config.settings.hosts;       % ["alpha" "beta" "gamma"]
enabled = config.settings.enabled;   % [true false true]
```

### Modify and Write Back

Load, modify, and save:

```matlab
config = readini('config.ini');
config.server.port = '9000';
writeini(config, 'config_updated.ini');
```

## Supported Format

### Sections
```ini
[SectionName]
```

### Key-Value Pairs
```ini
key=value
key:value
```

### Comments
```ini
; Comment at line start
# Another comment
```

### Value Types

- **Strings**: Any text
- **Booleans**: `true`, `false`, `yes`, `no`, `1`, `0`
- **Numbers**: Decimal, integer, scientific notation
- **Arrays**: Comma-separated values: `8080,8443,9000`

## Limitations

- **No multiline values**: Each line is a separate key-value pair
- **One nesting level**: Only section → key structure
- **String storage**: All values read as strings unless auto-detected as boolean/numeric
- **No escape sequences**: Special characters not supported in keys

## See Also

[writeini](writeini.md), [IniData](IniData.md), [readyaml](readyaml.md), [readtoml](readtoml.md)

## Version History

- Introduced in 2026a

# writeini

**Write data to INI file**

## Syntax

```matlab
writeini(data, filename)
writeini(data, filename, 'SectionSpacing', 'compact')
writeini(data, filename, 'Precision', 6)
```

## Description

`writeini(data, filename)` writes MATLAB data to an INI file in Windows INI format.

The function accepts IniData objects, structs, or containers.Maps and generates properly formatted INI files with sections and key-value pairs.

## Input Arguments

### `data`

Data to write.

*Type:* IniData | struct | containers.Map

- **IniData**: Directly written
- **struct**: Converted to IniData (nested structs become sections)
- **containers.Map**: Converted to IniData (nested maps become sections)

### `filename`

Output file path.

*Type:* string scalar or character array

## Name-Value Arguments

### `'SectionSpacing'`

Control spacing between INI sections.

*Values:* `'compact'` (default) | `'loose'`

- `'compact'`: No blank lines between sections
- `'loose'`: Blank line between each section

*Default:* `'compact'`

### `'Precision'`

Number of decimal places for floating-point numbers.

*Type:* integer, nonnegative

*Default:* 6

## Examples

### Create and Write Configuration

Create INI data programmatically:

```matlab
% Create INIData
config = inidata();

% Add server section
config.server.host = 'localhost';
config.server.port = 8080;
config.server.ssl = false;

% Add database section
config.database.host = 'db.example.com';
config.database.port = 5432;
config.database.name = 'myapp';
config.database.pool_size = 20;

% Write to file
writeini(config, 'app.ini');

% Output:
% [server]
% host=localhost
% port=8080
% ssl=false
%
% [database]
% host=db.example.com
% port=5432
% name=myapp
% pool_size=20
```

### Write Struct as INI

Convert MATLAB struct to INI:

```matlab
settings = struct();
settings.app.name = 'MyApp';
settings.app.version = '1.0.0';
settings.logging.level = 'info';
settings.logging.file = '/var/log/app.log';

writeini(settings, 'settings.ini');
```

### Write with Loose Spacing

Control section spacing:

```matlab
config = inidata();
config.section1.key1 = 'value1';
config.section2.key2 = 'value2';

% Loose spacing (blank line between sections)
writeini(config, 'output.ini', 'SectionSpacing', 'loose');

% Output:
% [section1]
% key1=value1
%
% [section2]
% key2=value2
```

### Handle Arrays and Vectors

Arrays are converted to comma-separated lists:

```matlab
config = inidata();
config.ports.active = [8080 8443 9000];          % Numeric array
config.servers.names = ["alpha" "beta" "gamma"]; % String array
config.flags.enabled = [true false true];        % Logical array

writeini(config, 'config.ini');

% Output:
% [ports]
% active=8080,8443,9000
%
% [servers]
% names=alpha,beta,gamma
%
% [flags]
% enabled=true,false,true
```

### Modify and Write

Read, modify, and save:

```matlab
% Read existing config
config = readini('app.ini');

% Modify values
config.server.port = 9000;
config.database.ssl = true;
config.database.pool_size = 50;

% Write back
writeini(config, 'app.ini');
```

### Control Floating-Point Precision

```matlab
config = inidata();
config.math.pi = pi;
config.math.e = exp(1);

% Default (6 significant figures)
writeini(config, 'math.ini');

% Higher precision
writeini(config, 'math_precise.ini', 'Precision', 12);

% Output (Precision=12):
% [math]
% pi=3.14159265359
% e=2.71828182846
```

## Output Format

### Sections

All top-level fields become section headers:

```ini
[SectionName]
```

### Key-Value Pairs

Keys within sections are written as:

```ini
key=value
```

### Comments

No comments are generated. To preserve comments, use programmatic reading/modification.

## Data Type Conversion

| MATLAB Type | INI Output |
|---|---|
| Logical | `true` \| `false` |
| Integer | `123` |
| Float | `3.14159` (precision controlled) |
| String | `value` |
| String array | `val1,val2,val3` |
| Numeric array | `1,2,3` |
| Logical array | `true,false,true` |

## Limitations

- **No deep nesting**: Only one section level supported
- **No comments**: Original comments not preserved when reading/writing
- **No multiline values**: Each value must fit on one line
- **Array serialization**: Arrays converted to comma-separated strings (information preserved, but structure lost)

## See Also

[readini](readini.md), [IniData](IniData.md), [writeyaml](writeyaml.md), [writetoml](writetoml.md)

## Version History

- Introduced in 2026a

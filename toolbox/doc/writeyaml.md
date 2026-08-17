# writeyaml

**Write data to YAML file**

The `writeyaml` function writes MATLAB&reg; data to a YAML file with customizable formatting options.

## Syntax

```matlab
writeyaml(data)
writeyaml(data,filename)
writeyaml(___,Name=Value)
```

## Description

`writeyaml(data)` writes the MATLAB data to `untitled.yaml` in the current directory.

`writeyaml(data,filename)` writes to the specified file.

`writeyaml(___,Name=Value)` specifies additional formatting options using name-value arguments.

## Input Arguments

### data
Data to write to file.
*Type:* [YAMLData](YAMLData.md), [ConfigurationData](ConfigurationData.md), struct, dictionary, containers.Map, cell array, or other MATLAB data types

### filename
Output file path.
*Type:* string scalar or character vector
*Default:* `"untitled.yaml"`

### Name-Value Arguments

#### ArrayStyle
Style for arrays and lists.
*Type:* `"block"` or `"flow"`
*Default:* `"block"`

- `"block"` - Use block style with `-` items (multi-line)
- `"flow"` - Use inline style as `[1, 2, 3]`

#### NumIndentationSpaces
Number of spaces for indentation.
*Type:* positive integer scalar
*Default:* `2`

#### SectionSpacing
Spacing between top-level sections.
*Type:* `"loose"` or `"compact"`
*Default:* `"loose"`

- `"loose"` - Blank line between each top-level key
- `"compact"` - No blank lines

#### Precision
Number of decimal places for numeric values.
*Type:* positive integer scalar
*Default:* `6`

## Examples

### Write YAMLData to File

Create and write YAML configuration:

```matlab
% Create YAMLData
config = yamldata();
config.app.name = "MyApp";
config.app.version = "1.0.0";
config.app.port = 8080;

% Write to file
writeyaml(config,"config.yaml");
```

### Control Array Formatting

Choose between block and flow style for arrays:

```matlab
% Create data with arrays
data = yamldata();
data.ports = [8080; 8443; 9000];
data.servers = ["localhost"; "api.example.com"];

% Block style (default) - multi-line
writeyaml(data,"servers_block.yaml");
% ports:
%   - 8080
%   - 8443
%   - 9000

% Flow style - compact inline
writeyaml(data,"servers_flow.yaml",ArrayStyle="flow");
% ports: [8080, 8443, 9000]
```

### Customize Formatting Options

Adjust spacing and indentation:

```matlab
% Create nested configuration
config = yamldata();
config.database.host = "localhost";
config.database.port = 5432;
config.cache.enabled = true;
config.cache.ttl = 3600;

% Compact format with 4-space indentation
writeyaml(config,"compact.yaml", ...
    NumIndentationSpaces=4, ...
    SectionSpacing="compact", ...
    Precision=2);
```

For more examples, see [readyamlExample.m](../../examples/readyamlExample.m).

## Tips

- Pass structs or dictionaries directly: `writeyaml(myStruct, "file.yaml")`.
- Use `ArrayStyle="flow"` for compact, single-line arrays in configuration files.
- Use `SectionSpacing="compact"` to reduce file size when readability isn't critical.
- The `Precision` option controls decimal places; use smaller values for cleaner output when full precision isn't needed.
- YAMLData, structs, and dictionaries produce equivalent YAML output; choose based on your workflow preferences.

## More About

### Data Type Conversions

MATLAB types are converted to YAML as follows:

**Numeric arrays:**
- Converted to YAML sequences based on `ArrayStyle`
- Precision controlled by `Precision` option

**String arrays:**
- Converted to YAML sequences
- Empty strings written as `""`

**Logical values:**
- `true` → `true`
- `false` → `false`

**Structs and objects:**
- Converted to YAML mappings (key-value pairs)
- Nested structs become nested YAML mappings

**Cell arrays:**
- Converted to YAML sequences
- Can contain mixed types

**Empty arrays:**
- `[]` → `[]` (empty sequence)

### Special Characters in Keys

Keys with special characters (hyphens, spaces) are automatically quoted when necessary to maintain valid YAML syntax.

## See Also

[readyaml](readyaml.md), [writetoml](writetoml.md), [YAMLData](YAMLData.md), [struct](https://www.mathworks.com/help/matlab/ref/struct.html)

## Version History

- Introduced in 2025a

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
*Type:* Any serializable MATLAB type:
- **Mapping types:** [YAMLData](YAMLData.md), struct, dictionary, or containers.Map
- **Sequence types:** struct array, YAMLData array, numeric array, string array, or cell array
- **Scalar types:** string, number, or logical

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
Number of significant digits for numeric values.
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

### Write a Struct Array as a Sequence

Write a struct array as a YAML sequence of mappings:

```matlab
records = [struct("name","A","value",1), struct("name","B","value",2)];
writeyaml(records,"records.yaml");
% - name: A
%   value: 1
%
% - name: B
%   value: 2
```

### Write Scalars and Arrays

Write primitive values directly:

```matlab
% Write a numeric array
writeyaml([1, 2, 3],"numbers.yaml");
% - 1
% - 2
% - 3

% Write a scalar string
writeyaml("hello world","greeting.yaml");
% hello world
```

For more examples, see [readyamlExample.m](../../examples/readyamlExample.m).

## Tips

- Pass structs or dictionaries directly: `writeyaml(myStruct, "file.yaml")`.
- Pass struct arrays for sequences of mappings: `writeyaml([struct("a",1), struct("a",2)], "file.yaml")`.
- Scalars and arrays are written directly as top-level YAML values.
- Use `ArrayStyle="flow"` for compact, single-line arrays in configuration files.
- Use `SectionSpacing="compact"` to reduce file size when readability isn't critical.
- The `Precision` option controls significant digits; use smaller values for cleaner output when full precision isn't needed.
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

**Datetime values:**
- Converted to YAML sequences based on `string(dt)` conversion.

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

## Limitations

- **Singleton array collapse on edit:** Editing or replacing the sole element of a one-item sequence (e.g., `data.steps(1).uses = "new"`) causes the sequence to collapse to a single mapping in the written output. Workaround: wrap the value in a cell array before writing.
- **`struct` conversion is lossy:** Converting a YAMLData object to a struct via `struct()` normalizes keys to valid MATLAB identifiers (e.g., `build-system` becomes `build_system`). Writing the struct back produces different keys than the original file. Use the YAMLData object directly for lossless round-trips.
- **Heterogeneous struct arrays gain null fields:** MATLAB struct arrays require all elements to share the same fields. Converting a YAMLData array of mappings with different keys to a struct array pads missing fields with empty values, which serialize as `null` in the output. Use YAMLData arrays to preserve per-record key sets.
- Comments are not preserved during round-trip.

## See Also

[readyaml](readyaml.md), [writetoml](writetoml.md), [YAMLData](YAMLData.md), [struct](https://www.mathworks.com/help/matlab/ref/struct.html)

## Version History

- Introduced in 2025a

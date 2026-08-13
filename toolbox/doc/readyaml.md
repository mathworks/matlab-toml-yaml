# readyaml

**Read data from YAML file**

The `readyaml` function reads YAML configuration files and returns the data as a [YAMLData](YAMLData.md) object with dot notation access and support for special characters in field names.

## Syntax

```matlab
data = readyaml(filename)
data = readyaml(filename,SequenceRule=rule)
```

## Description

`data = readyaml(filename)` reads the YAML file specified by `filename` and returns the data as a [YAMLData](YAMLData.md) object. YAML sequences (arrays) are automatically converted to the most appropriate MATLAB array type.

`data = readyaml(filename,SequenceRule=rule)` controls how YAML flow-style sequences `[item1, item2, ...]` are converted to MATLAB arrays.

## Input Arguments

### filename
File path to read.
*Type:* string scalar or character vector
*Validation:* Must be non-empty and point to an existing file.

### Name-Value Arguments

#### 'SequenceRule'
Controls array conversion behavior.
*Type:* string scalar - `"auto"` or `"cell"`
*Default:* `"auto"`

- `"auto"` - Automatically converts sequences to specialized arrays when possible:
  - `[1, 2, 3]` → numeric array `[1; 2; 3]`
  - `[a, b, c]` → string array `["a"; "b"; "c"]`
  - `[1, "two", true]` → cell array `{1; "two"; true}` (mixed types)

- `"cell"` - Always returns cell arrays for consistency:
  - `[1, 2, 3]` → cell array `{1; 2; 3}`
  - `[a, b, c]` → cell array `{"a"; "b"; "c"}`

## Output Arguments

### data
YAML data as a YAMLData object.
*Type:* [YAMLData](YAMLData.md)

[YAMLData](YAMLData.md) supports:
- Dot notation for field access: `data.field`
- Special character keys using dynamic field names: `data.("field-name")`
- Conversion to struct: `s = struct(data)`
- Methods: `keys`, `isfield`, `show`, `copy`

## Examples

### Basic YAML Reading

Read a simple YAML configuration file:

```matlab
% Create sample YAML file
yamlContent = [
    "app-name: MyApplication"
    "version: 1.2.0"
    "port: 8080"
    "debug: true"];
writelines(yamlContent,"config.yaml");

% Read the file
config = readyaml("config.yaml");

% Access values using dot notation
appName = config.("app-name")  % "MyApplication"
port = config.port             % 8080
```

### Using SequenceRule for Consistent Array Types

Control how arrays are returned:

```matlab
% YAML with numeric array
yamlContent = "ports: [8080, 8443, 9000]";
writelines(yamlContent,"ports.yaml");

% Default behavior - returns numeric array
config1 = readyaml("ports.yaml");
config1.ports  % [8080; 8443; 9000] - numeric array

% Force cell array for consistency
config2 = readyaml("ports.yaml","SequenceRule","cell");
config2.ports  % {8080; 8443; 9000} - cell array
```

### Nested Structures

Navigate nested YAML mappings:

```matlab
% Create nested YAML
yamlNested = [
    "database:"
    "  host: localhost"
    "  port: 5432"
    "  credentials:"
    "    username: admin"];
writelines(yamlNested,"nested.yaml");

% Read and access nested data
dbConfig = readyaml("nested.yaml");
username = dbConfig.database.credentials.username  % "admin"
```

For comprehensive examples including GitHub Actions workflows and advanced array handling, see [readyamlExample.m](../../examples/readyamlExample.m).

## Tips

- Use `"SequenceRule","cell"` when you need consistent array types regardless of content, making downstream processing more predictable.
- Access fields with special characters (hyphens, spaces, etc.) using dynamic field names: `data.("field-name")`.
- Convert YAMLData to standard structs using `struct(data)` for compatibility with code expecting struct inputs.
- YAMLData is a value class. Assignment creates independent copies automatically.

## More About

### Type Conversions

YAML values are converted to MATLAB types as follows:

**Booleans:**
- `true`, `yes`, `on` → `true`
- `false`, `no`, `off` → `false`

**Null values:**
- `null`, `~`, empty value → `[]`

**Numbers:**
- Automatically detected and converted to numeric values

**Strings:**
- Unquoted text → string scalars
- Quoted text (single or double quotes) → string scalars

**Arrays:**
- Flow-style: `[item1, item2, item3]`
- Block-style: List items starting with `-`
- Both styles support SequenceRule conversion

### Array Conversion Details

When `SequenceRule` is `"auto"` (default), arrays are converted based on element types:
- All elements numeric → column numeric array
- All elements text → column string array
- All elements logical → column logical array
- Mixed element types → column cell array

All arrays are returned as column vectors for consistency.

## Limitations

`readyaml` implements a lightweight, pure-MATLAB parser for the subset of YAML
most commonly used in configuration files. It is **not** a fully compliant YAML
1.2 parser. The following features are not supported:

- **Anchors and aliases** (`&`, `*`) are not supported and may be read as literal text.
- **Tags** (e.g. `!!str`, `!!float`) and **directives** (e.g. `%YAML 1.2`) are not supported.
- **Multiple documents** in one file (separated by `---`) are not supported; the entire file is treated as a single document.
- **Complex keys** are not supported; mapping keys must be scalar strings.
- **Flow-style mappings** (e.g. `{name: value}`) are not robustly parsed; use block style. Nested flow-style sequences (e.g. `[[1,2],[3,4]]`) are also not fully supported.
- **Block scalars** (`|` and `>`) are not explicitly supported and may be parsed incorrectly.
- **Timestamps** are detected with a regular expression covering a subset of ISO 8601; other date/time formats are read as strings.
- **Comments** (`#`) are removed during parsing and not preserved when writing.

For use cases requiring full spec compliance (for example, complex Kubernetes
manifests that use anchors), consider a Java-based library such as SnakeYAML.

## See Also

[writeyaml](writeyaml.md), [readtoml](readtoml.md), [YAMLData](YAMLData.md), [struct](https://www.mathworks.com/help/matlab/ref/struct.html)

## Version History

- Introduced in 2025a

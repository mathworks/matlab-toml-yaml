# setformat

**Set format metadata on configuration data keys**

The `setformat` function assigns formatting metadata to keys in a configuration data object. The metadata controls how values are rendered when written to file.

## Syntax

```matlab
obj = setformat(obj, key, Name=Value)
obj = setformat(obj, [key1, key2], Name=Value)
obj = setformat(obj, "a.b.c", Name=Value)
```

## Description

`obj = setformat(obj, key, Name=Value)` sets metadata properties on `key` and returns the modified object.

`obj = setformat(obj, [key1, key2], Name=Value)` applies the same metadata to multiple keys.

`obj = setformat(obj, "a.b.c", Name=Value)` navigates dot-separated key paths into nested objects.

**Value class semantics:** The return value must be captured. `setformat(obj, ...)` without capturing the result has no effect.

## Input Arguments

### obj
Configuration data object.
*Type:* [YAMLData](YAMLData.md) or [TOMLData](TOMLData.md)

### key
Key name or dot-separated path into nested objects.
*Type:* string scalar, string array, or character vector

### Name-Value Arguments

#### Shared Properties

These properties are available on both YAMLData and TOMLData objects.

##### ContainerStyle
Container rendering style.
*Values:* `"block"` (default), `"flow"`
- `"block"` -- Multi-line rendering (YAML block sequences/maps, TOML expanded tables)
- `"flow"` -- Inline rendering (YAML `[a, b]` / `{k: v}`, TOML inline)

##### ScalarStyle
Scalar string rendering style.
*Values:* `"auto"` (default), `"plain"`, `"double-quoted"`, `"single-quoted"`, `"literal"`, `"folded"`

##### IsArray
Mark the key as a sequence/array.
*Type:* logical

##### Comments
Comment lines to emit above the key.
*Type:* string array

##### TrailingComment
Inline comment after the value.
*Type:* string scalar

#### TOML-Specific Properties

These properties are only valid on TOMLData objects.

##### IntegerFormat
Integer rendering format.
*Values:* `"dec"` (default), `"hex"`, `"oct"`, `"bin"`

##### FloatFormat
Float rendering format.
*Values:* `"default"`, `"fixed"`, `"scientific"`

##### StringMultiline
Use multiline string syntax (`"""..."""` or `'''...'''`).
*Type:* logical

##### TableFormat
Table rendering style.
*Values:* `"expanded"` (default), `"inline"`, `"dotted"`

##### ArrayOfTables
Use `[[table]]` array-of-tables syntax.
*Type:* logical

## Examples

### Set Flow Array Style

```matlab
data = yamldata();
data.ports = [8080; 8443; 9000];
data = setformat(data, "ports", ContainerStyle="flow", IsArray=true);
writeyaml(data, "config.yaml");
% ports: [8080, 8443, 9000]
```

### Set Hex Integer Format (TOML)

```matlab
data = tomldata();
data.color = 255;
data = setformat(data, "color", IntegerFormat="hex");
writetoml(data, "config.toml");
% color = 0xFF
```

### Add Comments (TOML)

```matlab
data = tomldata();
data.port = 8080;
data = setformat(data, "port", Comments="# HTTP server port");
writetoml(data, "config.toml");
% # HTTP server port
% port = 8080
```

### Set Literal String Style

```matlab
data = yamldata();
data.path = "/usr/local/bin";
data = setformat(data, "path", ScalarStyle="single-quoted");
writeyaml(data, "config.yaml");
% path: '/usr/local/bin'
```

### Set Metadata on Nested Keys

```matlab
data = readyaml("config.yaml");
data = setformat(data, "server.ports", ContainerStyle="flow", IsArray=true);
```

## Tips

- Always capture the return value: `data = setformat(data, ...)`. Calling without assignment has no effect because ConfigurationData is a value class.
- Multiple properties can be set in a single call using multiple name-value pairs.
- Setting metadata on a key that already has metadata merges the new properties with the existing ones.

## See Also

[getformat](getformat.md), [resetformat](resetformat.md), [YAMLMetadata](YAMLMetadata.md), [TOMLMetadata](TOMLMetadata.md)

## Version History

- Introduced in R2026b

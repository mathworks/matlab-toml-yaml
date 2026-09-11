# TOMLMetadata

**TOML format metadata**

TOMLMetadata describes the formatting attributes for a node in a [TOMLData](TOMLData.md) object. It extends [YAMLMetadata](YAMLMetadata.md) with TOML-specific properties for integer formats, float formats, multiline strings, and table rendering. It is returned by [getformat](getformat.md) and consumed by [writetoml](writetoml.md) to reproduce the original style of a TOML file on round-trip.

## Creation

TOMLMetadata objects are returned by `getformat` on TOMLData objects. They can also be inspected after reading a TOML file:

```matlab
data = readtoml("config.toml");
meta = getformat(data, "color");
```

## Properties

### Inherited Properties

TOMLMetadata inherits all properties from [YAMLMetadata](YAMLMetadata.md):

- **ContainerStyle** -- `"block"` (default) or `"flow"`
- **ScalarStyle** -- `"auto"`, `"plain"`, `"double-quoted"`, `"single-quoted"`, `"literal"`, `"folded"`
- **IsArray** -- logical (default `false`)
- **Comments** -- string array of comment lines
- **TrailingComment** -- string scalar
- **Keys** -- dictionary of child key metadata overrides

### IntegerFormat
Integer rendering format.
*Type:* string scalar
*Values:* `"dec"` (default), `"hex"`, `"oct"`, `"bin"`

| Value | Output |
|-------|--------|
| `"dec"` | `255` |
| `"hex"` | `0xFF` |
| `"oct"` | `0o377` |
| `"bin"` | `0b11111111` |

### FloatFormat
Float rendering format.
*Type:* string scalar
*Values:* `"default"`, `"fixed"`, `"scientific"`

| Value | Output |
|-------|--------|
| `"default"` | `3.14` |
| `"fixed"` | `3.140000` |
| `"scientific"` | `3.14e+00` |

### StringMultiline
Use multiline string syntax.
*Type:* logical
*Default:* `false`

When `true`, strings are rendered with triple-quote delimiters (`"""..."""` for basic strings, `'''...'''` for literal strings).

### TableFormat
Table rendering style.
*Type:* string scalar
*Values:* `"expanded"` (default), `"inline"`, `"dotted"`

| Value | Output |
|-------|--------|
| `"expanded"` | `[table]` header with key-value pairs below |
| `"inline"` | `{key = val, key2 = val2}` |
| `"dotted"` | `table.key = val` |

### ArrayOfTables
Use `[[table]]` array-of-tables syntax.
*Type:* logical
*Default:* `false`

## Examples

### Inspect Hex Integer Metadata

```matlab
toml = "color = 0xFF";
writelines(toml, "config.toml");
data = readtoml("config.toml");

meta = getformat(data, "color");
meta.IntegerFormat  % "hex"
```

### Inspect Comment Metadata

```matlab
toml = ["# Server config", "port = 8080"];
writelines(toml, "config.toml");
data = readtoml("config.toml");

meta = getformat(data, "port");
meta.Comments  % "# Server config"
```

### Set Inline Table

```matlab
data = tomldata();
data.point.x = 1;
data.point.y = 2;
data = setformat(data, "point", TableFormat="inline");
writetoml(data, "config.toml");
% point = {x = 1, y = 2}
```

### Round-Trip with Formatting Preserved

```matlab
data = readtoml("pyproject.toml");
data.project.version = "2.0.0";
writetoml(data, "pyproject.toml");
% Comments, hex values, inline tables survive the round-trip
```

## See Also

[YAMLMetadata](YAMLMetadata.md), [getformat](getformat.md), [setformat](setformat.md), [resetformat](resetformat.md), [TOMLData](TOMLData.md)

## Version History

- Introduced in R2026b

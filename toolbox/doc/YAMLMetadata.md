# YAMLMetadata

**YAML format metadata**

YAMLMetadata describes the formatting attributes for a node in a [YAMLData](YAMLData.md) object. It is returned by [getformat](getformat.md) and consumed by [writeyaml](writeyaml.md) to reproduce the original style of a YAML file on round-trip.

## Creation

YAMLMetadata objects are returned by `getformat` on YAMLData objects. They can also be inspected after reading a YAML file:

```matlab
data = readyaml("config.yaml");
meta = getformat(data, "ports");
```

## Properties

### ContainerStyle
Container rendering style.
*Type:* string scalar
*Values:* `"block"` (default), `"flow"`

| Value | Sequence output | Mapping output |
|-------|----------------|----------------|
| `"block"` | `- item` (one per line) | `key: value` (one per line) |
| `"flow"` | `[item1, item2]` | `{key: val}` |

### ScalarStyle
Scalar string rendering style.
*Type:* string scalar
*Values:* `"auto"` (default), `"plain"`, `"double-quoted"`, `"single-quoted"`, `"literal"`, `"folded"`

| Value | Output |
|-------|--------|
| `"auto"` | Writer chooses the best style |
| `"plain"` | `value` (unquoted) |
| `"double-quoted"` | `"value"` |
| `"single-quoted"` | `'value'` |
| `"literal"` | `\|` block (preserves newlines) |
| `"folded"` | `>` block (folds newlines) |

### IsArray
Marks the key as a sequence.
*Type:* logical
*Default:* `false`

When `true`, the value is written as a YAML sequence even if it is a scalar MATLAB array.

### Comments
Comment lines emitted above the key.
*Type:* string array (column)
*Default:* `string.empty`

*Reserved for future use.* YAML comments are not currently preserved during round-trip.

### TrailingComment
Inline comment after the value.
*Type:* string scalar
*Default:* `""`

*Reserved for future use.*

### Keys
Dictionary of child key metadata overrides.
*Type:* dictionary
*Default:* empty dictionary

Stores per-key [YAMLMetadata](YAMLMetadata.md) objects for child keys that deviate from the node defaults. Usually accessed indirectly through [getformat](getformat.md) and [setformat](setformat.md) rather than manipulated directly.

## Examples

### Inspect Flow Sequence Metadata

```matlab
yaml = ["server:", "  ports: [8080, 8443]", "  host: localhost"];
writelines(yaml, "config.yaml");
data = readyaml("config.yaml");

meta = getformat(data, "server.ports");
meta.ContainerStyle  % "flow"
meta.IsArray         % true
```

### Set Single-Quoted Style

```matlab
data = yamldata();
data.path = "/usr/local/bin";
data = setformat(data, "path", ScalarStyle="single-quoted");
writeyaml(data, "config.yaml");
% path: '/usr/local/bin'
```

## See Also

[TOMLMetadata](TOMLMetadata.md), [getformat](getformat.md), [setformat](setformat.md), [resetformat](resetformat.md), [YAMLData](YAMLData.md)

## Version History

- Introduced in R2026b

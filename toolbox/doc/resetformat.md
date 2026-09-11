# resetformat

**Reset format metadata to defaults**

The `resetformat` function removes format metadata from keys, reverting them to default rendering when written to file.

## Syntax

```matlab
obj = resetformat(obj, key)
obj = resetformat(obj, [key1, key2])
obj = resetformat(obj)
```

## Description

`obj = resetformat(obj, key)` removes metadata for the specified key.

`obj = resetformat(obj, [key1, key2])` removes metadata for multiple keys.

`obj = resetformat(obj)` clears all metadata on the node.

**Value class semantics:** The return value must be captured. `resetformat(obj, ...)` without capturing the result has no effect.

## Input Arguments

### obj
Configuration data object.
*Type:* [YAMLData](YAMLData.md) or [TOMLData](TOMLData.md)

### key
Key name or dot-separated path into nested objects.
*Type:* string scalar, string array, or character vector

## Examples

### Reset a Single Key

```matlab
data = readyaml("config.yaml");
getformat(data, "ports").ContainerStyle  % "flow"

data = resetformat(data, "ports");
getformat(data, "ports").ContainerStyle  % "block" (default)
```

### Reset All Metadata

```matlab
data = readtoml("config.toml");
data = resetformat(data);
writetoml(data, "config_default.toml");
% All values written with default formatting
```

### Reset Multiple Keys

```matlab
data = resetformat(data, ["ports", "hosts"]);
```

## Tips

- After resetting, keys revert to default formatting: block containers, auto scalar style, decimal integers (TOML).
- Resetting a key that has no metadata is a no-op.
- To reset metadata on a nested key, use dot-path syntax: `data = resetformat(data, "server.ports")`.

## See Also

[getformat](getformat.md), [setformat](setformat.md), [YAMLMetadata](YAMLMetadata.md), [TOMLMetadata](TOMLMetadata.md)

## Version History

- Introduced in R2026b

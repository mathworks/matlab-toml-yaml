# getformat

**Query format metadata for configuration data keys**

The `getformat` function returns metadata describing how keys are formatted when written to file. Metadata reflects inheritance: keys with no explicit metadata inherit from the parent node.

## Syntax

```matlab
meta = getformat(obj, key)
meta = getformat(obj, [key1, key2])
meta = getformat(obj, "a.b.c")
tbl = getformat(obj)
getformat(obj)
```

## Description

`meta = getformat(obj, key)` returns the resolved [YAMLMetadata](YAMLMetadata.md) or [TOMLMetadata](TOMLMetadata.md) for `key`, depending on the type of `obj`.

`meta = getformat(obj, [key1, key2])` returns an array of metadata objects, one per key.

`meta = getformat(obj, "a.b.c")` navigates dot-separated key paths into nested objects.

`tbl = getformat(obj)` returns a summary table of all top-level keys with their ContainerStyle, ScalarStyle, and IsArray values.

`getformat(obj)` with no output argument displays the summary table.

## Input Arguments

### obj
Configuration data object.
*Type:* [YAMLData](YAMLData.md) or [TOMLData](TOMLData.md)

### key
Key name or dot-separated path into nested objects.
*Type:* string scalar, string array, or character vector

## Output Arguments

### meta
Resolved metadata for the requested key. The type matches the object:
- [YAMLMetadata](YAMLMetadata.md) for YAMLData objects
- [TOMLMetadata](TOMLMetadata.md) for TOMLData objects

Keys with no explicit metadata return a default metadata object. The resolution order is:

1. **Node metadata** -- If the key holds a nested object that has its own Metadata, that metadata is returned.
2. **Parent key override** -- If the parent node's Metadata.Keys dictionary has an entry for this key, that entry is returned.
3. **Parent inheritance** -- If the parent node has Metadata but no key-specific entry, ContainerStyle and ScalarStyle are inherited from the parent.
4. **Default** -- A default [YAMLMetadata](YAMLMetadata.md) or [TOMLMetadata](TOMLMetadata.md) with all properties at their default values.

### tbl
Summary table with columns: Key, ContainerStyle, ScalarStyle, IsArray.
*Type:* table

## Examples

### Inspect a Flow Sequence

```matlab
yaml = "ports: [8080, 8443, 9000]";
writelines(yaml, "config.yaml");
data = readyaml("config.yaml");

meta = getformat(data, "ports");
meta.ContainerStyle  % "flow"
meta.IsArray         % true
```

### Check Integer Format (TOML)

```matlab
toml = "color = 0xFF";
writelines(toml, "config.toml");
data = readtoml("config.toml");

meta = getformat(data, "color");
meta.IntegerFormat  % "hex"
```

### View Summary Table

```matlab
data = readyaml("config.yaml");
getformat(data)
```

```text
    Key        ContainerStyle    ScalarStyle    IsArray
    _______    ______________    ___________    _______

    "name"     "block"           "auto"         false
    "ports"    "flow"            "auto"         true
```

### Navigate Nested Keys

```matlab
data = readyaml("config.yaml");
meta = getformat(data, "server.ports");
meta.ContainerStyle  % "flow"
```

## Tips

- Use the no-argument form `getformat(obj)` for a quick overview of all top-level key styles.
- Dot-path navigation (`"a.b.c"`) follows the same resolution as dot notation on the object itself.
- Returned metadata is *resolved*: it reflects what the writer would actually use, including inherited values from parent nodes.

## See Also

[setformat](setformat.md), [resetformat](resetformat.md), [YAMLMetadata](YAMLMetadata.md), [TOMLMetadata](TOMLMetadata.md)

## Version History

- Introduced in R2026b

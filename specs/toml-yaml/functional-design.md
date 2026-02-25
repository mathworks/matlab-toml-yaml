# Functional Design

## Proposed Functional Design: Summary

### API Reference Table

**YAML**

| Name | Kind | Description |
|------|------|-------------|
| [`readyaml`](#readyaml) | Function | Read a YAML file; returns a `YAMLData` object |
| [`writeyaml`](#writeyaml) | Function | Write a `YAMLData` object (or struct) to a YAML file |
| [`yamldata`](#yamldata) | Function | Create a `YAMLData` object — informal constructor |
| [`matlab.io.config.YAMLData`](#matlabioconfyamldata) | Class | YAML data container; the type returned by `readyaml` |

**TOML**

| Name | Kind | Description |
|------|------|-------------|
| [`readtoml`](#readtoml) | Function | Read a TOML file; returns a `TOMLData` object |
| [`writetoml`](#writetoml) | Function | Write a `TOMLData` object (or struct) to a TOML file |
| [`tomldata`](#tomldata) | Function | Create a `TOMLData` object — informal constructor |
| [`matlab.io.config.TOMLData`](#matlabioconftomldata) | Class | TOML data container; the type returned by `readtoml` |

**Shared base**

| Name | Kind | Description |
|------|------|-------------|
| [`matlab.io.config.ConfigurationData`](#matlabioconfconfigurationdata) | Abstract class | Base class for all configuration data types; not instantiated directly; provides the dot notation, key management, and display behavior shared by `YAMLData` and `TOMLData` |

### Data Class Design

`YAMLData` and `TOMLData` are **value classes** — they behave like MATLAB structs, not objects. Copying produces an independent copy; modifying the copy does not affect the original.

The classes are **struct-like** by design, with a few extensions:

| Feature | Behavior |
|---------|----------|
| Dot notation access | `config.section.key` — reads and writes nested values in array `config.section` naturally, not comma-separated list |
| Special character keys | `config.("build-system")` — keys with hyphens, dots, or spaces are fully supported |
| Key aliases | `config.build_system` also works (auto-generated `makeValidName` alias) |
| Method calls | Function syntax required: `keys(config)`, `isfield(config, "k")`, `describe(config)` — dot syntax accesses data keys, not methods |
| Key order | Insertion order preserved on both read and write |
| Struct compatibility | `struct(config)` converts to a plain struct; writers also accept plain structs |

## Proposed Design: Details

### `readyaml`

Read a YAML file and return a `YAMLData` object.

#### Syntax

```matlab
data = readyaml(filename)
data = readyaml(filename, SequenceRule=rule)
```

#### Input Arguments

| Argument | Type | Constraints | Description |
|----------|------|-------------|-------------|
| `filename` | text scalar | Non-empty; file must exist | Path to the YAML file to read |

#### Name-Value Arguments

| Name | Type | Values | Default | Description |
|------|------|--------|---------|-------------|
| `SequenceRule` | `string` | `"auto"` \| `"cell"` | `"auto"` | Controls how YAML sequences are converted to MATLAB values |
| `DatetimeType` | `string` | `"datetime"` \| `"string"` | `"string"` | Controls how date-like string values are returned in MATLAB |

**`SequenceRule` conversion behavior:**

| YAML sequence | `"auto"` result | `"cell"` result |
|---------------|-----------------|-----------------|
| `[1, 2, 3]` homogeneous numeric | `[1 2 3]` — double array | `{1, 2, 3}` — cell array |
| `[a, b, c]` homogeneous text | `["a" "b" "c"]` — string array | `{"a", "b", "c"}` — cell array |
| `[1, "two", true]` heterogeneous | `{1, "two", true}` — cell array | `{1, "two", true}` — cell array |
| `[localhost]` (single-element) | `"localhost"` — string scalar; indistinguishable from the non-array form | `{"localhost"}` — 1-element cell; distinguishable from scalar |

**`SequenceRule` tradeoffs:**

| | `"auto"` | `"cell"` |
|---|---|---|
| Ease of use | High — sequences feel like native MATLAB arrays | Lower — every sequence is a cell array |
| Round-trip fidelity | Lossy for single-element sequences | Exact structural preservation |
| Array element access | `config.ports(1)` | `config.ports{1}` |
| Recommended when | Reading for extraction or modification | Strict structure preservation required |

TOML is less affected by this ambiguity. TOML's type system distinguishes arrays from scalars at the syntax level; `SequenceRule` is primarily a YAML concern.

**`DatetimeType` behavior:**

| | `"string"` (default) | `"datetime"` |
|---|---|---|
| Return type | `string` | MATLAB `datetime` |
| Date arithmetic | Not available | Available |
| Round-trip fidelity | Exact text preserved | May reformat |
| Recommended when | Preserving exact file representation | Processing or comparing dates |

Note: YAML has no native datetime type — date values in YAML are plain strings. When `DatetimeType="datetime"`, detection is heuristic: any value matching the ISO 8601 date pattern (`yyyy-MM-dd`, with optional time component) is parsed as a `datetime`. Values that do not match are returned as strings regardless of this setting. TOML datetime detection is unambiguous because TOML's type system marks datetimes explicitly.

#### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `data` | `matlab.io.config.YAMLData` | Configuration data object with dot notation access |

#### Examples

```matlab
% Default: convenient array types
config = readyaml("config.yaml");
config.ports              % [8080, 8443] — double array

% Strict round-trip: all sequences as cell arrays
config = readyaml("config.yaml", SequenceRule="cell");
config.server.allowed_hosts{end+1} = "staging.example.com";
writeyaml(config, "config.yaml");

% Parse ISO 8601 date strings as MATLAB datetime objects
config = readyaml("config.yaml", DatetimeType="datetime");
config.created_at         % datetime scalar (e.g., 2024-01-15)
```

---

### `writeyaml`

Write MATLAB data to a YAML file.

#### Syntax

```matlab
writeyaml(data)
writeyaml(data, filename)
writeyaml(data, filename, Name=Value, ...)
```

#### Input Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `data` | `YAMLData`, `ConfigurationData`, `struct`, `dictionary`, `containers.Map`, cell array, or other MATLAB type | (required) | Data to write to YAML |
| `filename` | text scalar | `"untitled.yaml"` | Output file path |

#### Name-Value Arguments

| Name | Type | Values | Default | Description |
|------|------|--------|---------|-------------|
| `ArrayStyle` | `string` | `"block"` \| `"flow"` | `"block"` | Output style for sequences. `"block"` writes each item on its own line with `- ` prefix; `"flow"` writes inline as `[a, b, c]` |
| `NumIndentationSpaces` | `(1,1) double` | positive integer | `2` | Number of spaces per indentation level |
| `SectionSpacing` | `string` | `"loose"` \| `"compact"` | `"loose"` | `"loose"` inserts a blank line between top-level keys; `"compact"` omits blank lines |
| `Precision` | `(1,1) double` | positive integer | `6` | Number of significant digits for floating-point values |

#### Output Arguments

None.

#### Notes

`ArrayStyle` has no `"auto"` mode (unlike `writetoml`). Block style is the YAML convention for config files; use `"flow"` explicitly for compact inline arrays such as short lists.

#### Examples

```matlab
writeyaml(config, "output.yaml");
writeyaml(config, "output.yaml", ArrayStyle="flow", NumIndentationSpaces=4);
writeyaml(config, "output.yaml", SectionSpacing="compact", Precision=10);
```

---

### `yamldata`

Create a `YAMLData` object. `yamldata` is the **informal interface** to `matlab.io.config.YAMLData`, following the MATLAB pattern where `figure` creates a `matlab.ui.Figure`. Most users work through `yamldata`; use `matlab.io.config.YAMLData` directly only when subclassing or writing type checks.

#### Syntax

```matlab
data = yamldata()
data = yamldata(input)
```

#### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `input` | `struct` or `dictionary` | Optional. Populate the new object from an existing data structure. When omitted, an empty object is returned. |

#### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `data` | `matlab.io.config.YAMLData` | New YAMLData object, empty or populated from `input` |

#### Examples

```matlab
% Create empty and populate
config = yamldata();
config.database.host = "localhost";
config.database.port = 5432;

% Create from struct
s.name = "MyApp";
s.version = "1.0";
config = yamldata(s);
```

---

### `matlab.io.config.YAMLData`

YAML configuration data container. This is the type returned by `readyaml` and created by `yamldata`. `YAMLData` is a concrete subclass of `matlab.io.config.ConfigurationData`, which provides dot notation, key management, and display behavior.

#### Superclasses

| Class | Role |
|-------|------|
| `matlab.io.config.ConfigurationData` | Dot notation, key management, display |
| `matlab.mixin.indexing.RedefinesDot` | Custom dot notation interception |
| `matlab.mixin.indexing.OverridesPublicDotMethodCall` | Routes dot notation to data keys, not methods |
| `matlab.mixin.CustomDisplay` | Formatted console display |

#### Reserved Key Name

`YAMLData` has no public properties. One key name is reserved and cannot be used as a configuration key: `xInternal__`.

#### Dot Notation and Key Aliasing

Dot notation on a `YAMLData` object always accesses data keys, never methods. This is enabled by the `OverridesPublicDotMethodCall` mixin. All methods must be called using **function syntax**:

```matlab
keys(config)       % correct: calls the keys method
config.keys        % NOT a method call — reads the data value under key "keys"
```

| Expression | Behavior |
|------------|----------|
| `obj.key` | Read the data value stored under `"key"` |
| `obj.key = value` | Assign `value` under `"key"` |
| `obj.("key-name")` | Access a key containing hyphens or other special characters |
| `obj.alias` | Access via auto-generated `makeValidName` alias (e.g., `obj.build_system` for key `"build-system"`) |

Keys with names that are not valid MATLAB identifiers (e.g., `"build-system"`) automatically get a `makeValidName` alias. Both the original key and the alias access the same stored value.

#### Value Semantics

`YAMLData` is a value class. Assignment creates an independent copy — modifying the copy does not affect the original:

```matlab
copy = original;       % independent copy
copy.field = "new";    % does NOT affect original
```

#### Nested Object Creation

Assigning to a nested path auto-creates intermediate objects of the same class:

```matlab
config = yamldata;
config.new.section.value = 42;  % creates nested YAMLData objects automatically
```

#### Methods

All methods must be called using **function syntax** — `keys(obj)`, not `obj.keys` (see Dot Notation and Key Aliasing above).

**Key introspection and manipulation**

| Method | Description |
|--------|-------------|
| `keys` | Return all key names in insertion order; works on scalar or array |
| `iskey` | Check if a key exists; works element-wise on scalar or array |
| `remove` | Remove a key; returns updated object |
| `properties` | Return key names as `cellstr`; used by IDE for tab completion |

**Struct-compatible aliases**

`YAMLData` also implements the standard MATLAB `struct` interface, allowing code written for structs to work without modification:

| Method | Equivalent to | Description |
|--------|--------------|-------------|
| `fieldnames` | `keys` | Return key names |
| `isfield` | `iskey` | Check if a key exists |
| `rmfield` | `remove` | Remove a key; returns updated object |

**Display**

| Method | Description |
|--------|-------------|
| `show` | Display the data as YAML text in the command window |
| `describe` | Print or return a structural overview |

**Conversions**

| Method | Description |
|--------|-------------|
| `struct` | Convert to MATLAB struct |
| `dictionary` | Convert to MATLAB `dictionary` |
| `map` | Convert to `containers.Map` |

---

#### `keys`

Return key names. For a scalar object, returns all keys in insertion order. For an array, returns the union of all keys across every element (preserving first-appearance order).

##### Syntax

```matlab
k = keys(obj)
[k, perElementKeys] = keys(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar or array | The configuration data object or array |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `k` | `string` array | Key names. For scalar `obj`: keys in insertion order. For array `obj`: union of all key names across elements, in first-appearance order. |
| `perElementKeys` | `cell` array | Only returned when called with two output arguments. Same size as `obj`. Each cell contains a `string` array of the key names for the corresponding array element. For scalar `obj`, returns a 1×1 cell containing `k`. |

##### Examples

```matlab
% Scalar: keys in insertion order
config = readyaml("config.yaml");
keys(config)          % ["database", "logging"]

% Array with heterogeneous keys: returns union
steps = wf.jobs.test.steps;   % 1×4 YAMLData array
keys(steps)           % ["name", "uses", "with"] — union across all elements

% Two-output form: per-element key sets
[allKeys, perStep] = keys(steps);
perStep{1}            % keys of the first element only
isequal(perStep{:})   % false if keys vary by element
```

---

#### `iskey`

Check whether a key exists in a `YAMLData` scalar or each element of an array. Useful for filtering arrays of configuration objects.

##### Syntax

```matlab
tf = iskey(obj, key)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar or array | The configuration data object or array |
| `key` | text scalar | Key name to check |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `tf` | `logical` array | Same size as `obj`; `tf(i)` is `true` if `obj(i)` contains `key` |

##### Examples

```matlab
% Filter an array of config objects to those that have "email"
hasEmail = iskey(data.users, "email");
emailUsers = data.users(hasEmail);

% Require all elements to have a key
all(iskey(data.users, "name"))
```

---

#### `remove`

Remove a key from the object. Returns the modified object. Because `YAMLData` is a value class, the return value must be captured.

##### Syntax

```matlab
obj = remove(obj, key)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data object |
| `key` | text scalar | Key to remove; original keys and aliases both accepted |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` | Updated object with the key removed |

##### Notes

```matlab
config = remove(config, "debug");   % correct: capture the result
remove(config, "debug");            % does nothing — result discarded
```

---

#### `properties`

Return key names as a cell array of character vectors. Used by the MATLAB IDE to populate tab completion.

##### Syntax

```matlab
p = properties(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data object |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `p` | `cell` of `char` | Key names |

---

#### `fieldnames`

Return key names as a `string` array. Struct-compatible alias for `keys`.

##### Syntax

```matlab
names = fieldnames(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data object |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `names` | `string` array | Key names in insertion order |

---

#### `isfield`

Check whether a key exists. Struct-compatible alias for `iskey`.

##### Syntax

```matlab
tf = isfield(obj, key)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data object |
| `key` | text scalar | Key name to check; original keys and aliases both accepted |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `tf` | `logical` scalar | `true` if the key exists |

---

#### `rmfield`

Remove a key from the object. Struct-compatible alias for `remove`; the return value must be captured.

##### Syntax

```matlab
obj = rmfield(obj, key)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data object |
| `key` | text scalar | Key to remove; original keys and aliases both accepted |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` | Updated object with the key removed |

---

#### `show`

Display the data as YAML text in the command window. Useful for viewing deeply nested structures.

##### Syntax

```matlab
show(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar or array | The object to display |

##### Notes

For scalar objects, displays the YAML serialization of the data. For arrays, displays each element as a YAML list item using `- ` block sequence syntax. Falls back to default display if serialization fails.

##### Examples

```matlab
config = readyaml("config.yaml");
show(config)
```
```
database:
  host: localhost
  port: 5432
  name: mydb
logging:
  level: info
```

```matlab
show(config.database)
```
```
host: localhost
port: 5432
name: mydb
```

---

#### `describe`

Print or return a structural overview of the configuration data. When called without an output argument, prints a recursive tree showing all keys, types, and scalar values to the console. When called with an output argument, returns a table for programmatic querying.

##### Syntax

```matlab
describe(obj)
describe(obj, Depth=N)
info = describe(obj)
info = describe(obj, Depth=N)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data to describe |

##### Name-Value Arguments

| Name | Type | Values | Default | Description |
|------|------|--------|---------|-------------|
| `Depth` | `(1,1) double` | positive number | `Inf` | Maximum recursion depth for nested objects |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `info` | `table` | Only returned when called with an output argument; otherwise output is printed. Columns: `Path` (string), `Type` (string), `Size` (string). |

##### Examples

```matlab
describe(config)
```
```
YAMLData with 2 keys
  database          YAMLData        [1×1, 3 keys]
    host            string          "localhost"
    port            double          5432
    name            string          "mydb"
  logging           YAMLData        [1×1, 2 keys]
    level           string          "info"
    file            string          "app.log"
```

```matlab
describe(config, Depth=1)
```
```
YAMLData with 2 keys
  database          YAMLData        [1×1, 3 keys]
  logging           YAMLData        [1×1, 2 keys]
```

```matlab
info = describe(config);
info(info.Type == "string", :)      % query: all string-valued fields
```

---

#### `struct`

Convert the configuration data to a plain MATLAB struct. Keys with special characters are coerced to valid field names via `makeValidName`. Nested `YAMLData` objects are recursively converted to nested structs.

##### Syntax

```matlab
s = struct(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar or array | The configuration data to convert |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `s` | `struct` or struct array | Arrays of `YAMLData` produce struct arrays |

##### Notes

Keys with special characters (e.g. `"build-system"`) are coerced to valid field names (e.g. `build_system`). This is one-way — writing the result back to a file will not recover the original key name. For round-trip key fidelity, use the `YAMLData` object directly.

---

#### `dictionary`

Convert the configuration data to a MATLAB `dictionary` with string keys and cell values. Nested `YAMLData` objects are recursively converted to nested dictionaries.

##### Syntax

```matlab
d = dictionary(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data to convert |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `d` | `dictionary<string, cell>` | Values are wrapped in cells; retrieve with `d{"key"}` |

---

#### `map`

Convert the configuration data to a `containers.Map`. Provided for compatibility with code that requires `containers.Map`. For new code, prefer `struct` or `dictionary`.

##### Syntax

```matlab
m = map(obj)
```

##### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `obj` | `YAMLData` scalar | The configuration data to convert |

##### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `m` | `containers.Map` | Key-value map with string keys |

---

### `readtoml`

Read a TOML file and return a `TOMLData` object.

#### Syntax

```matlab
data = readtoml(filename)
data = readtoml(filename, DatetimeType=type)
```

#### Input Arguments

| Argument | Type | Constraints | Description |
|----------|------|-------------|-------------|
| `filename` | `(1,1) string` | File must exist | Path to the TOML file to read |

#### Name-Value Arguments

| Name | Type | Values | Default | Description |
|------|------|--------|---------|-------------|
| `DatetimeType` | `(1,1) string` | `"datetime"` \| `"string"` | `"datetime"` | Controls how TOML native datetime values are returned in MATLAB |

**`DatetimeType` behavior:**

| | `"datetime"` | `"string"` |
|---|---|---|
| Return type | MATLAB `datetime` | `string` |
| Date arithmetic | Available | Not available |
| Round-trip fidelity | May reformat (timezone normalization, precision) | Exact text preserved |
| Recommended when | Processing or comparing dates | Preserving exact file representation |

TOML has four native datetime subtypes: offset datetime (e.g. `2024-01-15T12:00:00Z`), local datetime (`2024-01-15T12:00:00`), local date (`2024-01-15`), and local time (`12:00:00`). Because TOML's type system marks datetimes explicitly, detection is unambiguous. YAML has no native datetime type — detection in `readyaml` is heuristic (ISO 8601 pattern matching) and defaults to `"string"` to avoid unexpected type coercion.

#### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `data` | `matlab.io.config.TOMLData` | Configuration data object with dot notation access |

#### Examples

```matlab
% Default: TOML dates become MATLAB datetime objects
project = readtoml("pyproject.toml");

% Preserve exact datetime text for round-trip fidelity
project = readtoml("pyproject.toml", DatetimeType="string");
```

---

### `writetoml`

Write MATLAB data to a TOML file.

#### Syntax

```matlab
writetoml(data)
writetoml(data, filename)
writetoml(data, filename, Name=Value, ...)
```

#### Input Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `data` | `TOMLData`, `ConfigurationData`, `struct`, `dictionary`, or `containers.Map` | (required) | Data to write to TOML |
| `filename` | `(1,1) string` | `"untitled.toml"` | Output file path |

#### Name-Value Arguments

| Name | Type | Values | Default | Description |
|------|------|--------|---------|-------------|
| `ArrayStyle` | `string` | `"auto"` \| `"flow"` \| `"block"` | `"auto"` | Style for TOML arrays. `"auto"` uses heuristics (flow for short arrays, block for long or complex); `"flow"` forces inline `[1, 2, 3]`; `"block"` forces multiline one-item-per-line |
| `NumIndentationSpaces` | `(1,1) double` | positive integer | `2` | Number of spaces per indentation level |
| `SectionSpacing` | `string` | `"loose"` \| `"compact"` | `"loose"` | `"loose"` inserts a blank line between top-level tables; `"compact"` omits blank lines |
| `Precision` | `(1,1) double` | positive integer | `6` | Number of significant digits for floating-point values |
| `TableStyle` | `string` | `"auto"` \| `"inline"` \| `"expanded"` | `"auto"` | Style for nested TOML tables. `"auto"` uses heuristics based on size and complexity; `"inline"` forces `{key = value}` syntax; `"expanded"` forces `[section]` header syntax |
| `TableArrayStyle` | `string` | `"auto"` \| `"expanded"` \| `"inline"` | `"expanded"` | Style for arrays of tables (`[[section]]`). `"expanded"` writes one `[[section]]` header per record (standard, most readable); `"inline"` writes a compact array of inline tables; `"auto"` uses heuristics |
| `StringEscapeStyle` | `string` | `"auto"` \| `"escaped"` \| `"literal"` | `"auto"` | TOML string quoting style. `"escaped"` produces basic strings with `\` escape sequences; `"literal"` produces single-quoted strings where backslashes are verbatim (natural for Windows paths); `"auto"` chooses per-value |
| `StringLayout` | `string` | `"auto"` \| `"singleline"` \| `"multiline"` | `"auto"` | Line layout for string values. `"singleline"` forces single-line delimiters; `"multiline"` forces triple-quoted multiline delimiters; `"auto"` chooses based on content |

#### Output Arguments

None.

#### Notes

- `ArrayStyle` includes `"auto"` (unlike `writeyaml`). Most TOML arrays appear inline in real files; `"auto"` produces natural-looking TOML by default.
- `TableStyle` and `TableArrayStyle` are separate parameters because they control distinct TOML constructs (tables vs. arrays of tables) with different defaults. Heuristic thresholds (e.g., `InlineTableMaxFields`) are not exposed — users choose between `"auto"`, `"expanded"`, and `"inline"`.
- `StringEscapeStyle` and `StringLayout` are orthogonal: escape processing (semantic intent) is independent of line layout (presentation).

#### Examples

```matlab
writetoml(config, "pyproject.toml");
writetoml(config, "config.toml", ArrayStyle="flow", SectionSpacing="compact");
writetoml(config, "pyproject.toml", TableArrayStyle="inline");
writetoml(config, "config.toml", StringEscapeStyle="literal");  % natural for Windows paths
```

---

### `tomldata`

Create a `TOMLData` object. `tomldata` is the **informal interface** to `matlab.io.config.TOMLData`, following the same pattern as `yamldata`. Most users work through `tomldata`; use `matlab.io.config.TOMLData` directly only when subclassing or writing type checks.

#### Syntax

```matlab
data = tomldata()
data = tomldata(input)
```

#### Input Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `input` | `struct` or `dictionary` | Optional. Populate the new object from an existing data structure. When omitted, an empty object is returned. |

#### Output Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `data` | `matlab.io.config.TOMLData` | New TOMLData object, empty or populated from `input` |

#### Examples

```matlab
config = tomldata();
config.project.name = "my-package";
config.project.version = "1.0.0";
```

---

### `matlab.io.config.TOMLData`

TOML configuration data container. This is the type returned by `readtoml` and created by `tomldata`. `TOMLData` is a concrete subclass of `matlab.io.config.ConfigurationData`, which provides dot notation, key management, and display behavior. All properties, methods, and behaviors are identical to `YAMLData`; the only differences are that `SourceFormat` is `"toml"` and nested object creation produces `TOMLData` objects.

#### Superclasses

| Class | Role |
|-------|------|
| `matlab.io.config.ConfigurationData` | Dot notation, key management, display |
| `matlab.mixin.indexing.RedefinesDot` | Custom dot notation interception |
| `matlab.mixin.indexing.OverridesPublicDotMethodCall` | Routes dot notation to data keys, not methods |
| `matlab.mixin.CustomDisplay` | Formatted console display |

#### Reserved Key Name

`TOMLData` has no public properties. One key name is reserved and cannot be used as a configuration key: `xInternal__`.

#### Dot Notation and Key Aliasing

Identical to `YAMLData`. Dot notation always accesses data keys, never methods; all methods require function syntax. Keys with special characters get `makeValidName` aliases.

```matlab
keys(config)       % correct: calls the keys method
config.keys        % NOT a method call — reads the data value under key "keys"

config.("build-system")   % original key — always works
config.build_system        % auto-generated alias — also works
```

#### Value Semantics

Identical to `YAMLData`. `TOMLData` is a value class; assignment creates an independent copy.

#### Nested Object Creation

Assigning to a nested path auto-creates intermediate `TOMLData` objects:

```matlab
config = tomldata;
config.new.section.value = 42;  % creates nested TOMLData objects automatically
```

#### Methods

All methods must be called using **function syntax** — `keys(obj)`, not `obj.keys`.

**Key introspection and manipulation**

| Method | Description |
|--------|-------------|
| `keys` | Return all key names in insertion order; works on scalar or array |
| `iskey` | Check if a key exists; works element-wise on scalar or array |
| `remove` | Remove a key; returns updated object |
| `properties` | Return key names as `cellstr`; used by IDE for tab completion |

**Struct-compatible aliases**

`TOMLData` also implements the standard MATLAB `struct` interface, allowing code written for structs to work without modification:

| Method | Equivalent to | Description |
|--------|--------------|-------------|
| `fieldnames` | `keys` | Return key names |
| `isfield` | `iskey` | Check if a key exists |
| `rmfield` | `remove` | Remove a key; returns updated object |

**Display**

| Method | Description |
|--------|-------------|
| `show` | Display the data as TOML text in the command window |
| `describe` | Print or return a structural overview |

**Conversions**

| Method | Description |
|--------|-------------|
| `struct` | Convert to MATLAB struct |
| `dictionary` | Convert to MATLAB `dictionary` |
| `map` | Convert to `containers.Map` |

The method reference for `TOMLData` is identical to `YAMLData` — see the [YAMLData methods](#matlabioconfyamldata) section above, substituting `TOMLData` for `YAMLData` throughout.

---

### `matlab.io.config.ConfigurationData`

Abstract base class for all configuration data types. This is an implementation detail — users interact with `YAMLData` and `TOMLData` directly. `ConfigurationData` is relevant when subclassing to create a custom format type, or when writing type checks that apply across all formats: `isa(obj, "matlab.io.config.ConfigurationData")`.

#### Methods

All methods must be called using **function syntax** — dot notation routes to data keys, not methods. Full documentation for each method is in the `YAMLData` section; the same methods and behaviors apply to all subclasses.

**Key introspection and manipulation**

| Method | Description |
|--------|-------------|
| `keys` | Return all key names in insertion order; works on scalar or array |
| `iskey` | Check if a key exists; works element-wise on scalar or array |
| `remove` | Remove a key; returns updated object |
| `properties` | Return key names as `cellstr`; used by IDE for tab completion |

**Struct-compatible aliases**

| Method | Equivalent to | Description |
|--------|--------------|-------------|
| `fieldnames` | `keys` | Return key names |
| `isfield` | `iskey` | Check if a key exists |
| `rmfield` | `remove` | Remove a key; returns updated object |

**Display**

| Method | Description |
|--------|-------------|
| `show` | Display the data in format-appropriate text (defined per subclass) |
| `describe` | Print or return a structural overview |

**Conversions**

| Method | Description |
|--------|-------------|
| `struct` | Convert to MATLAB struct |
| `dictionary` | Convert to MATLAB `dictionary` |
| `map` | Convert to `containers.Map` |

---

### YAML vs. TOML API Differences

`YAMLData` and `TOMLData` share identical class APIs. The reader and writer functions are intentionally parallel, but a few options differ between formats to reflect genuine differences in the YAML and TOML specifications. This section collects those divergences in one place.

#### `SequenceRule` — reader option, YAML only

| | `readyaml` | `readtoml` |
|---|---|---|
| `SequenceRule` option | Yes — `"auto"` (default) or `"cell"` | Not present |

YAML has no syntactic distinction between a scalar and a single-element sequence — both are just a value. `SequenceRule="cell"` lets users preserve that structural distinction at the cost of less ergonomic access. TOML's type system marks arrays explicitly at the syntax level, so the ambiguity does not arise.

#### `DatetimeType` — reader option, different defaults

| | `readyaml` | `readtoml` |
|---|---|---|
| `DatetimeType` default | `"string"` | `"datetime"` |

TOML has four native datetime subtypes. The type is declared unambiguously in the file, so returning a MATLAB `datetime` by default is safe and expected. YAML has no native datetime type — detection must be heuristic (ISO 8601 pattern matching). Defaulting to `"string"` avoids silently coercing strings that happen to look like dates; users opt in with `DatetimeType="datetime"` when they know their file contains dates.

#### `ArrayStyle` — writer option, different defaults and value sets

| | `writeyaml` | `writetoml` |
|---|---|---|
| `ArrayStyle` values | `"block"` (default) \| `"flow"` | `"auto"` (default) \| `"flow"` \| `"block"` |

Block style (`- item` per line) is the dominant YAML convention for configuration files. `writeyaml` defaults to it and does not offer `"auto"` — there is no ambiguity to resolve. In TOML, short arrays appear inline in nearly all real files, so `writetoml` defaults to `"auto"` and uses heuristics to choose between inline and multiline.

#### Additional writer options — TOML only

| Option | Present in `writeyaml` | Present in `writetoml` |
|--------|------------------------|------------------------|
| `TableStyle` | No | Yes |
| `TableArrayStyle` | No | Yes |
| `StringEscapeStyle` | No | Yes |
| `StringLayout` | No | Yes |

TOML has a richer syntax with multiple representations for the same data: tables can be `[section]` headers or `{inline = "tables"}`; strings can be basic (`"..."`), literal (`'...'`), or multiline (`"""..."""`). These options expose that expressiveness. YAML's writer model is simpler — indentation-based block structure has no equivalent multiplicity of representation — so these options have no YAML analogue.

---

### Design Cases

#### Design Case: Programmatic CI/CD Workflow Generation (yaml)

```matlab
% Generate a GitHub Actions workflow for a MATLAB toolbox project

workflow = yamldata;
workflow.name = "CI";
workflow.on.push.branches = ["main"];
workflow.on.pull__request.branches = ["main"];  % note: key alias for "pull_request"

% Build the test job
job = yamldata;
job.("runs-on") = "ubuntu-latest";
job.strategy.matrix.matlab = ["R2022b", "R2023a", "R2024a", "R2025a"];

setupStep = yamldata;
setupStep.name = "Set up MATLAB";
setupStep.uses = "matlab-actions/setup-matlab@v2";
setupStep.with.release = "${{ matrix.matlab }}";

testStep = yamldata;
testStep.name = "Run tests";
testStep.uses = "matlab-actions/run-tests@v2";

job.steps = [setupStep, testStep];
workflow.jobs.test = job;

% Write the generated workflow
writeyaml(workflow, ".github/workflows/ci.yaml");
```

#### Design Case: ML Experiment Configuration (yaml)

```matlab
% Read hyperparameter config
params = readyaml("experiments/baseline.yaml");

% Inspect structure
describe(params);

% Modify for a learning rate sweep
params.training.learning_rate = 0.001;
params.training.epochs = 100;

% Save variant
writeyaml(params, "experiments/lr_sweep_1.yaml");
```

#### Design Case: Python Project Metadata (toml)

```matlab
% Read pyproject.toml
project = readtoml("pyproject.toml");

% Access metadata
name    = project.project.name;
version = project.project.version;
authors = project.project.authors;

% Check build dependencies (note: hyphenated key)
deps = project.("build-system").requires;
```

### Design Rationale

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | `read<type>`/`write<type>` naming aligns with modern MATLAB conventions (`readstruct`, `readtable`) | HIGH |
| 2 | Dot notation provides natural MATLAB syntax for nested access | HIGH |
| 3 | Value class semantics match user expectations for data objects | HIGH |
| 4 | Shared base class reduces code duplication across formats | MEDIUM |
| 5 | Special character support via `("key-name")` syntax handles real-world files | HIGH |
| 6 | Namespace design (`matlab.io.config.*`) follows MathWorks convention; informal wrappers maintain discoverability | HIGH |
| 7 | Function-syntax method calls allow config keys to have any name without conflict | HIGH |
| 8 | Type validation at assignment provides immediate feedback before a file write is attempted | MEDIUM |

| # | **Cons** | **Mitigation Plans** | **Priority** |
|---|----------|---------------------|--------------|
| 1 | Subset parser doesn't support full YAML 1.2 spec | Document limitations clearly; covers 95%+ of config files | MEDIUM |
| 2 | Comments not preserved on round-trip | Document as known limitation; common in config parsers | LOW |
| 3 | Array/scalar round-trip ambiguity in YAML | `SequenceRule="cell"` option; clear documentation of tradeoff | MEDIUM |
| 4 | Function-syntax methods differ from typical MATLAB OOP | Discoverable via tab completion and documentation | LOW |

### Error Conditions and Edge Cases

| # | **Condition** | **Proposed Error / Warning Message** |
|---|---------------|-------------------------------------|
| 1 | File not found | `Error: Unable to open file "filename.yaml". File does not exist.` |
| 2 | Invalid YAML syntax | `Error: YAML parse error at line N: <description>` |
| 3 | Invalid TOML syntax | `Error: TOML parse error at line N: <description>` |
| 4 | Unsupported YAML feature (anchors) | `Warning: YAML anchors and aliases are not supported. Data may be incomplete.` |
| 5 | Empty file | Returns empty ConfigurationData object (no error) |
| 6 | Key with invalid MATLAB identifier | Automatically creates alias; accessible via `("original-key")` |
| 7 | Assigning unsupported type (e.g., `function_handle`) | `Error: Cannot assign value of type 'function_handle'. Function handles cannot be serialized to a config file.` |
| 8 | Assigning a `table` | `Error: Cannot assign table directly. Convert first: struct(yourTable)` |
| 9 | Accessing `data.users.name` on a ConfigurationData array | `Error: Cannot access field 'name' on a [1 3] array of YAMLData objects. Index into the array first, e.g., obj(1).name or use: arrayfun(@(x) x.name, obj)` |

## Alternate Designs Considered

### Category A: Return Type Alternatives

#### A1: Plain MATLAB Structs (readyaml, readtoml return type)

**Description:** Return plain MATLAB structs from reader functions instead of custom classes.

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Familiar to all MATLAB users | HIGH |
| 2 | No custom class learning curve | MEDIUM |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Cannot handle keys with hyphens/special characters | HIGH |
| 2 | Awkward or impossible to round-trip if coercing keys to valid MATLAB identifiers | HIGH |
| 3 | Can't customize display to use domain-relevant terminology | MEDIUM |

**Decision:** Rejected due to special character limitation.

---

#### A2: containers.Map (readyaml, readtoml return type)

**Description:** Return `containers.Map` as the primary data structure.

```matlab
config = readyaml("config.yaml");  % Returns containers.Map
config("database")("host")         % Access pattern
```

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Native MATLAB type, no custom classes | MEDIUM |
| 2 | Supports any key type | HIGH |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Handle class semantics cause confusion (`b = a` shares data) | HIGH |
| 2 | Verbose access syntax, not dot notation | HIGH |
| 3 | No format-specific metadata | LOW |

**Decision:** Rejected due to handle semantics and verbose syntax.

---

#### A3: dictionary (readyaml, readtoml return type)

**Description:** Return MATLAB's built-in `dictionary` type directly as the data structure

```matlab
config = readyaml("config.yaml");  % Returns dictionary
config("database")("host")         % Access pattern
```

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Native MATLAB type with value semantics — copies are independent | HIGH |
| 2 | No custom class learning curve | MEDIUM |
| 3 | Already required as a minimum-version dependency | LOW |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Access syntax is `config("key")` not `config.key` — no dot notation | HIGH |
| 2 | Heterogeneous values require `dictionary<string,cell>` — retrieving values needs `{1}` unwrapping | HIGH |
| 3 | Nested structures would be `dictionary` of `dictionary` — deeply awkward access patterns | HIGH |
| 4 | No custom display, no methods, no format metadata | MEDIUM |
| 5 | `dictionary` does not support dot notation overloading | HIGH |

**Decision:** Rejected. While `dictionary` solves the value semantics problem of `containers.Map`, it still cannot provide dot notation access, and the cell-unwrapping required for heterogeneous values makes even simple access verbose. It is the right choice for internal storage (where the class implementation handles the boilerplate), but not as a public return type.

---

### Category B: Class Semantics Alternatives

#### B1: Handle Class Semantics (ConfigurationData class design)

**Description:** Use handle class semantics for ConfigurationData objects.

```matlab
config = readyaml("config.yaml");
copy = config;       % Both point to same data
copy.name = "new";   % Modifies original too!
```

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Works with older MATLAB versions (pre-R2022b) | MEDIUM |
| 2 | Simpler nested modification (no write-back needed internally) | LOW |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Handle semantics confuse users: `b = a; b.x = 1` modifies `a` | HIGH |
| 2 | Requires explicit `copy()` method for independent copies | MEDIUM |
| 3 | Inconsistent with MATLAB data object expectations | HIGH |

**Decision:** Initially implemented, then migrated away. Value semantics provide more intuitive behavior for data objects.

---

#### B2: Support Comma-Separated List for Array Field Access (dot notation on ConfigurationData arrays)

**Description:** Make `arr.name` return comma-separated list like struct arrays when `arr` is a ConfigurationData array.

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Matches struct array behavior | MEDIUM |
| 2 | Convenient for extracting fields | MEDIUM |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | ConfigurationData arrays can have heterogeneous keys | HIGH |
| 2 | Behavior unpredictable if elements have different keys | HIGH |
| 3 | Code relying on this would fail at runtime depending on data | HIGH |

**Decision:** Rejected. Instead, provide helpful error message with workarounds:
```
Cannot access field 'name' on a [1 3] array of TOMLData objects.
Index into the array first, e.g., obj(1).name or use:
  arrayfun(@(x) x.name, obj)
```

---

### Category C: Class Hierarchy Alternatives

#### C1: Format-Specific Classes Without Shared Base (YAMLData, TOMLData class hierarchy)

**Description:** Create separate `YAMLData` and `TOMLData` classes without a common `ConfigurationData` base class.

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Simpler class hierarchy | LOW |
| 2 | Format-specific optimizations possible | LOW |

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Code duplication across formats | HIGH |
| 2 | Inconsistent APIs between formats | MEDIUM |
| 3 | Cannot use `isa(obj, 'matlab.io.config.ConfigurationData')` for type checking | MEDIUM |

**Decision:** Rejected. Shared base class reduces duplication and ensures consistent API.

---

#### C2: Generic Hash/Map Class (ConfigurationData class scope)

**Description:** Create a general-purpose dictionary-like class usable beyond configuration files.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Would compete with MATLAB's built-in `dictionary` | HIGH |
| 2 | Scope creep beyond configuration file use case | MEDIUM |

**Decision:** Rejected. Too broad; `dictionary` (R2022b+) already serves this purpose.

---

### Category D: Function Naming Alternatives

#### D1: Format-First Naming (`yamlread`, `yamlwrite`, `tomlread`, `tomlwrite`)

**Description:** Use `<format>read` / `<format>write` pattern like legacy MATLAB I/O functions.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Inconsistent with modern MATLAB (`readtable`, `readstruct`) | HIGH |
| 2 | Legacy pattern is being phased out | MEDIUM |
| 3 | `readstruct`/`writestruct` is closest analogue and uses type-first | HIGH |

**Decision:** Rejected. Modern MATLAB uses `read<type>`/`write<type>` pattern.

---

### Category E: Named Argument Alternatives

#### E1: `ArrayFormat` Instead of `SequenceRule` (readyaml option)

**Description:** Use `ArrayFormat` parameter name for controlling how YAML sequences are converted.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Confusingly similar to `ArrayStyle` (write option) | HIGH |
| 2 | "Format" is ambiguous — could mean output formatting | MEDIUM |
| 3 | Doesn't use correct YAML terminology ("sequence") | LOW |

**Decision:** Rejected. `SequenceRule` provides clear distinction from `ArrayStyle` and uses correct YAML terminology. "Rule" suffix matches MATLAB convention (`VariableNamingRule` in `detectImportOptions`).

---

#### E2: Exposing Heuristic Thresholds (writetoml options)

**Description:** Parameters to control automatic behavior thresholds, e.g., `InlineTableMaxFields`.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Overfits API to implementation details | HIGH |
| 2 | Heuristics may change; API becomes unstable | HIGH |
| 3 | Violates MATLAB philosophy of "useful automatic behavior" | HIGH |

**Decision:** Rejected. Users get `"auto"`, `"expanded"`, or `"inline"` — not threshold tweaking. See `Claude/TOMLWRITE_FORMAT_OPTIONS.md`.

---

#### E3: `TableStyle` and `TableArrayStyle` Naming Alternatives (writetoml options)

| Candidate | Evaluation |
|-----------|-----------|
| `ArrayOfTablesStyle` | Contains "Of" (prepositions discouraged); verbose |
| `TableListStyle` | TOML uses "array", not "list" |
| `TableSequenceStyle` | Not TOML terminology |
| `RepeatedTableStyle` | Obscure, indirect |
| **`TableArrayStyle`** | Clear, concise, TOML-native |

**Decision:** `TableArrayStyle` chosen.

---

#### E4: Single `StringStyle` vs `StringEscapeStyle` + `StringLayout` (writetoml options)

**Decision:** Chose orthogonal parameters:
- `StringEscapeStyle` — Controls escape processing (`"auto"`, `"escaped"`, `"literal"`)
- `StringLayout` — Controls line formatting (`"auto"`, `"singleline"`, `"multiline"`)

Rationale: Separates semantic intent (escape processing) from presentation (layout).

---

### Category F: Terminology Alternatives

#### F1: "Fields" vs "Keys" vs "Properties" (ConfigurationData method names and display terminology)

| Term | Context | Decision |
|------|---------|----------|
| **keys** | Primary — `keys(obj)`, display, documentation | YAML/TOML specs use "keys"; target users expect it |
| **fields** | Alias — `isfield()`, `fieldnames()`, `rmfield()` | Maintains MATLAB struct compatibility |
| **properties** | Avoid in display | Conflicts with MATLAB OOP `properties()` |

**Decision:** "Keys" as primary terminology; "fields" supported as aliases for struct compatibility. See `Claude/DESIGN_DECISIONS.md`.

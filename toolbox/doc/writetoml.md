# writetoml

**Write data to TOML file**

The `writetoml` function writes MATLAB&reg; data to a TOML file with extensive formatting options to control output style.

## Syntax

```matlab
writetoml(data)
writetoml(data,filename)
writetoml(___,Name=Value)
```

## Description

`writetoml(data)` writes the MATLAB data to `untitled.toml` in the current directory.

`writetoml(data,filename)` writes to the specified file.

`writetoml(___,Name=Value)` specifies additional formatting options using name-value arguments.

## Input Arguments

### data
Data to write to file.
*Type:* [TOMLData](TOMLData.md), struct, dictionary, or containers.Map

### filename
Output file path.
*Type:* string scalar
*Default:* `"untitled.toml"`

### Name-Value Arguments

#### ArrayStyle
Style for arrays.
*Type:* `"flow"` or `"block"`
*Default:* `"flow"`

- `"flow"` - Use inline style as `[1, 2, 3]`
- `"block"` - Use multi-line style with one item per line

#### NumIndentationSpaces
Number of spaces for indentation.
*Type:* positive integer scalar
*Default:* `2`

#### SectionSpacing
Spacing between top-level tables.
*Type:* `"loose"` or `"compact"`
*Default:* `"loose"`

- `"loose"` - Blank line between each top-level table
- `"compact"` - No blank lines

#### Precision
Number of significant digits for numeric values.
*Type:* positive integer scalar
*Default:* `6`

#### TableStyle
Style for nested tables.
*Type:* `"auto"`, `"inline"`, or `"expanded"`
*Default:* `"auto"`

- `"auto"` - Use heuristics based on table size/complexity
- `"inline"` - Always use inline tables `{x = 1, y = 2}`
- `"expanded"` - Always use expanded `[table]` headers

#### TableArrayStyle
Style for arrays of tables.
*Type:* `"expanded"`, `"inline"`, or `"auto"`
*Default:* `"expanded"`

- `"expanded"` - Use `[[table]]` syntax (most common, readable)
- `"inline"` - Use inline array syntax `[{x=1}, {x=2}]`
- `"auto"` - Choose based on array size/complexity

#### StringEscapeStyle
String escape processing.
*Type:* `"auto"`, `"escaped"`, or `"literal"`
*Default:* `"auto"`

- `"auto"` - Choose escaped or literal automatically
- `"escaped"` - Use escape-processing (TOML basic strings)
- `"literal"` - Use literal strings (no escape processing)

#### StringLayout
String layout style.
*Type:* `"auto"`, `"singleline"`, or `"multiline"`
*Default:* `"auto"`

- `"auto"` - Choose single-line or multiline automatically
- `"singleline"` - Always use single-line strings
- `"multiline"` - Always use multiline delimiters

## Examples

### Write TOMLData to File

Create and write TOML configuration:

```matlab
% Create TOMLData
config = tomldata();
config.project.name = "my-package";
config.project.version = "1.0.0";
config.project.authors = ["Alice"; "Bob"];

% Write to file
writetoml(config,"pyproject.toml");
```

### Control Table Formatting

Choose between inline and expanded table styles:

```matlab
% Create nested configuration
data = tomldata();
data.database.connection.host = "localhost";
data.database.connection.port = 5432;
data.database.pool.size = 10;

% Expanded format (default) - uses [table] headers
writetoml(data,"config_expanded.toml");
% [database.connection]
% host = "localhost"
% port = 5432

% Inline format - compact
writetoml(data,"config_inline.toml",TableStyle="inline");
% database = {connection = {host = "localhost", port = 5432}, ...}
```

### Format Arrays and Spacing

Customize array style and spacing:

```matlab
% Create data with arrays
config = tomldata();
config.dependencies.packages = ["numpy"; "pandas"; "scipy"];
config.build.requires = ["setuptools"; "wheel"];

% Block arrays with compact spacing
writetoml(config,"requirements.toml", ...
    ArrayStyle="block", ...
    SectionSpacing="compact", ...
    NumIndentationSpaces=4);
```

### Write Python Project File

Create a pyproject.toml with proper formatting:

```matlab
project = tomldata();
project.("build-system").requires = ["setuptools>=61.0"; "wheel"];
project.("build-system").("build-backend") = "setuptools.build_meta";
project.project.name = "my-package";
project.project.version = "1.0.0";
project.project.dependencies = ["numpy>=1.20.0"; "pandas>=1.3.0"];

writetoml(project,"pyproject.toml", ...
    ArrayStyle="flow", ...
    SectionSpacing="loose");
```

For more examples, see [readtomlExample.m](../../examples/readtomlExample.m).

## Tips

- Pass structs or dictionaries directly: `writetoml(myStruct, "file.toml")`.
- Use `TableStyle="inline"` for small, simple tables to reduce file size.
- Use `ArrayStyle="block"` for long dependency lists to improve readability.
- Use `StringEscapeStyle="literal"` for Windows paths to avoid escape sequence issues.
- The `"auto"` settings generally produce good results; use explicit settings when you need consistent formatting.

## More About

### Data Type Conversions

MATLAB types are converted to TOML as follows:

**Numeric values:**
- Integers → TOML integers
- Floats → TOML floats
- Precision controlled by `Precision` option

**String scalars:**
- Converted to TOML strings
- Escape style controlled by `StringEscapeStyle`
- Layout controlled by `StringLayout`

**Logical values:**
- `true` → `true`
- `false` → `false`

**Datetime objects:**
- MATLAB `datetime` → TOML date-time format
- Preserves time zone information when available

**Structs and objects:**
- Converted to TOML tables
- Nested structs → nested tables
- Table style controlled by `TableStyle`

**Arrays:**
- Numeric/string arrays → TOML arrays
- Style controlled by `ArrayStyle`
- Arrays of structs → array of tables (controlled by `TableArrayStyle`)

### TOML Format Options

TOML supports multiple ways to represent the same data:

**Inline vs Expanded Tables:**
- Inline: `server = {host = "localhost", port = 8080}`
- Expanded:
  ```toml
  [server]
  host = "localhost"
  port = 8080
  ```

**Flow vs Block Arrays:**
- Flow: `ports = [8080, 8443, 9000]`
- Block:
  ```toml
  ports = [
      8080,
      8443,
      9000,
  ]
  ```

## See Also

[readtoml](readtoml.md), [writeyaml](writeyaml.md), [TOMLData](TOMLData.md), [datetime](https://www.mathworks.com/help/matlab/ref/datetime.html)

## Version History

- Introduced in 2025a

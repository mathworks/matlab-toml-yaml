# readtoml

**Read data from TOML file**

The `readtoml` function reads TOML configuration files and returns the data as a [TOMLData](TOMLData.md) object with dot notation access and support for special characters in field names.

## Syntax

```matlab
data = readtoml(filename)
data = readtoml(filename,Name=Value)
```

## Description

`data = readtoml(filename)` reads the TOML file specified by `filename` and returns the data as a [TOMLData](TOMLData.md) object. Dates and datetimes are automatically converted to MATLAB&reg; `datetime` objects.

`data = readtoml(filename,Name=Value)` specifies how to represent date and datetime values.

## Input Arguments

### filename
File path to read.
*Type:* string scalar
*Validation:* Must point to an existing file.

### Name-Value Arguments

#### DatetimeType
Controls how dates and datetimes are represented.
*Type:* `"datetime"` or `"string"`
*Default:* `"datetime"`

- `"datetime"` - Convert to MATLAB `datetime` objects
- `"string"` - Keep as string representations

## Output Arguments

### data
TOML data as a TOMLData object.
*Type:* [TOMLData](TOMLData.md)

[TOMLData](TOMLData.md) supports:
- Dot notation for key access: `data.field`
- Special character keys using dynamic field names: `data.("field-name")`
- Conversion to struct: `s = struct(data)`
- Methods: `keys`, `isfield`, `show`, `copy`

## Examples

### Basic TOML Reading

Read a TOML configuration file:

```matlab
% Create sample TOML file
tomlContent = [
    "[project]"
    "name = ""my-package"""
    "version = ""1.0.0"""
    "authors = [""Alice"", ""Bob""]"
    ""
    "[dependencies]"
    "numpy = "">=1.20.0"""];
writelines(tomlContent,"config.toml");

% Read the file
config = readtoml("config.toml");

% Access values using dot notation
name = config.project.name         % "my-package"
authors = config.project.authors   % ["Alice"; "Bob"]
```

### Access Keys with Special Characters

TOML commonly uses hyphens in keys:

```matlab
% TOML with special characters
tomlContent = [
    "[build-system]"
    "requires = [""setuptools"", ""wheel""]"
    "build-backend = ""setuptools.build_meta"""];
writelines(tomlContent,"pyproject.toml");

config = readtoml("pyproject.toml");

% Access using dynamic field names
backend = config.("build-system").("build-backend")  % "setuptools.build_meta"
```

### Working with Datetime Values

Control how dates are represented:

```matlab
% TOML with datetime
tomlContent = [
    "created = 2025-01-08T10:30:00Z"
    "updated = 2025-01-08"];
writelines(tomlContent,"timestamps.toml");

% Default - returns datetime objects
data1 = readtoml("timestamps.toml");
data1.created  % datetime: 08-Jan-2025 10:30:00

% As strings for custom parsing
data2 = readtoml("timestamps.toml",DatetimeType="string");
data2.created  % "2025-01-08T10:30:00Z"
```

For comprehensive examples including Python project files and nested tables, see [readtomlExample.m](../../examples/readtomlExample.m).

## Tips

- Use `DatetimeType="string"` when you need custom datetime parsing or want to preserve the original format.
- Access keys with special characters (hyphens, dots) using dynamic field names: `data.("field-name")`.
- Convert TOMLData to standard structs using `struct(data)` for compatibility with code expecting struct inputs.
- TOMLData is a value class. Assignment creates independent copies automatically.

## More About

### Type Conversions

TOML values are converted to MATLAB types as follows:

**Booleans:**
- `true` → `true`
- `false` → `false`

**Integers:**
- Automatically converted to numeric values
- Supports underscores for readability: `1_000_000` → `1000000`

**Floats:**
- Converted to double precision
- Supports scientific notation: `1.5e-3`

**Strings:**
- Basic strings (with escapes) → string scalars
- Literal strings (no escapes) → string scalars
- Multi-line strings supported

**Dates and Datetimes:**
- Local date-time: `2025-01-08T10:30:00`
- Offset date-time: `2025-01-08T10:30:00Z`
- Local date: `2025-01-08`
- Local time: `10:30:00`
- Conversion controlled by `DatetimeType` option

**Arrays:**
- Converted to MATLAB arrays (numeric, string, or cell)
- Homogeneous arrays → specialized arrays
- Heterogeneous arrays → cell arrays

**Tables:**
- Standard tables: `[table]`
- Inline tables: `{x = 1, y = 2}` → struct
- Array of tables: `[[array]]` → array of TOMLData objects

## Limitations

- Extremely large integers may lose precision due to MATLAB's double precision representation.
- Time zone information in offset date-times is preserved in `datetime` objects.

## See Also

[writetoml](writetoml.md), [readyaml](readyaml.md), [TOMLData](TOMLData.md), [datetime](https://www.mathworks.com/help/matlab/ref/datetime.html)

## Version History

- Introduced in 2025a

# Format Background

Configuration files store settings that control how software behaves. Unlike data files — which hold measurements, results, or records — config files are typically written and maintained by humans, and are read by software at startup or runtime. The format a project chooses reflects how it expects users to interact with those settings.

Several formats are in common use:

**JSON and XML** are general-purpose serialization formats designed primarily for computer-to-computer communication. They are machine-friendly: strict syntax, no ambiguity, and fast to parse. JSON intentionally omits comment support — it was designed as a data interchange format where comments have no role. Both formats work as config files, but they aren't very pleasant to read or write.

**TOML and YAML** were designed specifically for humans authoring config files. Quoting requirements are minimal. Structure reads naturally. Neither format is intended for high-volume data exchange — they optimize for clarity and editability over parsing performance. These are the formats this toolbox targets.

Regardless of syntax, both formats represent the same fundamental structure: **a hierarchy of named values**. A MATLAB struct is the right mental model. The top level is like a struct with named fields; each field holds a scalar value (a number, a string, or a boolean), an array, or a nested struct. Reading a config file loads that hierarchy from text; writing one serializes it back.

```matlab
% Think of a config file like a struct
config.debug            = false;                            % Scalar value
config.releases         = ["R2022b", "R2023a", "R2024a"];   % Array
config.database.host    = "localhost";                      % Nested struct
config.database.port    = 5432;
```

The interesting challenges arise at the edges of this mapping: YAML and TOML have naming conventions for their keys that don't align with MATLAB's identifier rules, and unlike MATLAB, they distinguish between scalars and arrays.

---

## YAML

[YAML](https://yaml.org/) (YAML Ain't Markup Language) is an indentation-based format widely used for CI/CD pipelines (GitHub Actions, GitLab CI), container orchestration (Docker Compose, Kubernetes), ML experiment frameworks (Hydra, Weights & Biases), and many other tools.

### Core concepts

**Key-value pairs**
```yaml
name: my-project
version: 1.0
debug: false
```
Most strings do not require quotes. Type is inferred from the value's appearance, e.g. `true`/`false` are Booleans while `"true"`/`"false"` are strings. 1.0 is a float, 5432 is an integer

**Mappings** — nested structure:
```yaml
database:
  host: localhost
  port: 5432
  name: mydb
```
Indentation defines nesting — `host`, `port`, and `name` are keys within `database`. There are no braces or explicit delimiters; whitespace is the structure. Indent any number of spaces (not tabs), just be consistent within a given block.

**Sequences** — lists (conceptually like 1-D arrays). YAML supports two styles: **Block** and **Flow**
```yaml
# Block style — each item on its own line, readable
releases:
  - R2022b
  - R2023a
  - R2024a

# Flow style — compact inline
releases: [R2022b, R2023a, R2024a]
```
Both are valid YAML and semantically identical. The choice is stylistic. Block is more readable for longer lists; flow is compact for short ones. The values in a sequence can be mixed types; no requirement for homogeneity.

**Comments:**
```yaml
# Database configuration
database:
  host: localhost  # override in production
```
Comments run to the end of the line. They are typically discarded by parsers and not preserved through a round-trip.

### Real-world example — GitHub Actions workflow fragment

```yaml
on:                                       # on is a mapping with key push
  push:                                   # push is a mapping with key branches
    branches: [main]                      # branches is a sequence of string scalars (flow style)

jobs:
  test:
    runs-on: ubuntu-latest                # runs-on is a scalar string.
    strategy:
      matrix:
        matlab: [R2022b, R2023a, R2024a]  # matlab is a sequence of string scalars
    steps:                                # steps is a sequence of mappings, each with keys 'name' and 'uses'
      - name: Set up MATLAB               # '-' begins a new mapping in the sequence
        uses: matlab-actions/setup-matlab@v2
      - name: Run tests                   # '-' begins the second mapping
        uses: matlab-actions/run-tests@v2
```

### Summary of YAML details we'll need to consider

**Key names with hyphens and special characters.** `runs-on` is a valid YAML key, but it is not a valid MATLAB variable name — the hyphen is syntactically ambiguous with subtraction. This is ubiquitous in real YAML: GitHub Actions uses `runs-on`, `pull-request`, `workflow-dispatch`; HTTP headers use `x-custom-header`, `content-type`.

**Scalar vs. single-element sequence.** YAML distinguishes `branches: main` (a scalar string) from `branches: [main]` (a one-element sequence). In MATLAB, `"main"` and `["main"]` are identical — there is no native way to represent this distinction. Users will need a way to explicitly distinguish.

**Indentation.** YAML uses indentation as syntax, not style. Two spaces is the most common convention; four spaces is also widely used. The exact amount is not specified by the format — any consistent indentation is valid. Users may want flexibility.

**Section spacing.** Blank lines between top-level sections significantly improve readability in longer config files. This is a common convention but not required by the format. Users may want flexibility to help write files that look familiar.

**Numeric precision.** Floating-point values can be written with varying precision: `1.2345678` vs `1.23`. The right choice depends on context — a measurement that must round-trip exactly needs full precision; a threshold set by a human benefits from a clean representation.

---

## TOML

[TOML](https://toml.io/) (Tom's Obvious, Minimal Language) was created by Tom Preston-Werner (GitHub co-founder) as a config format with unambiguous, explicitly typed values. It is used by `pyproject.toml` (Python project metadata), `Cargo.toml` (Rust packages), and many modern configuration systems. It will be used by `matlab.toml`, the forthcoming MATLAB project definition file.

### Core concepts

**Key-value pairs**
```toml
name = "my-project"
version = "1.0.0"
debug = false
port = 5432
pi = 3.14159
```
Strings must be quoted. Booleans are `true`/`false`. Integers and floats are unquoted. Unlike YAML, strings are always quoted.

**Tables** — nested structure. TOML supports two syntaxes **expanded** and **inline**:
```toml
# Expanded: [section] header, then key-value pairs below
[database]
host = "localhost"
port = 5432

# Inline: compact, written on one line
database = {host = "localhost", port = 5432}
```
Both are semantically equivalent. Expanded tables are the standard for top-level configuration sections; inline tables are used when the nested data is simple enough to read comfortably on one line.

**Arrays** — TOML supports both single line and multiline arrays:
```toml
# Single line — the standard style for most TOML arrays
releases = ["R2022b", "R2023a", "R2024a"]

# Multiline — for longer arrays
releases = [
  "R2022b",
  "R2023a",
  "R2024a",
]
```
The values in a sequence can be mixed types; no requirement for homogeneity.

**Array of tables** — repeated structured records, two syntaxes:
```toml
# Expanded [[double-bracket]] syntax — the standard, most readable
[[steps]]
name = "Set up MATLAB"
uses = "matlab-actions/setup-matlab@v2"

[[steps]]
name = "Run tests"
uses = "matlab-actions/run-tests@v2"

# Inline array syntax — compact alternative
steps = [
  {name = "Set up MATLAB", uses = "matlab-actions/setup-matlab@v2"},
  {name = "Run tests", uses = "matlab-actions/run-tests@v2"},
]
```
`[[double brackets]]` defines an array of tables — a list of records, each with the same set of keys. This is TOML's equivalent of what YAML expresses as a sequence of mappings. The expanded form is by far the most common in real TOML files.

**String types** — TOML has four:
```toml
# Basic string — supports escape sequences (\n, \t, \\ etc.)
message = "Hello\nWorld"
path = "C:\\Users\\name\\Documents"   # each backslash must be doubled

# Literal string — no escape processing; content taken verbatim
path = 'C:\Users\name\Documents'      # backslashes are literal

# Multiline basic string — for long text
description = """
This spans
multiple lines.
"""

# Multiline literal string — verbatim, multi-line
template = '''
{{variable}} syntax is not processed here
\n is two characters, not a newline
'''
```
The key practical distinction: **literal strings (single quotes) are the natural choice for Windows paths** because every `\` in a basic string must be written as `\\`. For most config values this doesn't arise; it matters whenever the value contains backslashes.

**Comments:**
```toml
# Project metadata
[project]
name = "my-project"  # PEP 518 required field
```

### Real-world example — pyproject.toml fragment

```toml
[build-system]                             # build-system is a table with keys requires and build-backend
requires = ["hatchling"]                   # requires is an array of strings
build-backend = "hatchling.build"          # build-backend is a string scalar

[project]                                  # project is a table with 3 keys
name = "my-package"
version = "0.1.0"                          # string scalar — quoted, not a number
dependencies = ["numpy>=1.21", "scipy"]    # dependencies is an array of strings

[[project.authors]]                        # project.authors is an array of tables
name = "Jane Smith"
email = "jane@example.com"

[[project.authors]]                        # [[...]] begins the second table in the array
name = "John Doe"
email = "john@example.com"
```

### Summary of TOML details we'll need to consider

**Key and table names with hyphens.** `[build-system]` appears in essentially every `pyproject.toml`. Same challenge as YAML: `build-system` is not a valid MATLAB identifier.

**Multiple syntax options for the same structure.** Tables, arrays, and arrays of tables each have two syntactically distinct but semantically equivalent forms — expanded vs. inline. When generating TOML from MATLAB, choices must be made about which form to produce, and different users will have different preferences depending on context.

---

## YAML and TOML Summary

Both formats represent the same underlying structure — a hierarchy of named values — but use different terminology and syntax conventions. This table maps the core concepts across the two formats and into MATLAB.

### Concepts
| Concept | YAML term | TOML term | MATLAB equivalent |
|---------|-----------|-----------|-------------------|
| Named element | **Key** | **Key** | Field (struct), Key (dict), Property (class) |
| Ordered collection of key-value pairs | **Mapping** | **Table** | struct |
| Ordered list of values | **Sequence** | **Array** | array or cell array |
| Atomic value (number, string, boolean) | **Scalar** | **Value** | scalar (1-element array)|

### Syntax
| Concept | YAML term | TOML term | Closest MATLAB equivalent |
|---------|-----------|-----------|-------------------|
| Comments | `# text` | `# text` | `% text` |
| String quoting | Optional — most values unquoted | Required for all strings | Required (`"..."` or `'...'`) |
| Nesting syntax | Indentation | `[section]` header; dotted keys (`a.b`) | `.` dot notation |
| Inline nested structure | **Flow mapping**: `{key: val}` | **Inline table**: `{key = val}` | `s.key = val` |
| Inline list | **Flow sequence**: `[a, b, c]` | Array: `["a", "b", "c"]` | `[a b c]` or `{"a","b","c"}` |
| List of structured records (see below) | **Sequence** of **mappings** | **Array** of **tables** | struct array |


**YAML - Sequence of Mappings**
```yaml
# YAML — sequence of mappings (block style)
steps:
  - name: build
    cmd: make
  - name: test
    cmd: make test
```
**TOML - Array of Tables**
```toml
# TOML — array of tables
[[steps]]
name = "build"
cmd = "make"

[[steps]]
name = "test"
cmd = "make test"
```
**MATLAB - Struct Array**
```matlab
% MATLAB — struct array
steps(1).name = "build";  steps(1).cmd = "make";
steps(2).name = "test";   steps(2).cmd = "make test";
```


### Valid key/field names

| Rule | YAML| TOML | MATLAB |
|------|----------------|----------------|-------------------|
| Allowed characters | Most printable chars except space | `A-Za-z`, `0-9`, `-`, `_` | `A-Za-z`, `0-9`, `_` |
| Names with spaces | `"key with spaces"` | `"key with spaces"` | Not supported |
| Must start with letter | ✗ | ✗ | ✓ |

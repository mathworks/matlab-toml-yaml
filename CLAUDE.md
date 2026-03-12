# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MATLAB toolbox for reading/writing YAML, TOML, JSON, and INI configuration files with dot notation access. No external toolboxes required. Minimum MATLAB version: R2022b (for `dictionary` type with value semantics).

## Commands

### Run Tests
```matlab
% via MCP Server
run_matlab_test_file('tests/yamltest.m')
run_matlab_test_file('tests/tomltest.m')
run_matlab_test_file('tests/initest.m')
run_matlab_test_file('tests/jsontest.m')
run_matlab_test_file('tests/subsasgnTest.m')
run_matlab_test_file('tests/describeTest.m')
run_matlab_test_file('tests/configdataTest.m')
run_matlab_test_file('tests/ConfigurationPerformanceTest.m')
```

### Setup Path
```matlab
addpath('toolbox')
% Or openProject("ConfigurationFileIO.prj")
```

### Static Analysis
```matlab
% Via MCP server
mcp__matlab__check_matlab_code('toolbox/readyaml.m')
```

## Branching Strategy
All work must be done on a branch, not on main. Create a new branch for new work, or switch to an appropriate existing branch for refinement. 

## Code style
- Don't use ambiguous abbreviations like Arr or Ann in variable names, especially ones that are UpperCase or camelCase. When in doubt, spell out the word.

## Architecture

### Class Hierarchy
```
ConfigurationData (value class, base)
├── YAMLData
├── TOMLData
├── JSONData
└── INIData
```

ConfigurationData inherits from:
- `matlab.mixin.indexing.RedefinesDot` - custom dot notation
- `matlab.mixin.indexing.OverridesPublicDotMethodCall` - data keys take priority over methods
- `matlab.mixin.CustomDisplay` - custom disp/display

### Internal Storage (ConfigurationData)
All internal state is stored in a single `public Hidden` struct property named `xInternal__`:
- `xInternal__.Data` - dictionary<string, cell> storing values wrapped in cells
- `xInternal__.KeyAliases` - dictionary<string, string> mapping valid MATLAB names to original keys
- `xInternal__.OriginalKeys` - string array preserving insertion order
- `xInternal__.SourceFormat` - string identifying the file format ("yaml", "toml", "json", "ini")

This design uses one reserved key name to enable tab completion. See `Claude/TAB_COMPLETION_DESIGN.md`.

### I/O Pattern
Reader functions (`readyaml`, `readtoml`, `readjson`, `readini`) return subclass objects (YAMLData, TOMLData, etc.). Writer functions (`writeyaml`, `writetoml`, `writejson`, `writeini`) accept data objects or structs.

Format-neutral `ConfigurationData` objects (no source format) are created via the `configdata()` wrapper. Each subclass also has a wrapper: `yamldata()`, `tomldata()`, `jsondata()`, `inidata()`. These wrappers accept no args (empty), a struct, or a dictionary.

## Critical Design Decisions

### Method Calling Convention
Methods must use function syntax due to `OverridesPublicDotMethodCall`:
```matlab
% CORRECT
keys(config)
isfield(config, 'database')
show(config)

% WRONG - these access data keys, not methods
config.keys
config.isfield
config.show
```

This allows users to have data keys named "keys", "show", "isfield", etc.

### Value Class Semantics
ConfigurationData is a value class (not handle). Assignment creates independent copies:
```matlab
copy = original;  % copy is independent
copy.field = 'new';  % does not affect original
```

### Key Aliasing
Keys with special characters get valid MATLAB aliases:
```matlab
config.("build-system")  % original key with hyphens
config.build_system      % aliased name also works
```

### Nested Object Creation
Assigning to nested paths auto-creates intermediate objects preserving class type:
```matlab
config = YAMLData;
config.new.section.value = 42;  % creates nested YAMLData objects
```

### Accessing xInternal__ on Array Elements
`obj.xInternal__` works when `obj` is the direct `self` parameter (bypasses RedefinesDot). But `obj(j).xInternal__` on array elements goes through `dotReference` and is blocked. Inside methods that iterate over arrays, use the public API instead:
```matlab
% WRONG inside a method iterating obj array
obj(j).xInternal__.OriginalKeys

% CORRECT
keys(obj(j))
iskey(obj(j), key)
getData(obj(j), key)
```

### show() vs describe()
- `show(obj)` — value viewer; displays actual data. Format-specific subclasses emit native format (YAML/TOML/JSON/INI). Format-neutral `ConfigurationData` emits an indented tree with values and no type annotations. Arrays use ND-array style (`varname(i) =`).
- `describe(obj)` — schema inspector; shows key hierarchy with MATLAB types and sizes. Supports `Depth=N` limiting and returns a queryable table when called with an output argument.

### Missing Key Behavior (Issue #74)
Reading a missing key returns `missing` instead of erroring:
```matlab
events(3).sensor  % returns missing if events(3) has no "sensor" key
```

**Key properties:**
- The key is **not actually added** to the object — `iskey()` still returns false, `keys()` doesn't include it, `show()` and file writes omit it
- This is **read-only convenience** without side effects
- Enables direct filtering: `events(events.sensor == "temperature")` works even when some events lack "sensor"
- Works naturally for `double` and `string` types (most common in configs)
- Errors for integer/logical types (MATLAB can't concatenate `missing` with these)

**Use `iskey()` for authoritative key existence checks:**
```matlab
iskey(obj, "field")  % true only if key actually exists
obj.field            % returns missing if absent (read convenience)
```

## Key Files

| File | Purpose |
|------|---------|
| `toolbox/+matlab/+io/+config/ConfigurationData.m` | Base class with dot notation handling (~1,500 lines) |
| `toolbox/+matlab/+io/+config/YAMLData.m` | YAML subclass; `show()` prints YAML format |
| `toolbox/+matlab/+io/+config/TOMLData.m` | TOML subclass; `show()` prints TOML format |
| `toolbox/+matlab/+io/+config/JSONData.m` | JSON subclass; `show()` prints JSON format |
| `toolbox/+matlab/+io/+config/INIData.m` | INI subclass; `show()` prints INI format |
| `toolbox/readyaml.m` | YAML parser (~400 lines) |
| `toolbox/readtoml.m` | TOML parser (~1,250 lines, most complex) |
| `toolbox/writeyaml.m` | YAML writer with formatting options |
| `toolbox/writetoml.m` | TOML writer with formatting options |
| `toolbox/readjson.m` | JSON reader (wraps jsondecode) |
| `toolbox/writejson.m` | JSON writer (wraps jsonencode) |
| `Claude/DESIGN_DECISIONS.md` | Naming rationale and design philosophy |
| `Claude/ISSUE_14_RESERVED_NAMES.md` | Reserved name handling explanation |
| `Claude/TAB_COMPLETION_DESIGN.md` | Tab completion fix and xInternal__ rationale |
| `specs/` | Design specs and RFAs for features |

## Known Limitations

- **YAML**: No anchors/aliases, no multi-document, no literal/folded strings
- **TOML**: Array of tables reading has bugs (writing works)
- **JSON**: Designed for config files with usability focus; MATLAB's `5` and `[5]` are identical, so scalar vs array distinction is lossy by default
  - Use `SequenceRule='cell'` for strict round-trip preservation (all arrays become cells)
  - Use `ArrayKeys` parameter in `writejson` to force specific keys to be arrays (e.g., for API schemas)
  - For strict JSON round-tripping, use built-in `jsondecode`/`jsonencode`
- **Array indexing**: Cannot do `obj.field(i).subfield = value` directly; extract array first
- **Comments**: Not preserved during round-trip
- **Reserved key**: `xInternal__` cannot be used as a configuration key (reserved for internal storage)
- **Tab completion**: IDE shows data keys and methods together; methods require function syntax to call

## Test Files Location

Sample configuration files for testing are in `tests/SampleFiles/` (27+ real-world files including GitHub Actions workflows, Kubernetes manifests, pyproject.toml variants).

## Development Documentation

The `Claude/` folder contains 14 detailed design documents explaining implementation decisions, known issues, and architecture rationale.


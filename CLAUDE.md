# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## MATLAB Agentic Toolkit

This project uses the [MATLAB Agentic Toolkit](https://github.com/matlab/matlab-agentic-toolkit) for MATLAB skills (code authoring, testing, modernization, documentation) and the MATLAB MCP Server for code execution and static analysis. Install the toolkit for the full set of MATLAB skills rather than maintaining local copies.

## Project Overview

MATLAB toolbox for reading/writing YAML and TOML configuration files with dot notation access. No external toolboxes required. Minimum MATLAB version: R2022b (for `dictionary` type with value semantics).

## Commands

### Run Tests
```matlab
% via MCP Server
run_matlab_test_file('tests/yamltest.m')
run_matlab_test_file('tests/tomltest.m')
run_matlab_test_file('tests/subsasgnTest.m')
run_matlab_test_file('tests/ConfigurationPerformanceTest.m')
```

### Build Tasks
```matlab
buildtool           % runs default tasks: lint, test
buildtool indent    % auto-indent all .m files (uses indentcode)
buildtool lint      % report Code Analyzer issues
buildtool fixLint   % auto-fix Code Analyzer issues (R2023a+)
buildtool test      % run test suite with coverage
buildtool all       % indent, fixLint, test
```

### Setup Path
```matlab
addpath('toolbox')
% Or openProject("matlab-toml-yaml.prj")
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
ConfigurationData (abstract value class, @-folder)
├── YAMLData
└── TOMLData
```

ConfigurationData is decomposed into internal superclasses under `+internal/`:
- `ConfigurationStorage` — `Data` property, `resolveKey`, `traverse`, `tryConcatenate`, `normalizeVectorOrientation`
- `ConfigurationDotAccess` — `dotReference`, `dotAssign`, `dotListLength` (inherits `RedefinesDot` + `OverridesPublicDotMethodCall`)
- `ConfigurationDisplay` — `displayScalarObject`, `displayNonScalarObject`, `getHeader`, `compactRepresentationForSingleLine` (inherits `CustomDisplay`)
- `ConfigurationToType` — `struct`, `dictionary`, `keys`, `iskey`, `isfield`, `fieldnames`, `map`, `remove`, `rmfield`
- `TypeToConfigurationData` — `importFrom` (struct/dictionary/containers.Map → ConfigurationData)

### Internal Storage (ConfigurationData)
One protected property:
- `Data` — `dictionary<string, cell>` storing values wrapped in cells (insertion order preserved)

Key aliases (e.g. `build_system` → `build-system`) are computed on the fly in `resolveKey`. There are no reserved key names — users can have keys named "Data", etc.

### I/O Pattern
Reader functions (`readyaml`, `readtoml`) return subclass objects (YAMLData, TOMLData). Writer functions (`writeyaml`, `writetoml`) accept data objects or structs.

`ConfigurationData` is abstract. Subclass wrappers: `yamldata()`, `tomldata()`. These accept no args (empty), a struct, a dictionary, or a containers.Map.

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

This allows users to have data keys named "keys", "show", "isfield", etc. All public methods are Hidden to keep them out of tab completion.

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

### Accessing Protected Properties on Array Elements
`obj.Data` works when `obj` is the direct `self` parameter (bypasses RedefinesDot). But `obj(j).Data` on array elements goes through `dotReference` and treats "Data" as a user key. Inside methods that iterate over arrays, use the public API instead:
```matlab
% WRONG inside a method iterating obj array
obj(j).Data

% CORRECT
keys(obj(j))
iskey(obj(j), key)
```

### Missing Key Behavior on Arrays
When accessing a key on a non-scalar array, elements that lack the key return `missing` (coerced to `NaN` for doubles, `<missing>` for strings). The key is not added to the object.

```matlab
events = [yamldata(struct("sensor","temp","value",1)) yamldata(struct("value",2))];
events.sensor   % ["temp" <missing>]
events(events.sensor == "temp")  % filters correctly
```

Scalar access on a missing key errors (consistent with struct, dictionary, table, containers.Map). Integer/logical types error because MATLAB cannot concatenate `missing` with these types.

## Key Files

| File | Purpose |
|------|---------|
| `toolbox/+matlab/+io/+config/@ConfigurationData/` | Abstract base class (@-folder with `properties` override) |
| `toolbox/+matlab/+io/+config/+internal/` | Superclasses and shared utilities |
| `toolbox/+matlab/+io/+config/YAMLData.m` | YAML subclass; `show()` prints YAML format |
| `toolbox/+matlab/+io/+config/TOMLData.m` | TOML subclass; `show()` prints TOML format |
| `toolbox/readyaml.m` | YAML parser |
| `toolbox/readtoml.m` | TOML parser (most complex) |
| `toolbox/writeyaml.m` | YAML writer with formatting options |
| `toolbox/writetoml.m` | TOML writer with formatting options |
| `buildfile.m` | Build tasks (indent, lint, fixLint, test, mltbx) |
| `buildUtilities/` | Helpers for build tasks |

## Known Limitations

- **YAML**: No anchors/aliases, no multi-document, no literal/folded strings
- **Array indexing**: Cannot do `obj.field(i).subfield = value` directly; extract array first
- **Comments**: Not preserved during round-trip

## Test Files Location

Sample configuration files for testing are in `tests/SampleFiles/`.

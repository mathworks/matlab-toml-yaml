# Architectural Design

## Proposed Architectural Design: Summary

The toolbox uses a **value class hierarchy** with `dictionary`-based storage in the `matlab.io.config` namespace. The `ConfigurationData` base class implements dot notation access via `RedefinesDot` mixin and prioritizes data key access over method names via `OverridesPublicDotMethodCall`. Format-specific subclasses (`YAMLData`, `TOMLData`) handle format identification.

## Proposed Design: Details

### Architecture Description

#### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│          matlab.io.config.ConfigurationData (base)               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Properties:                                                  ││
│  │   xInternal__ (public Hidden struct):                        ││
│  │     .Data         dictionary (string → cell)                 ││
│  │     .KeyAliases   dictionary (string → string)               ││
│  │     .OriginalKeys string array (insertion order)             ││
│  │     .SourceFormat string ("yaml" | "toml")                   ││
│  └─────────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Mixins:                                                      ││
│  │   matlab.mixin.indexing.RedefinesDot (dot notation)         ││
│  │   matlab.mixin.indexing.OverridesPublicDotMethodCall         ││
│  │     (data keys take priority over method names)             ││
│  │   matlab.mixin.CustomDisplay (formatted display)            ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
            │                              │
  ┌─────────┴──────────┐        ┌──────────┴─────────┐
  │ matlab.io.config   │        │ matlab.io.config    │
  │    .YAMLData       │        │    .TOMLData        │
  │ SourceFormat="yaml"│        │ SourceFormat="toml" │
  └────────────────────┘        └────────────────────┘
            ↑                              ↑
      yamldata                      tomldata
  (informal wrapper)              (informal wrapper)
```

#### Value Semantics via dictionary

The critical architectural decision is using `dictionary` (introduced R2022b) instead of `containers.Map`:

| Aspect | containers.Map | dictionary |
|--------|---------------|------------|
| **Semantics** | Handle (reference) | Value (copy) |
| **Assignment** | `b = a` shares data | `b = a` copies data |
| **Modification** | `b.x = 1` affects `a` | `b.x = 1` does NOT affect `a` |
| **MATLAB Feel** | Confusing | Intuitive |

**Implementation Pattern:**
```matlab
% dictionary requires cell wrapper for heterogeneous values
obj.xInternal__.Data(key) = {value};              % Store
value = obj.xInternal__.Data(key){1};             % Retrieve
obj.xInternal__.Data = remove(obj.xInternal__.Data, key); % Remove
```

#### Consolidated Internal Storage: xInternal__

All internal state is stored in a single `public Hidden` struct property named `xInternal__`. This consolidation reduces the number of reserved key names from 4 to 1, minimizing conflicts with user configuration keys.

The name `xInternal__` is chosen to be maximally unlikely as a real configuration key:
- `x` prefix: uncommon in config key names
- `__` suffix: Python-style convention signaling internal use

The `public Hidden` visibility is required for MATLAB IDE tab completion: the IDE needs to see the property to enumerate completions, but users shouldn't see it in `disp` output or `properties()`. See `Claude/TAB_COMPLETION_DESIGN.md`.

#### Informal/Formal Interface Split

Following the `figure` → `matlab.ui.Figure` pattern:

```matlab
% For most users — informal interface, globally available
config = yamldata;                   % creates matlab.io.config.YAMLData
config = tomldata(myStruct);           % creates and populates from struct

% For developers building on top of the toolbox — formal interface
classdef MyAppConfig < matlab.io.config.YAMLData
isa(config, "matlab.io.config.ConfigurationData")  % type check
```

Class constructors are intentionally simple (no conversion logic). Conversion from struct or dictionary happens in the informal wrapper functions, keeping the class hierarchy clean and easy to subclass.

### Overview Document

See [DESIGN_DECISIONS.md](../Claude/DESIGN_DECISIONS.md) for detailed rationale on:
- Function naming (`read<type>` vs `<type>read`)
- Parameter naming (`SequenceRule` vs `ArrayFormat`)
- Terminology (keys vs fields vs properties)

### Non-Functional Requirements

#### Performance

- **Target:** Config files up to 1MB parsed in <1 second
- **Not optimized for:** Large data files, streaming, or memory-constrained environments
- **Bottlenecks:** String operations in parsers, regex matching in TOML

#### Compatibility

- **Minimum MATLAB Version:** R2022b (for `dictionary` and `configureDictionary`)
- **Tested Versions:** R2022b, R2023a, R2024a, R2024b
- **Platform:** Windows, macOS, Linux (pure MATLAB)

### Architecturally-Significant Design Cases

#### Case 1: Nested Object Access

The `RedefinesDot` mixin intercepts dot notation and routes through `dotReference` and `dotAssign`:

```matlab
config.database.host = "localhost";

% Internally:
% 1. dotAssign receives indexOp = ["database", "host"]
% 2. Checks if "database" exists, creates YAMLData if not (preserving class type)
% 3. Recursively assigns "host" = "localhost" to nested object
% 4. Writes modified nested object back (value semantics)
```

#### Case 2: Special Character Keys

Keys with hyphens create aliases:

```matlab
% YAML: build-system: ...
config.("build-system")  % Primary access — original key
config.build_system      % Alias via makeValidName — also works

% Implementation:
% KeyAliases("build_system") = "build-system"
% Both route to same Data entry
```

#### Case 3: Array Element Assignment (toml)

The `dotAssign` method handles chained indexing through array elements:

```matlab
% TOML [[users]] array of tables
data.users(2).name = "Suzie";           % Works
data.users(2).permissions.admin = true; % Works (chained)

% dotAssign detects Paren operation in indexOp chain,
% extracts array element, modifies it, writes back
```

### Design Rationale

| # | **Pros** | **Priority** |
|---|----------|--------------|
| 1 | Value semantics eliminate handle class confusion | HIGH |
| 2 | `dictionary` is native MATLAB type (R2022b+) | HIGH |
| 3 | `RedefinesDot` provides natural syntax | HIGH |
| 4 | Base class shares implementation across formats | MEDIUM |
| 5 | `matlab.io.config` namespace avoids global namespace pollution | HIGH |
| 6 | `OverridesPublicDotMethodCall` allows unrestricted configuration key names | HIGH |

| # | **Cons** | **Mitigation Plans** | **Priority** |
|---|----------|---------------------|--------------|
| 1 | Requires R2022b+ (dictionary) | Document requirement clearly | MEDIUM |
| 2 | Cell wrapper adds complexity | Encapsulate in base class methods | LOW |
| 3 | `obj.field.name` on ConfigurationData array not supported as CSL | Clear error with `arrayfun` workaround | LOW |

## Alternate Architecture Designs Considered

### Alternate Architecture 1: `containers.Map` vs `dictionary` for Internal Storage

**Decision:** Chose `dictionary` (R2022b+). Its value semantics enable the containing class to have intuitive value behavior without complex copy logic. `containers.Map` is a handle class and would propagate reference semantics to the containing value class.

---

### Alternate Architecture 2: `dynamicprops` Instead of `RedefinesDot`

**Description:** Use MATLAB's `dynamicprops` mixin to create dynamic properties at runtime.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | Cannot handle special characters — `addprop(obj, 'build-system')` fails | HIGH |
| 2 | Loses key ordering — `properties()` returns alphabetically sorted | HIGH |
| 3 | Heterogeneous arrays fail — `arr.email` errors if any element lacks `email` | HIGH |

**Decision:** Rejected. Special characters are essential for TOML/YAML (kebab-case keys like `build-system` are ubiquitous). See `Claude/DYNAMICPROPS_ANALYSIS.md`.

---

### Alternate Architecture 3: Struct with Metadata Wrapper

**Description:** Return structs with a thin wrapper for metadata only.

**Decision:** Rejected due to special character limitation.

---

### Alternate Architecture 4: Override `subsasgn` for Array Indexing

**Description:** To fix array indexing, override `subsasgn` instead of enhancing `dotAssign`.

| # | **Cons** | **Priority** |
|---|----------|--------------|
| 1 | `RedefinesDot` explicitly forbids `subsasgn` override | HIGH |
| 2 | Would conflict with mixin's internal implementation | HIGH |

**Decision:** Rejected. Fixed by enhancing `dotAssign` to handle `Paren` type in indexOp chain. See `Claude/ARRAY_INDEXING_LIMITATIONS.md`.

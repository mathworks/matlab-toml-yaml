# #15: Add JSON support to ConfigurationData

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-02-02  
**Labels:** enhancement  

## Description

JSON is a popular configuration file format. It is used in `package.json` files in NPM, for example.

It would be good to consider adding JSON support to round out the design.

## Comments

### Comment by michellehirsch on 2026-01-29

I think this is promising, but needs to be handled carefully. @aylindmello has identified use cases and requirements for JSON that will push significantly on the current design of TOMLData and YAMLData:
* JSON files can have much deeper structure
* JSON files can be much larger than typical TOML and YAML configuration data files
* Advanced JSON workflows may require higher fidelity of round-tripping than we plan to support here.



### Comment by michellehirsch on 2026-02-02

## Design Analysis: JSON Support for ConfigurationData

### Current Design Philosophy

The toolbox is built around "Pragmatic Mapping" - optimizing for **usability over perfect fidelity**. From the YAML scalar/array round-trip analysis:

> "Focus on the Use Case: Most users use this toolbox for Configuration Data... Accept that `[5]` -> `5` is a 'lossy' round trip for structure, but 'lossless' for data meaning in MATLAB context."

### Key Considerations

#### 1. Scale Difference

**Config files** (current target):
- `pyproject.toml`: ~50-200 lines
- GitHub workflow `.yaml`: ~100-500 lines

**JSON in the wild**:
- `package.json`: ~100 lines (config - fits well ✓)
- API responses: can be megabytes with thousands of keys
- MongoDB exports: arbitrarily large

The `dictionary<string, cell>` storage with cell-wrapping overhead may have performance implications for large files.

#### 2. Type Fidelity Issues

| JSON Type | MATLAB Mapping | Round-trip Issue |
|-----------|----------------|------------------|
| `null` | `[]` or `missing`? | Ambiguous - null vs absent key vs empty array |
| `[5]` | `5` | Loses array structure (same as YAML) |
| `1` vs `1.0` | `1` (double) | Integer/float distinction lost |
| `[1, "two", true]` | `{1, "two", true}` | Works via cell array |
| Large integers (>2^53) | `double` | Precision loss |

**Null is particularly problematic** - it's semantically meaningful in JSON ("explicitly no value") more often than in YAML.

#### 3. Value Proposition vs `jsondecode`

MATLAB already has `jsondecode`/`jsonencode`. What would `JSONData` add?

| Feature | jsondecode | JSONData |
|---------|------------|----------|
| Dot notation | Via struct | Native, convenient |
| Keys with `-` or `.` | Converts to `_` (lossy) | Aliased access preserves original |
| Nested modification | Verbose | `config.a.b.c = value` auto-creates |
| Consistent API | Different from YAML/TOML | Same as YAML/TOML |
| Large data perf | Better (native struct) | Overhead from wrapping |

### Design Options

#### Option A: Same approach as YAML/TOML (Recommended)

```matlab
config = readjson("package.json");
config.scripts.test = "npm run jest";
writejson(config, "package.json");
```

- Consistent API across all formats
- Covers config file use case well
- Same round-trip limitations as YAML
- Need explicit null handling design

#### Option B: Strict JSON types (wrapper classes)

```matlab
config.value = JSONNull();      % distinct from missing
config.ports = JSONArray([80]); % preserves array-ness
```

- Perfect round-trip fidelity
- But: "leaky abstraction", already rejected this approach for arrays in YAML design

#### Option C: Hybrid with strict mode

```matlab
config = readjson("config.json", "StrictTypes", true);
```

- Two code paths to maintain
- Confusing for users

### Null Handling Options

| Option | Example | Pros | Cons |
|--------|---------|------|------|
| `[]` (empty double) | `config.value = []` | Native, simple | Ambiguous |
| `missing` | `config.value = missing` | Native MATLAB (R2016b+), semantic "intentionally absent" | Primarily for string/categorical arrays |
| `matlab.io.config.Null` | Singleton class | Unambiguous, `isa()` checkable | Wrapper type (conflicts with philosophy) |
| Omit key on write | Key not present | Simple | Loses null vs absent distinction |

`missing` is interesting - it's MATLAB's native way to express "intentionally absent." However, standalone `missing` is technically a missing string scalar.

### Recommendation

1. **Scope clearly as "configuration JSON"** - `package.json`, `tsconfig.json`, VS Code settings, etc.
2. **Don't try to compete with `jsondecode`** for data interchange or large files
3. **Design null handling explicitly** - probably `[]` with a `"NullRule"` option (like `SequenceRule`)
4. **Document trade-offs** - users needing perfect fidelity should use `jsondecode` directly

The wrapper types approach (`JSONArray`, `JSONNull`, etc.) would conflict with the core design philosophy of "intuitive MATLAB types."

# #79: Preserve schema information as a first-class object (second output)

**State:** open
**Created:** 2026-02-27
**Labels:** enhancement, design, round-tripping

## Description

## Background

Current YAML/TOML round-tripping can lose schema information:
- Scalar vs. array distinction (MATLAB treats `5` and `[5]` identically)
- Intended array-ness for empty or single-element arrays
- Original nesting structure intentions
- Type hints that matter for serialization

This information is often critical for configuration files where schemas are strict (e.g., CI/CD configs, API specs).

## Proposal

Design a read/write workflow where schema information is preserved explicitly through a second output argument.

### API Design

```matlab
% Reading with schema capture
[data, schema] = readyaml('config.yaml');
[data, schema] = readtoml('config.toml');

% Writing with schema preservation
writeyaml(data, 'output.yaml', schema);
writetoml(data, 'output.toml', schema);
```

### Schema Object Requirements

The schema object should:
1. **Mirror the data hierarchy**: Same key structure as the data
2. **Capture type metadata**:
   - Scalar vs. array distinction
   - Array dimensions and intended shape
   - Empty array markers
   - Nesting depth and structure
3. **Be itself hierarchical**: Ideally represented as a YAML/TOML-like object for consistency
4. **Be optional**: If not provided to writer, fall back to current heuristics

### Example

```yaml
# Original YAML
ports: [8080]
tags: []
settings:
  timeout: 30
```

```matlab
% After reading
data.ports = 8080;           % Scalar in MATLAB
data.tags = [];              % Empty
data.settings.timeout = 30;

% Schema captures intent
schema.ports.type = 'array';
schema.ports.minLength = 1;
schema.tags.type = 'array';
schema.tags.minLength = 0;
schema.settings.timeout.type = 'scalar';

% Writing with schema preserves structure
writeyaml(data, 'out.yaml', schema);
% => ports: [8080]
% => tags: []
% => settings:
% =>   timeout: 30
```

## Design Questions

1. **Schema representation**:
   - Use a `SchemaData` class (similar to `ConfigurationData`)?
   - Use plain struct with metadata fields?
   - Use a separate schema format (JSON Schema, custom)?

2. **Granularity**: What level of detail should the schema capture?
   - Just array-ness?
   - Full type information (string vs. number)?
   - Validation rules?

3. **Default behavior**: When no schema is provided:
   - Use current heuristics (backward compatible)
   - Emit warning about potential schema loss?

4. **Automatic schema inference**: Should `readyaml` always return schema, or only on request?

5. **Schema editing**: Should users be able to modify the schema directly?

6. **Failure modes**: What happens when data and schema are inconsistent?
   - Validation errors?
   - Schema takes precedence?
   - Data takes precedence?

## Implementation Considerations

- Schema should be lightweight and not duplicate data
- Must handle nested objects and arrays of objects
- Should support partial schemas (only specify what matters)
- Consider performance impact of dual-output reading

## Related Issues

- #48: Fix JSON support for preserving scalar arrays
- #46: Fix JSON support for arbitrary keys
- #50: Preserve order of keys in round-trip read/write JSON
- #27: Arrays with 1 element do not round-trip through readyaml and writeyaml
- #70: Design question: format-specific types vs. generic hierarchical type

## Success Criteria

- Round-trip preservation: `readyaml` + `writeyaml` with schema produces byte-identical output
- User-friendly API that feels natural in MATLAB
- Minimal performance overhead when schema is not used
- Clear documentation of schema structure and usage

---

## Research & Design Exploration (2026-03-12)

### Research Conducted

Performed comprehensive analysis of:
1. **YAML 1.2 specification** - Core type system and distinctions
2. **TOML specification** - Type system and structural syntax variants
3. **Real-world sample files** - 21 files (7 YAML, 14 TOML) from `tests/SampleFiles/`

### Key Findings: What Information Gets Lost?

#### PRIMARY CONCERN: Arrayness (scalar vs sequence)

**Very common in real configs:**
- Single-element arrays: `branches: [main]` → `"main"` (scalar) in MATLAB
- Empty arrays: `tags: []` → `[]` (type ambiguous)
- Multi-element arrays: OK (2+ elements remain distinguishable)

**Examples from real files:**
- `tests/SampleFiles/github-actions-ci.yaml`: `branches: [main]` (CI trigger config)
- `tests/SampleFiles/kubernetes-deployment.yaml`: Multiple single-element port arrays
- `tests/SampleFiles/matlab.toml`: `shortcuts = [{name = "...", path = "..."}]`

**Impact:** HIGH - affects round-trip correctness for CI/CD configs, API schemas

#### SECONDARY CONCERNS

**1. TOML Structural Ambiguities**

TOML has multiple equivalent syntaxes that are semantically identical but syntactically different:

- **Array of inline tables vs array-of-tables:**
  ```toml
  # Array of inline tables
  shortcuts = [{name = "Edit", path = "..."}, {name = "Run", path = "..."}]

  # Array of tables (equivalent semantics)
  [[shortcuts]]
  name = "Edit"
  path = "..."

  [[shortcuts]]
  name = "Run"
  path = "..."
  ```
  After parsing to MATLAB struct array, original syntax is lost.

- **Nested tables under array elements:**
  ```toml
  [[jobs]]
  name = "build"

  [[jobs.steps]]  # Nested under jobs array
  name = "Checkout"

  [[jobs.steps]]
  name = "Build"
  ```
  Reconstruction is ambiguous: Is `jobs.steps` a field or a nested array-of-tables?

- **Dotted keys vs table headers:**
  ```toml
  client.version = "2.0"      # Dotted key
  [client.version]            # Equivalent table header (different syntax)
  ```

**Impact:** MEDIUM-HIGH for TOML - affects readability and maintainability of output

**2. YAML Flow vs Block Style**

YAML arrays can be written two ways:
```yaml
ports: [8080, 8443, 9000]   # Flow style (compact)

ports:                      # Block style (verbose)
  - 8080
  - 8443
  - 9000
```

Both parse identically in MATLAB. On write-back, style choice is arbitrary.

**Impact:** MEDIUM - affects formatting preferences but not semantics

**3. Type Distinctions (less critical)**

- Timestamps: YAML/TOML distinguish local vs offset datetime; MATLAB datetime doesn't
- Numeric types: `5` (int) vs `5.0` (float) both become double in MATLAB
- String encoding: TOML basic vs literal strings lose distinction

**Impact:** LOW-MEDIUM - rarely matters for typical config files

#### TERTIARY CONCERNS (rare in configs)

- YAML sets (`!!set`) - no direct MATLAB equivalent
- YAML ordered maps (`!!omap`) - modern systems treat all maps as ordered anyway
- YAML merge keys (`!!merge`) - advanced feature, rarely used
- YAML binary data (`!!binary`) - uncommon in config files

**Impact:** LOW - advanced features not common in real-world config files

### Terminology Decision: "Schema" May Be Wrong Term

**Observation:** We're not capturing validation rules or type constraints. We're capturing **presentation metadata** or **format hints** to preserve round-trip fidelity.

**Distinction:**
- **Schema (validation sense)**: "This field must be an integer between 1-100"
- **What we need**: "This field was written as `[5]` not `5`"

**Alternative terms to consider:**
- `FormatMetadata` - hints about original file format
- `PresentationHints` - how values should be presented
- `RoundTripData` - information needed for lossless round-trip
- `SerializationContext` - context for how to serialize back
- `StructuralHints` - hints about intended structure

**Impact of naming:** "Schema" might suggest to users they can validate data against it (like JSON Schema), which is a different use case. Need clear terminology.

### Design Decisions & Considerations

#### 1. Class Design

**Decision:** Create `matlab.io.config.ConfigurationDataSchema` (general, not YAML-specific)

**Rationale:**
- TOML has same arrayness issues as YAML
- TOML has additional structural ambiguities (array-of-tables syntax)
- JSON already has known issues (#48, #27, #50) that schema could address
- INI is simpler and probably doesn't need it, but won't be harmed
- Better to design general solution than format-specific

**Open question:** Should we rename to avoid "Schema" term? (see terminology discussion above)

#### 2. What to Capture

**Must capture (essential for correctness):**
- Sequence vs scalar distinction
- Empty array preservation

**Should capture (improves round-trip fidelity):**
- TOML: Array of inline tables vs array-of-tables syntax
- TOML: Dotted keys vs table headers
- YAML: Flow vs block style (nice-to-have)

**Could capture (lower priority):**
- Timestamp variants (local vs offset)
- Numeric type intent (int vs float representation)
- String encoding style (TOML literal vs basic)

**Proposed minimal schema vocabulary:**
```matlab
% Instead of generic "type", use format-specific terms
schema.ports.yamlKind = 'sequence';     % vs 'scalar'
schema.tags.yamlKind = 'sequence';

% Or even simpler - just mark sequences
schema.markSequence('ports');
schema.markSequence('tags');
% Everything not marked is assumed scalar
```

**Alternative - capture presentation explicitly:**
```matlab
schema.ports.presentation = 'array';    % Write as array even if scalar in MATLAB
schema.shortcuts.tomlStyle = 'array-of-tables';  % vs 'inline-tables'
schema.hosts.yamlStyle = 'flow';        % vs 'block'
```

**Open question:** What's the right level of abstraction? Format-agnostic or format-specific?

#### 3. Schema vs SequenceRule Parameter

**Current state:**
- `readyaml(..., 'SequenceRule', 'cell')` - blunt instrument, makes all arrays cells
- `readjson` has smart `extractArrayKeys()` to track original array context

**Proposed coexistence:**
- Keep `SequenceRule='cell'` for simple "preserve everything as arrays" use case
- Add schema for surgical, precise preservation
- No warning when schema not provided (backward compatible)

**Comparison:**
```matlab
% Simple approach - everything becomes cells
data = readyaml('config.yaml', 'SequenceRule', 'cell');
writeyaml(data, 'output.yaml');  % Arrays preserved but less ergonomic

% Precise approach - schema tracks what matters
[data, schema] = readyaml('config.yaml');
data.ports = 8080;  % Still a scalar for easy use
writeyaml(data, 'output.yaml', schema);  % Written as [8080]
```

**Decision:** Keep both options, let users choose based on their needs.

#### 4. nargout Behavior

**Decision:** Only create schema when requested (nargout == 2)

```matlab
data = readyaml('config.yaml');           % No schema overhead
[data, schema] = readyaml('config.yaml'); % Capture schema
```

**Rationale:** Performance optimization, no penalty for users who don't need schema

#### 5. Schema Editing & Data/Schema Sync

**Key insight:** Schema should mirror data structure using dot notation (like ConfigurationData)

**Proposed schema structure:**
```matlab
schema = ConfigurationDataSchema();
schema.ports = 'sequence';          % or struct with metadata
schema.tags = 'sequence';
schema.settings.timeout = 'scalar';

% Natural editing
schema.new_field = 'sequence';
rmfield(schema, 'old_field');
```

**Benefits:**
- Feels natural (same dot notation as data)
- Supports nested structures automatically
- Easily editable
- Allows partial schemas (missing keys = no hint, use heuristics)

**Sync utility concept:**
```matlab
schema = syncSchema(schema, data);
% Returns updated schema matching current data structure
% Warns about keys in schema but not in data
% Preserves metadata for keys that still exist
% New keys get 'unknown' or missing (user must set manually)
```

#### 6. Conflict Resolution: Data vs Schema Mismatch

**Scenario:** Schema says "array" but data is scalar

```matlab
[data, schema] = readyaml('config.yaml');  % ports: [8080]
data.ports = 8080;                         % User assigns scalar
writeyaml(data, 'output.yaml', schema);    % Conflict!
```

**Options:**
1. **Schema wins**: Write `ports: [8080]` (preserve original intent)
2. **Data wins**: Write `ports: 8080` (respect current state)
3. **Validate and error**: Throw error on mismatch
4. **Warn and use data**: Emit warning, write as scalar

**Proposed decision:** Schema wins (option 1)

**Rationale:**
- Schema represents user's original intent for file structure
- If user wants to change from array to scalar, they should update schema too
- Provides most predictable round-trip behavior
- If schema says "this is a sequence," that's authoritative

**Safety valve:** Provide `writeyaml(..., 'IgnoreSchema', true)` to override

**Open question:** Should we validate and warn, or silently use schema?

### Next Steps

Before implementation:

1. **Finalize terminology** - Schema vs FormatMetadata vs PresentationHints?
2. **Define schema vocabulary** - What fields/properties should schema objects have?
3. **Prototype schema class** - Try dot notation approach with ConfigurationDataSchema
4. **Test with real files** - Verify approach works with github-actions-ci.yaml, matlab.toml
5. **Design conflict resolution** - Firm up what happens when data and schema disagree
6. **Consider TOML structural hints** - How to capture array-of-tables vs inline syntax?

### Open Questions for Discussion

1. **Terminology:** Keep "Schema" or use "FormatMetadata" / "PresentationHints"?
2. **Scope:** Start with YAML-only or design for YAML+TOML together?
3. **Vocabulary:** Format-agnostic ('array' vs 'scalar') or format-specific ('sequence' vs 'scalar', 'array-of-tables')?
4. **TOML structural hints:** Worth capturing array-of-tables vs inline syntax? Or just focus on arrayness?
5. **Schema class design:** Inherit from ConfigurationData or separate class hierarchy?
6. **Validation:** Should schema provide validation capabilities, or purely presentation hints?

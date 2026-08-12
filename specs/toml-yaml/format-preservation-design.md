# Format Preservation Design Specification

**Status:** Draft
**Created:** 2026-03-13
**Related Issues:** #79, #27, #48, #50

## Executive Summary

This spec proposes a comprehensive format preservation system for YAML and TOML round-tripping. The system captures both semantic information (arrayness) and presentation preferences (style choices) through a `ConfigurationDataFormat` object returned as a second output from readers and consumed by writers.

**Philosophy:** Extend, don't replace. The system maintains existing "automatic behavior first" defaults while enabling power users to achieve byte-for-byte preservation through an opt-in format object.

## Problem Statement

### Current Limitations

MATLAB's semantic representation loses information during round-tripping:

1. **Arrayness (PRIMARY):** Single-element arrays become scalars (`[8080]` → `8080`)
2. **Empty arrays:** Type ambiguous (`[]` could be any type)
3. **TOML structural syntax:** Array-of-tables vs inline tables distinction lost
4. **Presentation style:** YAML flow vs block, TOML string encoding choices

### User Impact

- **90% of users:** Semantic round-tripping is sufficient (current behavior)
- **10% of users:** Need precise format preservation for:
  - CI/CD configs (GitHub Actions, Kubernetes)
  - API schemas with strict requirements
  - Configs checked into version control
  - Tools that validate exact syntax

## Design Philosophy

From existing documentation (TOMLWRITE_FORMAT_OPTIONS.md, YAML_SCALAR_ARRAY_ROUNDTRIP.md):

1. **Automatic behavior first** - defaults to 'auto' with smart heuristics
2. **Usability over perfection** - pragmatic MATLAB mappings
3. **Backward compatible** - existing code continues to work
4. **Opt-in precision** - format object enables exact round-tripping when needed

## Proposed Solution

### API Overview

```matlab
% Reading with format capture
[data, format] = readyaml('config.yaml');
[data, format] = readtoml('config.toml');

% Writing with format preservation
writeyaml(data, 'output.yaml', format);
writetoml(data, 'output.toml', format);

% Backward compatible - existing API unchanged
data = readyaml('config.yaml');
writeyaml(data, 'output.yaml', 'ArrayStyle', 'flow');
```

### ConfigurationDataFormat Class Hierarchy

```matlab
% Base class (format-agnostic)
ConfigurationDataFormat
    % Common properties (global, file-wide)
    - NumIndentationSpaces = 2
    - SectionSpacing = 'loose' | 'compact'
    - Precision = 6
    - ArrayStyle = 'auto' | 'flow' | 'block'

    % Per-key overrides (stored as nested structure)
    - Keys (mirrors data structure using dot notation)

    % Methods
    - markSequence(keypath)           % Mark as array/sequence
    - setArrayStyle(keypath, style)   % Override style for specific key
    - syncWithData(data)              % Align format with current data structure
    - show()                          % Display format settings

% YAML-specific subclass
YAMLDataFormat < ConfigurationDataFormat
    % No additional global properties (YAML is simpler)

    % Per-key properties:
    % - isSequence (bool)
    % - arrayStyle ('flow' | 'block')

% TOML-specific subclass
TOMLDataFormat < ConfigurationDataFormat
    % Additional global properties
    - TableStyle = 'auto' | 'inline' | 'expanded'
    - TableArrayStyle = 'auto' | 'inline' | 'expanded'
    - StringEscapeStyle = 'auto' | 'escaped' | 'literal'
    - StringLayout = 'auto' | 'singleline' | 'multiline'

    % Per-key properties:
    % - isSequence (bool)
    % - arrayStyle ('flow' | 'block' | 'auto')
    % - tableStyle ('inline' | 'expanded' | 'auto')
    % - tableArrayStyle ('inline' | 'expanded' | 'auto')
    % - stringEscapeStyle ('escaped' | 'literal' | 'auto')
    % - stringLayout ('singleline' | 'multiline' | 'auto')
```

## Format Preservation Levels

### Level 1: Global Format Settings (File-wide)

Applied to entire file unless overridden per-key:

```matlab
% Common to YAML and TOML
format.NumIndentationSpaces = 2;
format.SectionSpacing = 'loose';  % or 'compact'
format.Precision = 6;
format.ArrayStyle = 'auto';       % or 'flow', 'block'

% TOML-specific (ignored by YAML writers)
format.TableStyle = 'auto';
format.StringEscapeStyle = 'auto';
format.StringLayout = 'auto';
```

### Level 2: Per-Key Overrides (Hierarchical)

Format mirrors data structure using dot notation:

```matlab
% Mark arrayness (semantic - essential for correctness)
format.branches.isSequence = true;  % Was [main] not "main"
format.tags.isSequence = true;      % Was [] not missing

% Override formatting for specific keys (presentation)
format.shortcuts.tableArrayStyle = 'inline';  % Use [{}, {}] not [[table]]
format.hosts.arrayStyle = 'flow';             % Use [a, b, c] not block
format.description.stringLayout = 'multiline'; % Use """ """ for string

% Nested overrides follow data structure
format.server.ports.arrayStyle = 'block';
format.server.paths.stringEscapeStyle = 'literal';  % Windows paths
```

### Level 3: What Gets Captured During Read

When calling `[data, format] = readyaml('config.yaml')`:

**Always captured (essential for correctness):**
- Which keys were sequences (even if single-element or empty)
- Global indentation, spacing, precision detected from file

**Optionally captured (for style preservation):**
- Array presentation style (flow vs block) for each key
- TOML: Table style (inline vs expanded) for each table
- TOML: Table array style for each array of tables
- String encoding choices (escaped vs literal)

**Never captured (too granular or unknowable):**
- Comment locations and content
- Blank line positions (except coarse SectionSpacing)
- Key ordering (already preserved by ConfigurationData.xInternal__.OriginalKeys)
- Quote style for unambiguous strings

## Mapping to Existing Writer Parameters

### Current writeyaml Parameters (4 options)

| Parameter | Type | Default | Maps to |
|-----------|------|---------|---------|
| ArrayStyle | 'block' \| 'flow' | 'block' | format.ArrayStyle |
| NumIndentationSpaces | integer | 2 | format.NumIndentationSpaces |
| SectionSpacing | 'compact' \| 'loose' | 'loose' | format.SectionSpacing |
| Precision | integer | 6 | format.Precision |

### Current writetoml Parameters (8 options)

| Parameter | Type | Default | Maps to |
|-----------|------|---------|---------|
| ArrayStyle | 'auto' \| 'flow' \| 'block' | 'auto' | format.ArrayStyle |
| NumIndentationSpaces | integer | 2 | format.NumIndentationSpaces |
| SectionSpacing | 'compact' \| 'loose' | 'loose' | format.SectionSpacing |
| Precision | integer | 6 | format.Precision |
| TableStyle | 'auto' \| 'inline' \| 'expanded' | 'auto' | format.TableStyle |
| TableArrayStyle | 'auto' \| 'inline' \| 'expanded' | 'auto' | format.TableArrayStyle |
| StringEscapeStyle | 'auto' \| 'escaped' \| 'literal' | 'auto' | format.StringEscapeStyle |
| StringLayout | 'auto' \| 'singleline' \| 'multiline' | 'auto' | format.StringLayout |

**Note:** writetoml has richer options (8 vs 4) because TOML has more syntax variants.

## Design Questions & Decisions

### 1. Format Parameter Integration

**Question:** Should format parameter be optional 3rd arg or replace existing options?

**Decision:** Additive (backward compatible)

```matlab
% Option A: Current API still works (CHOSEN)
writeyaml(data, 'out.yaml', 'ArrayStyle', 'flow');
writeyaml(data, 'out.yaml', format);  % New format object API

% Conflict resolution: format object takes precedence if provided
writeyaml(data, 'out.yaml', format, 'ArrayStyle', 'block');  % format wins
```

**Rationale:**
- Maintains backward compatibility
- No breaking changes to existing code
- Clear precedence rule (format object > name-value pairs)

### 2. Capture Granularity

**Question:** How much detail should format capture?

**Decision:** Minimal by default, with option for complete

```matlab
% Minimal (default) - only captures deviations from 'auto'
[data, format] = readyaml('config.yaml');

% Complete - captures every formatting decision
[data, format] = readyaml('config.yaml', 'CaptureFormat', 'complete');
```

**Rationale:**
- Lightweight default (better performance)
- Power users can opt into complete capture
- Minimal capture still achieves correct round-tripping for most files

### 3. Format/Data Conflict Resolution

**Question:** What happens when format says "sequence" but data is scalar?

**Scenario:**
```matlab
[data, format] = readyaml('config.yaml');  % ports: [8080]
data.ports = 8080;  % User changes to scalar
writeyaml(data, 'out.yaml', format);  % Conflict!
```

**Decision:** Format wins (preserves intent)

```matlab
% Result: writes ports: [8080] even though data.ports is scalar
writeyaml(data, 'out.yaml', format);

% Safety valve: ignore format if needed
writeyaml(data, 'out.yaml', format, 'IgnoreFormat', true);
```

**Rationale:**
- Format represents user's original intent for file structure
- Most predictable round-trip behavior
- If user wants scalar, they should update format too
- Escape hatch available for exceptional cases

**Open question:** Should we validate and warn, or silently apply format?

### 4. Terminology

**Question:** "Schema" vs other terms?

**Current placeholder:** `ConfigurationDataFormat`

**Alternatives considered:**
- `ConfigurationDataSchema` - might imply validation (like JSON Schema)
- `FormatMetadata` - accurate but technical
- `PresentationHints` - clear but verbose
- `RoundTripData` - describes purpose but awkward
- `SerializationContext` - technical but precise

**Decision:** Use `ConfigurationDataFormat` pending further discussion

**Rationale:**
- "Format" clearly relates to file formatting
- Distinguishes from validation/schema systems
- Natural pairing with ConfigurationData
- Consistent with existing PRISM naming (MixedCase)

**Open:** Revisit after prototyping to see what feels natural in practice.

### 5. Scope (YAML vs TOML)

**Question:** Design for YAML-only or both together?

**Decision:** Design for both YAML and TOML together

**Rationale:**
- Both formats have arrayness issues
- TOML has additional structural ambiguities
- Shared base class avoids duplication
- Format-specific subclasses handle differences
- JSON and INI can adopt later if needed

**Implication:** Need specialized subtypes (YAMLDataFormat, TOMLDataFormat)

### 6. Format-Agnostic vs Format-Specific Vocabulary

**Question:** Should properties use generic terms or format-specific terms?

**Examples:**
```matlab
% Format-agnostic (shared vocabulary)
format.ports.isSequence = true;      % Both YAML and TOML
format.ports.arrayStyle = 'flow';    % Both understand

% Format-specific (different vocabulary)
format.ports.yamlKind = 'sequence';  % YAML term
format.shortcuts.tomlStyle = 'array-of-tables';  % TOML term
```

**Decision:** Use format-agnostic vocabulary where possible, format-specific when needed

**Rationale:**
- Common concepts (arrayness, flow style) share vocabulary
- Format-unique concepts (array-of-tables) use format-specific properties
- Base class provides common interface
- Subclasses extend with format-specific properties

**Properties:**
- **Common (base class):** isSequence, arrayStyle, NumIndentationSpaces
- **TOML-specific (subclass):** tableArrayStyle, stringEscapeStyle
- **YAML-specific (subclass):** None currently (YAML is simpler)

## Implementation Considerations

### Performance Impact

**When format not used (90% of users):**
- Zero overhead: `data = readyaml('file.yaml')` unchanged
- No format object created unless `nargout == 2`

**When format used (10% of users):**
- Minimal overhead during read: track style decisions already made
- No overhead during write: format guides decisions already needed
- Memory: format object much smaller than data (only metadata)

### Partial Format Support

Format objects support partial specifications:

```matlab
format = YAMLDataFormat();
format.branches.isSequence = true;  % Only specify this key

writeyaml(data, 'out.yaml', format);
% - branches written as sequence (format specified)
% - other keys use 'auto' heuristics (format not specified)
```

**Rationale:** Users often only care about specific keys, not entire file structure.

### Format Editing & Sync Utility

Users can edit format objects using dot notation:

```matlab
% Edit format
format.new_field.isSequence = true;
format.old_field = [];  % Remove

% Sync with data structure
format = syncWithData(format, data);
% - Warns about keys in format but not in data
% - Preserves metadata for keys that still exist
% - Returns updated format object
```

### Format Persistence

Format objects can be saved/loaded:

```matlab
% Save format separately
save('config_format.mat', 'format');

% Or embed in data object (future enhancement)
data.xInternal__.Format = format;  % Not in initial implementation
```

## Examples

### Example 1: GitHub Actions CI (arrayness preservation)

**Input file (github-actions-ci.yaml):**
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

**Round-trip without format:**
```matlab
data = readyaml('ci.yaml');
% data.on.push.branches = "main" (scalar!)

writeyaml(data, 'out.yaml');
% Result: branches: main  (WRONG - breaks CI trigger)
```

**Round-trip with format:**
```matlab
[data, format] = readyaml('ci.yaml');
% data.on.push.branches = "main" (scalar in MATLAB)
% format.on.push.branches.isSequence = true (captured)

writeyaml(data, 'out.yaml', format);
% Result: branches: [main]  (CORRECT - preserves array)
```

### Example 2: TOML Array-of-Tables Style

**Input file (matlab.toml):**
```toml
[project]
shortcuts = [
    {name = "Edit", path = "edit.m"},
    {name = "Run", path = "run.m"}
]
```

**Round-trip with format:**
```matlab
[data, format] = readtoml('matlab.toml');
% data.project.shortcuts(1).name = "Edit"
% format.project.shortcuts.tableArrayStyle = 'inline'

writetoml(data, 'out.toml', format);
% Result: shortcuts = [{name = "Edit", ...}, {name = "Run", ...}]
% (preserves inline style, not [[shortcuts]] syntax)
```

### Example 3: Mixed Flow and Block Styles (YAML)

**Input file:**
```yaml
server:
  ports: [8080, 8443, 9000]  # Flow style
  hosts:                      # Block style
    - alpha
    - beta
    - gamma
```

**Round-trip with format:**
```matlab
[data, format] = readyaml('server.yaml');
% format.server.ports.arrayStyle = 'flow'
% format.server.hosts.arrayStyle = 'block'

writeyaml(data, 'out.yaml', format);
% Result: preserves flow for ports, block for hosts
```

### Example 4: User Editing Format

**Scenario: User wants to change style after reading:**
```matlab
[data, format] = readyaml('config.yaml');

% Change from block to flow for specific key
format.settings.timeouts.arrayStyle = 'flow';

% Mark new key as sequence
format.new_section.tags.isSequence = true;

writeyaml(data, 'out.yaml', format);
```

## Open Questions

### High Priority

1. **Validation strategy:** Silent format application vs warn on conflicts?
2. **Capture defaults:** What's "minimal" vs "complete" capture exactly?
3. **Sync utility design:** When/how should users call syncWithData()?
4. **Error messages:** How to communicate format/data mismatches clearly?

### Medium Priority

5. **Format class hierarchy:** Should YAMLDataFormat inherit from base or be standalone?
6. **Format persistence:** Should format be embeddable in data objects?
7. **Interoperability:** Can TOMLDataFormat be used with writeyaml (error or ignore)?
8. **Format display:** What should show(format) output look like?

### Low Priority

9. **Format composition:** Should users be able to merge format objects?
10. **Format templates:** Pre-defined formats for common styles (e.g., "kubernetes", "github-actions")?
11. **Format validation:** Should format objects validate their own consistency?
12. **Format versioning:** How to handle format object evolution?

## Related Work

### Existing Systems

- **SequenceRule parameter:** Blunt instrument (all arrays → cells)
- **ArrayKeys parameter (JSON):** Explicitly mark array keys
- **extractArrayKeys() (readjson):** Tracks original array context

### Related Issues

- #27: Arrays with 1 element do not round-trip through readyaml and writeyaml
- #48: Fix JSON support for preserving scalar arrays
- #50: Preserve order of keys in round-trip read/write JSON
- #70: Design question: format-specific types vs. generic hierarchical type

## Success Criteria

1. **Correctness:** Round-trip `[data, format] = read*(); write*(data, format)` produces semantically identical output
2. **Precision:** With format object, preserve arrayness, style choices, and TOML structural syntax
3. **Usability:** Format objects feel natural in MATLAB (dot notation, show(), editing)
4. **Performance:** Zero overhead when format not used
5. **Compatibility:** Existing code works unchanged
6. **Documentation:** Clear examples for common use cases

## Next Steps

1. **Prototype base class** - Create ConfigurationDataFormat with core methods
2. **Prototype subclasses** - YAMLDataFormat and TOMLDataFormat
3. **Test with sample files** - Verify round-tripping with github-actions-ci.yaml, matlab.toml
4. **Design capture logic** - How readers populate format objects
5. **Design application logic** - How writers consume format objects
6. **Create test suite** - Comprehensive round-trip tests
7. **Write documentation** - User guide and examples

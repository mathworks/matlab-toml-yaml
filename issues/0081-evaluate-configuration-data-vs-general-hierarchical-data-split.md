# #81: Evaluate configuration data vs general hierarchical data split

**State:** open
**Created:** 2026-02-27
**Labels:** design, architecture

## Description

## Background

There's a fundamental design tension in this project:

1. **Specialized perspective**: This is a YAML/TOML/JSON/INI file I/O toolbox with format-specific types
2. **General perspective**: This is a hierarchical data container that happens to have file I/O capabilities

Issue #70 explored the format-specific vs. unified type question. This issue asks a broader question: **Should we split the general hierarchical data container from the configuration file formats?**

## The Core Question

Should we have:

### Option A: Current Design (Unified)
- `ConfigurationData` is the base class
- `YAMLData`, `TOMLData`, etc. inherit from it
- All hierarchical data functionality lives in `ConfigurationData`
- File formats are the primary entry point

### Option B: Split Design
- `HierarchicalData` (or `VariantRecord`) — general-purpose hierarchical data container
  - No file format association
  - Pure in-memory data structure
  - Used independently of YAML/TOML/JSON/INI
- `ConfigurationData` inherits from `HierarchicalData`
  - Adds file format metadata (`SourceFormat`)
  - Used by file I/O functions
- `YAMLData`, `TOMLData`, etc. inherit from `ConfigurationData`
  - Format-specific serialization behavior

### Option C: Separate Types Entirely
- `HierarchicalData` — standalone, no connection to file formats
- `YAMLData`, `TOMLData`, etc. — completely independent, optimized for their formats
- No shared base class beyond MATLAB built-ins
- Users choose explicitly which type they want

## Analysis Dimensions

### 1. User Mental Model
- **Option A**: "I'm working with configuration files"
  - Clear if you only care about YAML/TOML/JSON/INI
  - Unclear if you want general hierarchical data without file I/O
- **Option B**: "I'm working with hierarchical data that may or may not come from files"
  - Separates concerns clearly
  - May be confusing if most users only care about config files
- **Option C**: "These are unrelated tools for different purposes"
  - Simplest conceptually but duplicates code
  - Users may be confused about which to use

### 2. Round-Tripping and Schema Fidelity
- **Option A**: Format information is baked into the type
  - Good: `YAMLData` knows how to serialize back to YAML
  - Bad: Can't represent "generic hierarchical data" cleanly
- **Option B**: Format is metadata on a generic container
  - Good: Separation of concerns
  - Bad: Schema/format preservation becomes more complex
- **Option C**: Each format optimized independently
  - Good: No compromises for format-specific needs
  - Bad: Hard to convert between formats

### 3. Discoverability and Naming
- **Option A**: Users discover via `readyaml`, `YAMLData`, etc.
  - Natural for file-focused workflows
  - Hierarchical data use case is hidden
- **Option B**: Two entry points: `HierarchicalData()` for in-memory, `readyaml()` for files
  - Clearer separation but more to learn
  - Risk of "which one do I use?" confusion
- **Option C**: Completely separate documentation and discovery paths
  - Easiest to document but duplicates discovery burden

### 4. Risk of Over-Abstraction vs Fragmentation
- **Option A**:
  - Risk: `ConfigurationData` becomes a Swiss Army knife with too many responsibilities
  - Risk: Format-specific types don't pull their weight (see #70)
- **Option B**:
  - Risk: Over-abstraction — too many layers of inheritance
  - Risk: Users misuse types (e.g., using `HierarchicalData` when they should use `YAMLData`)
- **Option C**:
  - Risk: Fragmentation — multiple similar but incompatible types
  - Risk: Code duplication and maintenance burden

## Questions to Resolve

1. **Is there a strong use case for hierarchical data independent of file formats?**
   - In-memory config objects constructed programmatically?
   - API response parsing?
   - Generic tree/graph data structures?

2. **Do the format-specific types provide enough value to justify their existence?** (see #70)

3. **Should round-trip fidelity be a first-class concern?** (see #79)
   - If yes, format types are more justified
   - If no, generic types are sufficient

4. **What's the primary user workflow?**
   - Read config → modify → write back: suggests format-specific types
   - Build config programmatically → serialize: suggests generic types
   - Both equally common: suggests split design

5. **How do we avoid "12 table-like types" fragmentation?**
   - Is `HierarchicalData` distinct enough from `struct`, `dictionary`, `table`?
   - Does splitting create more types to learn, or clarify the landscape?

## Prior Art

- MATLAB `struct` — generic, no file format association
- Python `dict` vs. `json.loads()` — generic data structure vs. format-specific parsing
- JSON libraries that return generic objects vs. preserving type info
- TOML libraries: some return generic dicts, others have custom types

## Related Issues

- #70: Format-specific types vs. single generic hierarchical type
- #79: Schema preservation as first-class object
- #5: Convert to value class and use dictionary instead of containers.Map
- #28: Consider alternate approach to naming functions and classes

## Decision Criteria

To resolve this, we need clear answers to:

1. **Primary use case weighting**: What % of users care about:
   - File I/O only (reading/writing YAML/TOML/JSON)
   - In-memory hierarchical data manipulation
   - Round-trip fidelity and schema preservation
   - Interoperability between formats

2. **Complexity budget**: How many types can users reasonably keep in their mental model?

3. **Maintenance cost**: Which design minimizes code duplication and maximizes reusability?

4. **Future extensibility**: As new formats are added (XML, HOCON, etc.), does the design scale?

## Recommendation (TBD)

This issue should be resolved through:
- User research / feedback on primary workflows
- Analysis of existing usage patterns (if any)
- Prototype implementations of Option B to assess complexity
- Clear documentation of tradeoffs for stakeholders

**Do not implement** until this design question is thoroughly explored and decided.

## Success Criteria for Resolution

- Clear understanding of primary user workflows
- Concrete examples showing where each option succeeds/fails
- Decision documented with rationale
- Migration path defined if design changes
- Updated documentation reflecting the chosen approach

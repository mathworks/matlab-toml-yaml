# #70: Design question: format-specific types vs. a single generic hierarchical type

**State:** open  
**Created:** 2026-02-20  
**Labels:** design  

## Description

## Background

This issue captures an open design question raised in discussion: should this toolbox expose **format-specific types** (`YAMLData`, `TOMLData`, `JSONData`, `INIData`) as its primary abstraction, or should it expose (or additionally expose) a **single generic type** that is format-agnostic?

The concern, drawing on previous design discussions about avoiding "12 different table-like things," is:

> "Do we really want six different kinds of hierarchical data objects that are ever so slightly different and that you can't pass around between workflows?"

There's also a naming question: if most of the useful behavior is shared, **why is the type called `YAMLData` rather than `HierarchicalData`** or `ConfigurationData`?

---

## What's Already Implemented

The current design uses a **hybrid**: a shared `ConfigurationData` base class with format-specific subclasses. This was explicitly chosen over alternatives (separate format classes with no base, plain structs, `containers.Map`, raw `dictionary`) to reduce duplication and give users a unified interface.

The key question is whether the **format-specific subclasses are pulling their weight**, or whether the public API should be `ConfigurationData` (or renamed to something like `HierarchicalData`) with format only surfacing in the I/O functions.

---

## What Actually Differs Between the Subclasses

Examining the implementations reveals that the subclasses are more similar than different:

| Aspect | YAMLData | TOMLData | JSONData | INIData |
|--------|----------|----------|----------|---------|
| Unique method | `show()` → YAML text | `show()` → TOML text | `show()` → JSON text | `show()` → INI text |
| Type-handling override | None | **Yes** — preserves native `datetime` | None | None |
| Structural constraint | None | None | None | **2-level max** (silently enforced during write) |
| Datetime behavior | Convert to ISO string | Keep as `datetime` object | Convert to ISO string | Convert to ISO string |
| Primary character | Cosmetic | **Semantic** (type fidelity) | Cosmetic | **Structural** |

**Key insight:** `TOMLData` is the most meaningfully distinct — it overrides type validation to preserve native `datetime` objects, because TOML has native datetime support. `YAMLData` and `JSONData` are nearly interchangeable at the class level; all meaningful format differences live in the reader/writer functions. `INIData` enforces a 2-level structural constraint during serialization.

---

## The Core Design Tension

### Arguments for format-specific subclasses

- **Round-trip identity**: `readyaml` → `YAMLData` → `writeyaml` makes the write path obvious without extra arguments.
- **Nested object type preservation**: `config.new.section = value` auto-creates nested objects of the same type. Without a format-specific type, what type do they get?
- **Type safety**: `isa(obj, 'YAMLData')` lets code assert what format it's working with.
- **Format-specific semantics**: TOML's datetime preservation, INI's structural limit — these are real, meaningful differences.
- **Discovery**: Users reading docs or tab-completing naturally find `YAMLData` associated with YAML workflows.

### Arguments against (or for a more generic alternative)

- **Most behavior is shared**: Three of four subclasses have no unique type handling. The format-specific behavior lives almost entirely in the reader/writer functions, not the data objects.
- **Interoperability friction**: You can't pass a `YAMLData` to a function that expects `TOMLData` even if the data is structurally identical. Generic processing code must use `ConfigurationData` as the type.
- **Naming mismatch**: A file that happens to be read from YAML is not intrinsically "YAML data" — once it's in memory it's just hierarchical key-value data.
- **Proliferation concern**: As more formats are added (XML? HOCON? dotenv?), the type list grows. Users must learn which types are compatible.
- **Previous guidance**: Avoid many table-like types with subtle differences that can't be passed between workflows.

---

## Design Questions to Resolve

1. **Should the public-facing primary type be `ConfigurationData` (or renamed `HierarchicalData`), with format as metadata?**
   - In this model, `readyaml` returns `ConfigurationData` with `SourceFormat = "yaml"`, and `writeyaml(data)` uses that metadata to write back.
   - Pro: One type to learn, easy interoperability.
   - Con: Loses type-level format identity; nested object creation is ambiguous.

2. **Should format-specific subclasses exist but be implementation details?**
   - Users work with `ConfigurationData`; `YAMLData` etc. are internal to the I/O functions.
   - Requires documenting that `isa(obj, 'YAMLData')` is not a supported check.

3. **Is `TOMLData`'s datetime distinction important enough to keep?**
   - This is the most concrete semantic difference. If we collapse to one type, datetime behavior must be handled another way (e.g., explicit option, metadata flag).

4. **What happens with nested object creation in a single-type design?**
   - `config.new.section = 42` currently creates a nested `YAMLData`. In a single-type world, does it create `ConfigurationData`? Does `show()` need to know the format?

5. **Should we release `ConfigurationData` (or `HierarchicalData`) as a standalone, separately from the file I/O?**
   - There's a broader use case for an in-memory hierarchical data object that isn't tied to file formats at all.

---

## Prior Art / Related Discussions

- `specs/architectural-design.md`: Format-specific subclasses chosen for format metadata and extensibility.
- `specs/functional-design.md`: Documents YAML vs. TOML API differences (reader/writer options).
- `Claude/DESIGN_DECISIONS.md`: Explicit rationale for the hybrid base+subclass architecture.
- `Claude/JSON_TYPE_HIERARCHY_ANALYSIS.md` and `Claude/JSON_UNIFIED_TYPE_EXPLORATION.md`: Already analyzed the "unified type" question for JSON specifically; concluded against full unification for the primary config-file use case.
- `Claude/ISSUE_19_TYPE_RESTRICTIONS.md`: Type validation strategy (early vs. late).


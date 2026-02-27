# #77: Normalize YAML array orientation to avoid horzcat/vertcat issues

**State:** open
**Created:** 2026-02-27
**Labels:** design, enhancement

## Description

## Background

Working with YAML arrays in MATLAB can lead to unexpected orientation mismatches when concatenating or extracting arrays. Currently, the internal representation does not enforce a consistent orientation convention, which can cause `horzcat`/`vertcat` issues when users manipulate array-valued keys.

## Problem Statement

When YAML arrays are converted to MATLAB arrays, their orientation (row vs. column) can be inconsistent, leading to:
- Concatenation errors when combining arrays
- Unexpected transpose operations
- Confusion about whether extracted values are rows or columns
- Downstream code that must defensively reshape or transpose

## Proposal

Redesign the internal representation to establish a consistent orientation convention:

1. **Define a clear orientation rule**: Choose one of:
   - YAML data objects are column-oriented; contained values are row-oriented
   - YAML data objects are row-oriented; contained values are column-oriented
   - All YAML arrays are internally stored as column vectors (or row vectors)

2. **Treat YAML arrays as 1-D conceptually**: YAML sequences map to 1-D MATLAB arrays with a fixed orientation, avoiding ambiguity.

3. **Document the convention clearly**: Users should understand the orientation contract to write robust code.

## Design Questions

- Should this convention apply to all formats (TOML, JSON, INI) or just YAML?
- How does this interact with nested arrays or arrays of objects?
- Should users have an option to override the default orientation?
- What happens when round-tripping through `readyaml`/`writeyaml`?

## Tradeoffs

| Approach | Pros | Cons |
|----------|------|------|
| Column-oriented (like MATLAB convention) | Natural for matrix operations; consistent with MATLAB default | May surprise users expecting row vectors |
| Row-oriented (like sequence notation) | Matches typical YAML sequence syntax | Differs from MATLAB's column-major convention |
| User-configurable | Flexibility for different workflows | Introduces inconsistency across codebases |

## Success Criteria

- No unexpected `horzcat`/`vertcat` errors when working with YAML arrays
- Clear documentation of orientation convention
- Consistent behavior across nested structures
- Minimal breaking changes to existing code

## Related Issues

- See `Claude/DESIGN_DECISIONS.md` for architectural philosophy
- May relate to array-of-tables handling in TOML (#2)

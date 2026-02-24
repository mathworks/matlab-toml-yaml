# #27: Arrays with 1 element do not round-trip through readyaml and writeyaml

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-29  

## Description

There is an ambiguity in the design between single-element arrays and scalar objects:

```
>> type out.yaml

A:
  - B: 5

>> config = readyaml("out.yaml");
>> writeyaml(config, "out2.yaml")

>> type out2.yaml

A:
  B: 5
```

This is actually a big issue for `jsonencode`/`jsondecode` users, and a significant pain point that `jsonTree` was trying to address. A lot of schema validators treat array-with-1-element and a scalar object differently, unlike in MATLAB where a scalar struct and a struct array with 1 element are conceptually the same. JSON/webread users would jsondecode a REST API response, modify it, and then jsonencode it in `webwrite`, but get a schema validation error from the server since the array-ness was dropped.

## Comments

### Comment by michellehirsch on 2026-01-29

## Fixed in this commit

This issue has been resolved by implementing `SequenceRule='cell'` support for strict round-tripping.

### Solution

Use `SequenceRule='cell'` when you need to preserve array structure:

```matlab
% Read with cell mode - preserves single-element arrays
config = readyaml('out.yaml', 'SequenceRule', 'cell');

% Access elements using cell indexing
config.A{1}.B  % Returns 5

% Write back - array structure is preserved
writeyaml(config, 'out2.yaml');
% Output:
% A:
%   - B: 5
```

### Changes Made

1. **readyaml.m**: Modified to respect `SequenceRule='cell'` for arrays of ConfigurationData objects (not just scalar arrays). Previously, object arrays were always converted to MATLAB object arrays regardless of the SequenceRule setting.

2. **ConfigurationData.m**: Added `Brace` indexing support in `dotReference` to properly handle chained cell indexing like `config.A{1}.B`. This was causing `config.A{1}` to return the wrong type when accessed directly.

### Trade-offs (as documented in Claude/YAML_SCALAR_ARRAY_ROUNDTRIP.md)

- **Default mode (`SequenceRule='auto'`)**: Optimized for usability. Single-element arrays are converted to scalars for natural MATLAB operations (`config.port + 1` works). This is lossy for structure but lossless for data.

- **Strict mode (`SequenceRule='cell'`)**: Preserves array structure for round-tripping. Use this when schema validation matters (REST APIs, etc.). Requires cell indexing (`config.port{1}`).

### Test Results

All existing tests pass (34 YAML tests, 16 subsassign tests), plus new round-trip scenarios verified.

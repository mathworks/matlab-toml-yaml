# #2: struct() fails on ConfigurationData with arrays of tables

**State:** closed  
**Created:** 2026-01-14  
**Closed:** 2026-01-14  
**Labels:** bug  

## Description

## Bug Description

Calling `struct()` on a `TOMLData` or `YAMLData` object fails when the data contains arrays of tables (e.g., `[[users]]` in TOML).

## Steps to Reproduce

```matlab
t = readtoml("tests/SampleFiles/array_of_tables.toml");
struct(t)
```

## Error

```
Error using ConfigurationData/struct (line 75)
Too many input arguments.

Error in ConfigurationData/struct (line 80)
```

## Expected Behavior

`struct(t)` should return a standard MATLAB struct representation of the data, recursively converting nested `ConfigurationData` objects and arrays.

## Root Cause

The `struct` method in `ConfigurationData.m` doesn't handle the case where a value is an array of `ConfigurationData` objects. When it encounters an array like `t.users` (which is `[1×3 TOMLData]`), the recursive call fails.

## Affected Files

- `toolbox/ConfigurationData.m`, `struct` method (lines 70-85)

# #72: Wildcard key search for ConfigurationData

**State:** open  
**Created:** 2026-02-20  
**Labels:** enhancement  

## Description

## Summary

Add a way to search/filter keys by pattern, enabling use cases like "find all fields that start with `Run1`" and then index into the object to get them.

This was deferred from the `feature/general-hierarchical-data` branch pending spec work.

## Motivating example

```matlab
config = readyaml("experiment.yaml");
% config has keys: Run1_accuracy, Run1_loss, Run2_accuracy, Run2_loss, ...

% Want to extract all Run1 fields:
run1Keys = ???(config, "Run1*");   % ["Run1_accuracy", "Run1_loss"]
run1Data = select(config, run1Keys);
```

## Open design questions

1. **Pattern type**: Accept MATLAB `wildcardPattern` / `regexp` objects? Basic glob strings (`"Run*"`)? Both?
2. **Search scope**: Top-level keys only, or recursive into nested objects?
3. **Return type**: String array of matching key names (composable with `select()`), or a projected sub-object directly?
4. **API name**: `keysmatch`, `findkeys`, `searchkeys`? (avoid `grep` — shadows MATLAB's grep-like builtins)

## Proposed direction (needs validation)

A function `keysmatch(obj, pattern)` returning a string array of matching canonical key names seems most composable:

```matlab
run1Keys = keysmatch(config, "Run1*");   % string array
run1Data = select(config, run1Keys);     % project to sub-object
```

This keeps search and projection separate, letting users iterate over matching keys too.

## Related

- `select(obj, keys)` — already implemented, composes naturally with a key search function
- `keys(obj)` — already returns all top-level canonical key names; a `keysmatch` could be a thin filter on top


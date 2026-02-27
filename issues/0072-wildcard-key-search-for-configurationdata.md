# #72: Wildcard key search for ConfigurationData

**State:** open
**Created:** 2026-02-20
**Updated:** 2026-02-26
**Labels:** enhancement

## Status

✅ **Spec complete** — see [specs/SearchCapabilities.md](../specs/SearchCapabilities.md)

This issue is now covered by the broader search capabilities spec in issue #71.

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

## Spec decisions

The [full spec](../specs/SearchCapabilities.md) addresses the open design questions:

1. **Pattern type**: Support wildcards (`*`) converted to `wildcardPattern`, with optional support for `pattern` objects and function handles
2. **Search scope**: Recursive by default, with `Recursive=false` option for top-level only
3. **Return type**: String array of dot-notation paths (composable with `select()`)
4. **API name**: `findkeys` (clearer intent than `keysmatch` or `searchkeys`)

## Proposed API (from spec)

```matlab
paths = findkeys(obj, pattern)
paths = findkeys(obj, pattern, Name=Value)

% Examples:
run1Keys = findkeys(config, "Run1*");   % wildcard pattern
run1Data = select(config, run1Keys);     % compose with select()

% Case-insensitive, partial matching
dbKeys = findkeys(config, "database", IgnoreCase=true, MatchType="partial");
```

## Related

- [#71: Add search capabilities](0071-add-search-capabilities.md) — parent issue with full spec
- [specs/SearchCapabilities.md](../specs/SearchCapabilities.md) — complete specification
- `select(obj, keys)` — composes naturally with `findkeys()` output
- `keys(obj)` — returns all top-level keys; `findkeys()` filters and recurses


# #71: Add search capabilities

**State:** open
**Created:** 2026-02-20
**Updated:** 2026-02-26
**Labels:** enhancement

## Status

✅ **Spec complete** — see [specs/SearchCapabilities.md](../specs/SearchCapabilities.md)

## Description

When you've got a bunch of data buried in hierarchy, it sometimes can be hard to know where something lives. It could be convenient to search to find where a key lives, or exactly what it's called. It might also be convenient to search on values - at least text ones? I'm pretty sure we don't want to get into numeric searching, like data above a certain value, etc.

## Spec summary

The spec proposes a `findkeys(obj, pattern)` function that:
- Searches recursively through nested ConfigurationData
- Supports wildcard patterns (`"Run1*"`, `"*database*"`)
- Returns string array of dot-notation paths
- Composes with `select()` and `getData()`
- Includes optional `findvalues()` for value-based search (Phase 2)

**Example:**
```matlab
% Find all keys containing "port"
paths = findkeys(config, "*port*");
% → ["server.admin.port", "database.port"]

% Extract matching subset
subset = select(config, paths);
```

## Related

- [#72: Wildcard key search](0072-wildcard-key-search-for-configurationdata.md) — overlapping scope, addressed by same spec
- [specs/SearchCapabilities.md](../specs/SearchCapabilities.md) — full specification

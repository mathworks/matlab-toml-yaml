# #74: Design question: should arr.field return missing for elements that lack the key?

**State:** open  
**Created:** 2026-02-23  
**Labels:** enhancement  

## Description

## The Question

Currently, accessing a field via dot notation on a `ConfigurationData` array errors if any element in the array lacks that key:

```matlab
events(events.sensor == "temperature")  % errors — start/error events have no "sensor" key
```

The proposal: when not all elements have a key, return a typed array where absent elements are represented as `missing` (for strings/categoricals) or `NaN` (for numerics) rather than erroring.

## Motivating Example

The current two-step pattern for filtering heterogeneous arrays by key value:

```matlab
hasSensor = iskey(events, "sensor");
eventsWithSensor = events(hasSensor);
tempReadings = eventsWithSensor(eventsWithSensor.sensor == "temperature");
```

With `missing`-return semantics, this collapses to one step:

```matlab
tempReadings = events(events.sensor == "temperature");
% missing == "temperature" is false, so non-sensor events drop out naturally
```

This is exactly how MATLAB tables handle missing values — `missing == "something"` is `false`, so heterogeneous comparisons compose cleanly without guards. The `iskey` step becomes optional rather than mandatory for filtering.

## Revised Design: `missing` as Universal Placeholder

Rather than deciding between `missing` vs `NaN` based on the type of the present values, we can use `missing` as a universal placeholder for absent elements in every case, and defer coercion to MATLAB's concatenation rules. This is both simpler to implement and more principled.

MATLAB's behavior when concatenating `missing` with typed arrays:

| Type | `[val, missing, val]` result |
|------|------------------------------|
| `double` / `single` | Works — `missing` coerces to `NaN` |
| `string` | Works — `missing` stays as `missing` |
| `int8`…`int64`, `uint*` | **Errors** — "Conversion to int32 from missing is not possible" |
| `logical` | **Errors** |
| `char` | Errors, but `tryConcatenate` already converts `char`→`string` first, so this is fine |
| all absent | Returns `missing` array of class `missing` |

This means the approach works naturally for `double` and `string` — the two most common config value types. Integer and logical fields require special-cased error messages.

## Implementation Sketch

Two methods need changes:

**`dotReference`** (non-scalar branch, currently lines ~489–494): remove the early error when `~all(hasKey)`. Instead, build the `values` cell array with `missing` in slots where the element lacks the key, then proceed to `tryConcatenate` as normal.

**`tryConcatenate`**: currently uses `unique(cellfun(@class, values))` to enforce type homogeneity — `missing` would appear as its own type and trigger a false mismatch. Changes needed:
- Strip `missing` entries when determining the dominant type
- If dominant type is `double`, `single`, or `string` (or `char`, already converted): proceed — MATLAB handles coercion automatically in `[values{:}]`
- If dominant type is integer or logical: error with a helpful message (e.g., "field has missing values in some elements; integer and logical types cannot represent missing — use `arrayfun` or `iskey` to pre-filter")
- If all values are `missing`: return a `missing` array

## Arguments For

- **One-step filtering** for the common case of "filter array by the value of an optional field" — no `iskey` guard needed
- **Consistent with MATLAB table semantics** — tables return `NaN`/`missing` for empty cells; the same pattern is already familiar
- **Composable** — `missing` propagates correctly through `==`, `~=`, `<`, `>`, `mean` (with `omitnan`), `sort`, etc.
- **Simpler design** — no need to inspect types before deciding which placeholder to use; `missing` is always the placeholder, and MATLAB's concatenation handles the rest
- **No compatibility concerns** — not yet released, so current error behavior is not a commitment

## Arguments Against

- **Silent masking of bugs**: the current error is informative. If a user writes `events.sensor` expecting all events to have a sensor, the error tells them their assumption is wrong. With `missing`-return, the wrong assumption produces a silently empty result instead.
- **Type ambiguity for heterogeneous values**: what type should `arr.field` return when elements have different types for that key (e.g., some have a string, some have a double)? The `missing` approach doesn't resolve this — mixed non-missing types still error in `tryConcatenate`.
- **Integer/logical fields**: the approach degrades to an error for these types, meaning behavior is inconsistent across field types.
- **`iskey` remains necessary anyway** for other operations (writing, not just reading), so the pattern doesn't disappear — it just becomes optional for this one case.

## Possible Middle Ground

Rather than changing the default, add an explicit opt-in:

```matlab
arr.field              % current behavior: errors if any element lacks the field
safeGet(arr, "field")  % new function: returns missing/NaN for absent elements
```

This preserves the strict default while making the safe access pattern available without the two-step `iskey` guard. Users who want permissive access opt in explicitly.

## Related

- `iskey(arr, field)` — already vectorized, already the standard guard pattern
- Issue #72 — wildcard key search (composing `iskey` results with `select`)

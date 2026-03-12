# #74: Design question: should arr.field return missing for elements that lack the key?

**State:** close  
**Created:** 2026-02-23  
**Labels:** enhancement  

## Description

## The Design

**Proposed Behavior:**
- **Reading a missing key returns `missing`** (no error) — enables convenient filtering and comparison
- **But the key isn't actually added** — `keys()`, `iskey()`, `show()`, and file writes still reflect reality
- This is a **read-only convenience layer**, not a data model change

Currently, accessing a field via dot notation on a `ConfigurationData` array errors if any element in the array lacks that key:

```matlab
events(events.sensor == "temperature")  % errors — start/error events have no "sensor" key
```

**The proposal:** when an element lacks a key, return `missing` for that element rather than erroring. This makes `missing` a read-only placeholder that doesn't alter the underlying object structure.

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

## Key Example: Updating Values in Heterogeneous Arrays

The most compelling case is updating values back into the original array. Consider scaling all temperature readings by 1.1x:

**Current approach (6 lines with complex index mapping):**
```matlab
hasSensor = iskey(events, "sensor");
sensorIndices = find(hasSensor);  % Track indices of original array with key "sensor"
eventsWithSensor = events(hasSensor);
tempMask = eventsWithSensor.sensor == "temperature";
tempIndices = sensorIndices(tempMask);  % Map back to original indices
events(tempIndices).value = events(tempIndices).value * 1.1;
```

**Proposed approach (2 lines with direct boolean indexing):**
```matlab
tempMask = events.sensor == "temperature";  % [true false false false true]
events(tempMask).value = events(tempMask).value * 1.1;
```

Or as a compact 1-liner:
```matlab
events(events.sensor == "temperature").value = events(events.sensor == "temperature").value * 1.1;
```

The current approach requires complex index gymnastics: extract indices, filter the subarray, map the filtered indices back to the original array. With `missing`-return semantics, you can use boolean masks directly throughout.

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

## Critical Design Property: Keys Aren't Actually Added

When `arr(i).field` returns `missing` for an element that lacks the key, the object's internal state is **not modified**:

```matlab
% Given: events(3) has no "sensor" key
value = events(3).sensor;           % returns: missing
iskey(events(3), "sensor")          % returns: false
keys(events(3))                     % returns: ["type", "message", "timestamp"] (no "sensor")
show(events(3))                     % displays: only type, message, timestamp
writeyaml("out.yml", events(3))     % writes: only type, message, timestamp (no sensor field)
```

This is **read-only convenience** without side effects. The `missing` value is computed on-the-fly during dot reference; it doesn't pollute the object with artificial keys.

**Contrast with assignment:**
```matlab
events(3).sensor = missing;         % DOES add the key with value missing
iskey(events(3), "sensor")          % now returns: true
writeyaml("out.yml", events(3))     % now writes: sensor field (with null/missing value)
```

Read and write are asymmetric by design — reading is permissive (returns `missing` for absent keys), but writing is explicit (adds the key if you assign to it).

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
  - *Mitigation:* Users can still validate with `iskey` or check for `missing` in results. The trade-off is convenience vs strictness — MATLAB tables make the same choice.
- **Type ambiguity for heterogeneous values**: what type should `arr.field` return when elements have different types for that key (e.g., some have a string, some have a double)? The `missing` approach doesn't resolve this — mixed non-missing types still error in `tryConcatenate`.
  - *Impact:* This is already an error today; `missing` handling doesn't change it.
- **Integer/logical fields**: the approach degrades to an error for these types, meaning behavior is inconsistent across field types.
  - *Impact:* Config files rarely use integer types (most use double). The error message can guide users to use `arrayfun` or pre-filter with `iskey`.
- **Learning curve**: Users need to understand that `arr.field` returning `missing` doesn't mean the key exists.
  - *Mitigation:* Documentation should emphasize the read-only nature and show `iskey` as the authoritative check.

## Decision: Implement as Default Behavior

After analysis, implementing `missing`-return as default behavior is the right choice:
- It aligns with MATLAB table semantics (familiar pattern)
- The code simplification is significant (see "Key Example" above)
- Keys aren't polluted with artificial `missing` values (read-only design)
- The behavior is composable and predictable

No middle-ground opt-in is needed — the behavior is intuitive once understood, and users who want strict validation can use `iskey` explicitly.

## Related

- `iskey(arr, field)` — already vectorized, already the standard guard pattern
- Issue #72 — wildcard key search (composing `iskey` results with `select`)

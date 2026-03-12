# Design Decision: Array Dot-Reference Behavior

**Date:** 2026-01-14 (original), 2026-02-05 (updated), 2026-03-12 (Issue #74 revision)
**Status:** Implemented - Return concatenated typed arrays; missing keys return `missing` (Issue #74)

---

## Context

When a user has an array of `ConfigurationData` objects and attempts to access a field on the entire array:

```matlab
data = readtoml("tests/SampleFiles/array_of_tables.toml");
data.products.name  % products is a 1x3 TOMLData array
```

MATLAB structs would return a comma-separated list: `[s(1).name, s(2).name, s(3).name]`.

The question: Should `ConfigurationData` support this behavior?

---

## Decision (Updated 2026-03-12 - Issue #74)

**Yes, with flexible missing-key handling.** Array dot reference returns concatenated typed arrays:

```matlab
data.products.name    % Returns: ["Hammer" "Nail" "Screwdriver"]
data.products.sku     % Returns: [738594937 284758393 847520193]
data.products.in_stock % Returns: [true true false]
```

**New behavior (Issue #74):** When some elements lack the requested key, `missing` is returned for those elements:

```matlab
% events(1), events(2), events(5) have "sensor" key
% events(3), events(4) do not
events.sensor  % Returns: ["temperature" "humidity" missing missing "temperature"]

% This enables direct filtering
tempReadings = events(events.sensor == "temperature")  % Works! missing == X is false
```

**Type requirements:** All **present** values must have the same type (can be concatenated). Type mismatch errors are thrown:
- Type mismatch: `"Types differ: element 1 is string, element 3 is double."`

---

## Behavior Summary

| Scenario | All Have Key? | Types Match? | Result |
|----------|--------------|--------------|--------|
| All strings | Yes | Yes | string array |
| All numbers | Yes | Yes | double array |
| All logical | Yes | Yes | logical array |
| All ConfigurationData | Yes | Yes | ConfigurationData array |
| Mixed types (present values) | Yes/No | No | **ERROR** |
| Missing in some (double/string) | No | Yes | **Array with `missing`** |
| Missing in some (integer/logical) | No | Yes | **ERROR** (cannot concatenate) |

---

## Design Decisions

### D1: Missing Keys - Return `missing` (Issue #74)

When elements lack the requested key, `missing` is returned for those elements (read-only convenience). This:
- Enables direct filtering without `iskey` guards: `arr(arr.sensor == "temp")`
- Aligns with MATLAB table semantics (tables return `missing` for empty cells)
- Does **not** add keys to objects — `iskey()` still returns false
- Works naturally for `double` and `string` (most common config types)
- Errors for integer/logical types (MATLAB cannot concatenate `missing` with these)

**Key properties:**
```matlab
events(3).sensor           % Returns: missing (if key absent)
iskey(events(3), "sensor") % Returns: false (key not actually added)
keys(events(3))            % Doesn't include "sensor"
```

Users who want strict validation can use `iskey`:
```matlab
if ~all(iskey(data.users, "email"))
    error("Not all users have email");
end
emails = data.users.email;
```

### D2: Type Mismatch - Error (Strict)

We require all values to have the same concatenatable type. This:
- Ensures predictable return types (no surprise cell arrays)
- Avoids code that needs to handle both typed arrays and cells
- Encourages clean data

Users can use `arrayfun` for heterogeneous data:
```matlab
values = arrayfun(@(x) x.value, arr, 'UniformOutput', false);
```

**Future consideration:** A `pluck` method could provide explicit cell output.

### D3: Vectorized `iskey`

The `iskey` method now returns a logical array for array inputs:
```matlab
iskey(data.users, "email")  % Returns: [true false true]
all(iskey(data.users, "name"))  % Check if ALL have key
```

This enables filtering patterns and is a breaking change from the previous behavior (which only checked the first element).

### D4: Index Pre-Filtering

When accessing or assigning `arr.field(idx)`, the array is pre-filtered by `idx` before checking if all elements have the key. This supports **any valid MATLAB index type**:

```matlab
% Numeric indexing
arr.value(1)              % Single element
arr.value(1:5)            % Range
arr.value([1 3 5])        % Array of indices

% Logical indexing (any size)
arr.score(iskey(arr, "score"))     % Full mask
arr.score(mask(1:10))              % Partial mask

% Assignment with any index type
arr.active([1 3]) = true           % Broadcast scalar
arr.value(1:3) = [100, 200, 300]   % Element-wise
```

The pattern `arr.field(idx)` is interpreted as:
1. Pre-filter array: `filteredArr = arr(idx)`
2. Access field on filtered array: `filteredArr.field`
3. Return/assign concatenated values

---

## Rationale

### Why Not Comma-Separated Lists?

We chose to return a single concatenated result rather than comma-separated lists because:
1. `dotListLength` would need to return `numel(obj)` dynamically
2. Capturing comma-separated lists requires special syntax: `[a, b, c] = ...`
3. A single array is more convenient for most use cases

### Why Not Always Return Cell Arrays?

Returning cells for heterogeneous types would create unpredictable APIs:
- Sometimes `arr.field` returns `["a", "b"]`
- Sometimes `arr.field` returns `{1, "two", true}`
- Calling code would need to handle both cases

The strict approach ensures predictable types.

### Why Return `missing` for Missing Keys? (Issue #74)

Optional fields in config files are common, and heterogeneous arrays are a natural pattern (e.g., event logs with mixed event types). Returning `missing` for absent keys:

**Simplifies filtering:**
```matlab
% Before (3 steps with index mapping)
hasSensor = iskey(events, "sensor");
sensorIndices = find(hasSensor);
eventsWithSensor = events(hasSensor);
tempMask = eventsWithSensor.sensor == "temperature";
tempIndices = sensorIndices(tempMask);
events(tempIndices).value = events(tempIndices).value * 1.1;

% After (2 steps with direct boolean indexing)
tempMask = events.sensor == "temperature";  % missing == "temp" is false
events(tempMask).value = events(tempMask).value * 1.1;
```

**Trade-offs:**
- **Pro:** Composable, familiar (matches MATLAB tables), eliminates index gymnastics
- **Con:** Silent masking of bugs (accessing absent key doesn't error)
- **Mitigation:** Use `iskey()` for authoritative key existence checks when needed

The convenience outweighs the risk for config file workflows where heterogeneous structures are expected.

---

## Implementation

### `iskey` Method (vectorized)
```matlab
function tf = iskey(obj, key)
    tf = false(size(obj));
    for i = 1:numel(obj)
        resolvedKey = obj(i).resolveKey(key);
        tf(i) = ~isempty(resolvedKey);
    end
end
```

### `dotReference` (array handling)
```matlab
if ~isscalar(obj)
    % Check all elements have the key
    hasKey = iskey(obj, fieldName);
    if ~all(hasKey)
        % Error with missing element indices
    end

    % Collect values
    values = cell(size(obj));
    for i = 1:numel(obj)
        values{i} = obj(i).getData(resolvedKey);
    end

    % Concatenate (errors if types differ)
    result = tryConcatenate(values, fieldName);
end
```

### `parenDotAssign` (array element assignment)
Now handles `arr(idx).field = value` pattern correctly.

---

## Examples

```matlab
% Read TOML with array of tables
data = readtoml("tests/SampleFiles/array_of_tables.toml");

% Array dot reference - returns typed arrays
names = data.products.name      % ["Hammer" "Nail" "Screwdriver"]
prices = data.products.price    % [19.99 0.05 24.99]
active = data.products.in_stock % [true true false]

% Chained access through nested objects
admins = data.users.permissions.admin  % [false false true]

% Filtering with iskey (now optional)
hasEmail = iskey(data.users, "email");
emails = data.users(hasEmail).email;        % Explicit filtering (still works)
emails = data.users.email(hasEmail);        % Access with logical pre-filter (shorthand)

% NEW: Direct filtering without iskey (Issue #74)
emails = data.users.email(~ismissing(data.users.email));  % Filter missing inline

% Type mismatch error (still applies to present values)
j1 = jsondata(); j1.v = 1;
j2 = jsondata(); j2.v = "two";
[j1 j2].v  % ERROR: Types differ

% Missing key handling (NEW - Issue #74)
j1 = jsondata(); j1.name = "Alice";
j2 = jsondata();  % no name
[j1 j2].name  % Returns: ["Alice", missing]

% Direct filtering with missing values
events(events.sensor == "temperature")  % Works even if some lack "sensor"
```

---

## References

- Implementation: `toolbox/+matlab/+io/+config/ConfigurationData.m`
- Tests: `tests/subsasgnTest.m` (array dot reference section)
- Related: `Claude/ARRAY_INDEXING_LIMITATIONS.md`
- Issue #74: Design question for missing key behavior
- Examples: `research/issue74_missing_key_behavior/issue74_comparison.m`

# Spec: Search capabilities for ConfigurationData

**Author:** Claude (based on issue #71)
**Date:** February 26, 2026
**Status:** Draft

**Related issues:**
- [#71: Add search capabilities](../issues/0071-add-search-capabilities.md) — this spec
- [#72: Wildcard key search](../issues/0072-wildcard-key-search-for-configurationdata.md) — overlapping scope

---

## Requirements

### Problem statement

When working with deeply nested configuration data, users often need to find where specific keys or values live in the hierarchy. Current tools require manually navigating the tree level by level.

**The core problem:** "I know there's a `timeout` setting somewhere in this config, but I don't know where."

**Current state:**

| Task | Current approach | Pain point |
|------|-----------------|------------|
| Find where a key lives | Tab completion + trial and error, or manually inspect `show()` output | No programmatic way to locate keys by name |
| Find all keys matching a pattern | Must use `describe()` table and filter manually | Requires two steps; no direct search API |
| Find keys with specific values | Manual traversal with recursive code | No built-in support |
| Search within text values | Must extract all values and search manually | Very tedious for deep nesting |

**What describe() provides today:**

`describe(config)` returns a table with `Path`, `Type`, `Size`, and `Value` columns, enabling queries like:

```matlab
info = describe(config);
% Find all keys named "port" anywhere in the tree
info(endsWith(info.Path, "port") | endsWith(info.Path, "Port"), :)
```

This works but requires:
1. Understanding that `describe()` returns a queryable table
2. Manually constructing string patterns for the `Path` column
3. Remembering MATLAB string functions (`endsWith`, `startsWith`, `contains`)

### Use cases

**UC1: "Where is this key?"**
A user loads a large config file and remembers there's a `database.host` setting, but doesn't recall the exact path (`server.database.host`? `config.database.host`? `app.db.host`?).

*Need:* Quickly find all paths containing "database" and "host".

**UC2: "Find all keys matching a pattern"**
A user has experiment results with keys like `Run1_accuracy`, `Run1_loss`, `Run2_accuracy`, `Run2_loss`. They want to extract all `Run1_*` keys.

*Need:* Wildcard or pattern matching on key names (overlaps with issue #72).

**UC3: "Which keys have a specific value?"**
A user needs to find all fields set to `null`/`missing` or all numeric fields equal to a specific default value (e.g., `timeout=30`).

*Need:* Search by value, not just key name.

**UC4: "Search text content"**
A user has a config with many string fields (URLs, file paths, descriptions). They want to find all fields containing "localhost" or "staging".

*Need:* Text search across string values.

**UC5: "Find optional fields"**
A user has an array of config objects where most have the same schema, but some have optional fields like `ssl_enabled` or `retry_count`. They want to find which elements have these fields.

*Need:* Identify which array elements contain a specific key.

### Requirements summary

| ID | Requirement | Priority |
|---|---|---|
| R1 | Find keys by exact name match, case-sensitive and case-insensitive | MUST HAVE |
| R2 | Find keys by pattern (wildcard, regex, or partial match) | MUST HAVE |
| R3 | Return hierarchical paths to matching keys (e.g., `"server.database.host"`) | MUST HAVE |
| R4 | Search recursively through nested ConfigurationData objects | MUST HAVE |
| R5 | Search within ConfigurationData arrays | MUST HAVE |
| R6 | Find keys by value (exact match) | NICE TO HAVE |
| R7 | Find string values by text content (substring search) | NICE TO HAVE |
| R8 | Compose with existing functions (`select()`, `getData()`) | MUST HAVE |
| R9 | Support all ConfigurationData subclasses | MUST HAVE |
| R10 | Performance: acceptable for configs with 1000+ keys | MUST HAVE |

---

## Proposed Design

### Overview

Add two new functions to ConfigurationData:

1. **`findkeys(obj, pattern)`** — Find keys matching a pattern, return paths as strings
2. **`findvalues(obj, value)` or `findtext(obj, pattern)`** — Find keys by value content (optional, lower priority)

These complement the existing `describe()` table query approach by providing a simpler, more discoverable API for the common case.

### Design option A: `findkeys()` function

#### Signature

```matlab
paths = findkeys(obj, pattern)
paths = findkeys(obj, pattern, Name=Value)
```

**Parameters:**
- `pattern` — Key name pattern. Supports:
  - String literal for exact match: `"timeout"`
  - wildcardPattern: `wildcardPattern("Run1*")`
  - Pattern with `*` wildcards: `"database*"` (automatically converted to wildcardPattern)
  - For regex, user creates pattern first: `findkeys(obj, pattern(@(s) ~isempty(regexp(s, 'Run\d+_.*'))))`

**Name-Value arguments:**
- `IgnoreCase` (logical, default `false`) — Case-insensitive matching
- `MatchType` (`"exact"` | `"partial"` | `"pattern"`, default `"pattern"`)
  - `"exact"`: Full key name must match
  - `"partial"`: Pattern can match anywhere in key name (`contains()`)
  - `"pattern"`: Use pattern matching (wildcardPattern or function handle)
- `Recursive` (logical, default `true`) — Search nested objects

**Returns:**
- String array of dot-notation paths to matching keys
- Empty string array `string.empty(0,1)` if no matches

#### Examples

**Exact match:**
```matlab
config = readyaml("k8s-deployment.yaml");

% Find all keys named exactly "port"
paths = findkeys(config, "port");
% → ["spec.containers.port", "spec.service.port"]

% Case-insensitive
paths = findkeys(config, "PORT", IgnoreCase=true);
```

**Wildcard patterns:**
```matlab
% Find all keys starting with "Run1"
paths = findkeys(config, "Run1*");
% → ["Run1_accuracy", "Run1_loss", "Run1_timestamp"]

% Find keys with "database" anywhere in the name
paths = findkeys(config, "*database*");
% → ["server.database.host", "cache.database_url"]

% Or explicitly using partial matching
paths = findkeys(config, "database", MatchType="partial");
```

**Composing with select():**
```matlab
% Extract all Run1 fields into a new object
run1Paths = findkeys(config, "Run1*");
run1Data = select(config, extractAfter(run1Paths, strlength("Run1_")));
```

**Top-level only:**
```matlab
% Search only top-level keys (no recursion)
paths = findkeys(config, "database*", Recursive=false);
```

**Using with ConfigurationData arrays:**
```matlab
servers = config.servers;  % array of ConfigurationData

% Find which elements have an "ssl_enabled" key
for i = 1:numel(servers)
    if ~isempty(findkeys(servers(i), "ssl_enabled", Recursive=false))
        fprintf("Server %d has SSL config\n", i);
    end
end
```

#### Implementation notes

- Built on top of `keys(obj)` recursive traversal
- For nested objects, recursively call `findkeys()` and prepend parent key
- Returns canonical key names (handles key aliasing automatically)
- Works with the internal `xInternal__.OriginalKeys` to preserve ordering

---

### Design option B: `findvalues()` function (optional, lower priority)

Enable searching by value content, not just key names.

#### Signature

```matlab
paths = findvalues(obj, value)
paths = findvalues(obj, value, Name=Value)
```

**Parameters:**
- `value` — Value to search for. Supports:
  - Exact match for scalars: `missing`, `30`, `"localhost"`
  - Function handle for custom logic: `@(v) isnumeric(v) && v > 100`

**Name-Value arguments:**
- `MatchType` (`"exact"` | `"contains"`, default `"exact"`)
  - `"exact"`: Value must equal target (using `isequal()`)
  - `"contains"`: For strings, substring match; for arrays, element match
- `Recursive` (logical, default `true`)

**Returns:**
- String array of paths where value matches

#### Examples

```matlab
% Find all fields set to missing/null
paths = findvalues(config, missing);
% → ["database.backup_host", "cache.fallback_url"]

% Find all numeric fields equal to 30
paths = findvalues(config, 30);
% → ["timeout", "server.retry_interval"]

% Find strings containing "localhost"
paths = findvalues(config, "localhost", MatchType="contains");
% → ["server.host", "database.url"]

% Find all numeric fields > 100 using custom function
paths = findvalues(config, @(v) isnumeric(v) && isscalar(v) && v > 100);
% → ["server.max_connections", "cache.size_mb"]
```

#### Implementation challenges

- Handling different types (numeric, string, logical, arrays, nested objects)
- `contains()` semantics for non-string types
- Performance for large configs (must traverse entire tree and inspect values)

---

## Alternative designs considered

### Alt 1: Extend `describe()` with built-in filtering

Add optional filtering arguments to `describe()`:

```matlab
info = describe(config, KeyPattern="*database*");
info = describe(config, ValueEquals=missing);
```

**Pros:**
- Single unified API for structural overview + search
- No new functions to learn

**Cons:**
- `describe()` already returns a table; users can filter it themselves
- Mixes two distinct concerns (structural display vs. search)
- Harder to compose (table output less ergonomic than string array)
- Name-value syntax gets cluttered with many options

**Verdict:** Not recommended. Keep `describe()` focused on structural overview.

---

### Alt 2: Single `search()` function with mode parameter

```matlab
paths = search(config, "pattern", Type="key")
paths = search(config, "localhost", Type="value")
```

**Pros:**
- Single entry point
- Potentially more discoverable

**Cons:**
- Less clear intent (`findkeys` vs `findvalues` is self-documenting)
- More complex signature with mode switching
- `search` is too generic (conflicts with common terminology)

**Verdict:** Not recommended. Separate functions are clearer.

---

### Alt 3: Method syntax instead of function syntax

```matlab
paths = config.findkeys("port")
```

**Pros:**
- Feels more "object-oriented"

**Cons:**
- **Breaks project convention**: ConfigurationData uses function syntax for methods (`keys(obj)`, `show(obj)`, `describe(obj)`) due to `OverridesPublicDotMethodCall`
- Users might confuse `config.findkeys` with accessing a data key named "findkeys"

**Verdict:** Not recommended. Stay consistent with existing API.

---

### Alt 4: Return table instead of string array

```matlab
results = findkeys(config, "port");
% Returns table with columns: Path, Type, Size, Value
```

**Pros:**
- More information available immediately
- Consistent with `describe()` output

**Cons:**
- Harder to compose with other functions
- String array is simpler and sufficient for most use cases
- User can always call `describe()` and filter if they want table output

**Verdict:** Not recommended. Prioritize composability with `select()`, `getData()`.

---

### Alt 5: Use `matches()` pattern object

Leverage MATLAB's `pattern` objects (R2020b+) for more expressive matching:

```matlab
pat = "Run" + digitsPattern(1) + "_" + wildcardPattern;
paths = findkeys(config, pat);
```

**Pros:**
- Very expressive
- Native MATLAB pattern syntax
- Works with `matches()` which supports `IgnoreCase`

**Cons:**
- More complex for simple cases
- Requires R2020b+ (this toolbox targets R2022b, so OK)
- Users must learn `pattern` syntax

**Verdict:** Support as an option (accept `pattern` objects), but also allow simple `"*"` wildcards for ease of use.

---

## Proposed implementation approach

### Phase 1: `findkeys()` with basic patterns (issue #72)

Implement `findkeys()` with:
- Exact match
- Wildcard patterns using `*` (converted to wildcardPattern internally)
- `IgnoreCase` option
- Recursive search (default)

**Acceptance criteria:**
- Works with all ConfigurationData subclasses
- Handles nested objects and arrays
- Returns canonical key names
- Composes with `select()` and `getData()`

### Phase 2: Value search (optional, evaluate user demand)

If user feedback shows demand for value-based search, implement `findvalues()` or add to `findkeys()` as a mode.

### Phase 3: Advanced patterns (future)

If basic wildcards prove insufficient, add support for:
- Regex patterns
- Function handle predicates
- More sophisticated filtering

---

## Relationship to existing APIs

### With `describe()`

`findkeys()` is a specialized, simpler alternative to querying the `describe()` table:

| Task | Using `describe()` | Using `findkeys()` |
|------|-------------------|-------------------|
| Find "port" keys | `info = describe(cfg);`<br>`info(endsWith(info.Path, "port"), :)` | `paths = findkeys(cfg, "port")` |
| Find "Run1*" keys | `info = describe(cfg);`<br>`info(startsWith(info.Path, "Run1"), :)` | `paths = findkeys(cfg, "Run1*")` |

Both approaches are valid. `findkeys()` is more direct for the common case; `describe()` gives more information (types, sizes, values).

### With `select()`

`findkeys()` output is designed to compose with `select()`:

```matlab
% Find keys, then project to subset
matchingPaths = findkeys(config, "Run1*");
subset = select(config, matchingPaths);
```

### With `keys()`

`keys()` returns all top-level keys. `findkeys()` filters and recurses:

```matlab
allKeys = keys(config);               % ["server", "database", "cache"]
portKeys = findkeys(config, "*port"); % ["server.admin.port", "database.port"]
```

---

## Design rationale

### Pros

| Benefit | Priority |
|---------|----------|
| Simple, focused API for common search task | HIGH |
| Composes naturally with existing functions (`select()`, `getData()`) | HIGH |
| Consistent with project's function-syntax convention | HIGH |
| String array return type is easy to work with | MEDIUM |
| No breaking changes to existing APIs | HIGH |

### Cons and mitigations

| Con | Mitigation | Priority |
|-----|------------|----------|
| Yet another function to learn | Good naming and docs make intent clear | MEDIUM |
| Overlaps with `describe()` table queries | Position as simpler alternative for common case | LOW |
| Wildcard syntax less powerful than regex | Support both; users can use pattern objects for advanced cases | LOW |
| Value search (`findvalues`) adds complexity | Defer to Phase 2; validate demand first | LOW |

---

## Open questions

1. **Should `findkeys()` return short key names or full paths?**
   - **Proposed:** Full dot-notation paths (e.g., `"server.database.host"`), because that's what `select()` and `getData()` accept for nested access.
   - If users want just the leaf key names, they can use `extractAfter(paths, lastIndexOf(paths, "."))`.

2. **How to handle arrays of ConfigurationData?**
   - **Proposed:** Include array syntax in paths: `"servers(2).host"` vs just `"servers.host"`?
   - **Decision needed:** For now, return paths to the key within each element, letting users iterate if needed. Table from `describe()` shows which element.

3. **Should there be a shorthand for case-insensitive search?**
   - **Proposed:** `IgnoreCase=true` is explicit and consistent with MATLAB conventions (e.g., `contains(..., IgnoreCase=true)`).

4. **Should `findkeys()` support multiple patterns at once?**
   ```matlab
   paths = findkeys(config, ["*host*", "*port*"]);  % OR logic
   ```
   - **Proposed:** Defer to Phase 2. For now, users can call twice and combine with `union()`.

5. **Should value search be combined into `findkeys()` or a separate function?**
   - **Proposed:** Separate function (`findvalues()`) if implemented, because:
     - Different parameters and return semantics
     - Keeps `findkeys()` API simple
     - Users can choose the right tool

---

## Testing considerations

### Unit tests for `findkeys()`

1. Exact match (case-sensitive and case-insensitive)
2. Wildcard patterns (`*`, multiple wildcards)
3. Recursive vs. non-recursive search
4. Empty results (no matches)
5. Arrays of ConfigurationData
6. All ConfigurationData subclasses (YAML, TOML, JSON, INI)
7. Keys with special characters (hyphens, underscores) and aliasing
8. Composition with `select()` and `getData()`

### Performance tests

- Large config file (1000+ keys) — search should complete in <100ms
- Deep nesting (10+ levels) — ensure recursion doesn't stack overflow

### Documentation tests

- Include examples in function docstring
- Add to user guide / examples folder

---

## Documentation outline

### Function reference: `findkeys`

**Purpose:** Find keys in a ConfigurationData object by pattern matching.

**Syntax:**
```matlab
paths = findkeys(obj, pattern)
paths = findkeys(obj, pattern, Name=Value)
```

**Description:**
`findkeys(obj, pattern)` searches recursively through `obj` for keys matching `pattern` and returns their full dot-notation paths as a string array.

**Examples:**
- Find keys by name
- Use wildcard patterns
- Case-insensitive search
- Combine with `select()` to extract subset

**See also:** `keys`, `select`, `describe`, `isfield`

---

## Success metrics

1. **Discoverability:** Users can find the function via tab completion, help search, or doc pages
2. **Ease of use:** Common searches require one line of code (e.g., `findkeys(cfg, "port")`)
3. **Adoption:** If implemented, tracked via internal telemetry or user feedback
4. **No confusion:** Clear distinction from `keys()`, `describe()`, `select()`

---

## Future enhancements (out of scope for initial release)

1. **Value-based search** — `findvalues(obj, value)` or add `ValueEquals` option to `findkeys()`
2. **Multiple patterns** — `findkeys(obj, ["host", "port"])` with OR logic
3. **AND logic** — Find paths containing both "database" AND "host"
4. **Return structured results** — Option to return table instead of string array
5. **Search across files** — `findkeys(["file1.yaml", "file2.yaml"], "pattern")` for multi-file projects
6. **Integration with `describe()` output** — `findkeys(describeTable, "pattern")` to filter table

---

## Recommendation

**Implement `findkeys()` as specified in Design Option A (Phase 1).**

- Addresses the core use case: finding keys by pattern
- Simple, composable API
- Low implementation risk
- Solves both issue #71 (general search) and issue #72 (wildcard matching)

**Defer `findvalues()` to Phase 2** pending user feedback on whether value-based search is needed.

**Leverage existing `describe()` table queries** for users who need more advanced filtering until dedicated search functions prove their value.

# Issue #77: Array Orientation Normalization - Implementation Plan

**Date:** 2026-03-12
**Status:** Planning - In Discussion
**Issue:** [0077-normalize-yaml-array-orientation-to-avoid-horzcat-vertcat-issues.md](../issues/0077-normalize-yaml-array-orientation-to-avoid-horzcat-vertcat-issues.md)
**Related Issues:** #82 (Display array values to match their actual orientation)

## Executive Summary

The toolbox currently has **inconsistent array orientations** for VALUES stored in configuration data objects. This causes problems when extracting values from ConfigurationData object arrays using dot notation.

**The Core Problem:**

ConfigurationData object arrays can be any shape (1xN, Nx1, MxN), but **common workflows produce 1xN arrays** (row vectors):
- Readers return 1xN arrays (e.g., `configs = readyaml('files/*.yaml')`)
- Single-index expansion creates 1xN arrays (e.g., `config(2) = YAMLData` makes 1x2)
- This matches MATLAB struct behavior (e.g., `mystruct(2).field` expands to 1x2)

When you extract values from object arrays using dot notation, **MATLAB's concatenation behavior depends on the object array shape:**
- **1xN object array** → uses `horzcat` to combine values
- **Nx1 object array** → uses `vertcat` to combine values

**Why Column Vectors for Values Matter:**

If each object stores a **column vector value** (e.g., 3x1 array) and you have a **1xN object array** (common case):
```matlab
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat([8080;8443;9000], [8080;8443;9000], [8080;8443;9000])
% Result: 3x3 array where each column is one config's ports ✅
```

But if values are **row vectors** (1x3):
```matlab
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat([8080 8443 9000], [8080 8443 9000], [8080 8443 9000])
% Result: 1x9 flattened array - structure lost! ❌
```

**Current State - Inconsistent Value Orientations:**

| Format | Current Orientation | Implementation Location |
|--------|-------------------|------------------------|
| **YAML** | Column vectors (Nx1) | `readyaml.m:362` - `parsedItems(:)` |
| **JSON** | Column vectors (Nx1) | `readjson.m:271-303` - `vertcat(...)` |
| **INI** | **Row vectors (1xN)** ⚠️ | `readini.m:126,132` - `array'` |
| **TOML** | No normalization | `readtoml.m:770-776` - natural shape |

**Root Cause:** `ConfigurationData.tryConcatenate` (lines 917-1041) preserves whatever orientation it receives without enforcing consistency.

**Proposed Solution:** Normalize all **array values** to **column vectors** centrally in `ConfigurationData.tryConcatenate`.

---

## Detailed Analysis

### Understanding Object Array Concatenation

MATLAB's dot notation on object arrays uses different concatenation operations based on array shape:

```matlab
% Example: 3 configs, each with ports = [8080; 8443; 9000] (3x1 column)

% Case 1: 1xN object array (common) - uses horzcat
configs_row = [config1 config2 config3];  % 1x3
ports = configs_row.ports;
% MATLAB calls: horzcat([8080;8443;9000], [8080;8443;9000], [8080;8443;9000])
% Result: [8080 8080 8080    % 3x3 array - natural structure!
%          8443 8443 8443
%          9000 9000 9000]

% Case 2: Nx1 object array - uses vertcat
configs_col = [config1; config2; config3];  % 3x1
ports = configs_col.ports;
% MATLAB calls: vertcat([8080;8443;9000], [8080;8443;9000], [8080;8443;9000])
% Result: [8080    % 9x1 array - each config's ports stacked
%          8443
%          9000
%          8080
%          8443
%          9000
%          8080
%          8443
%          9000]
```

**Key Insight:** Column vector values work naturally with both orientations. Row vector values cause problems with 1xN object arrays (the common case).

### Why Common Workflows Produce 1xN Object Arrays

**1. Readers return 1xN:**
```matlab
configs = readyaml('config*.yaml');  % Returns 1xN array of YAMLData objects
```

**2. Single-index expansion (MATLAB behavior):**
```matlab
config(1) = YAMLData;  % Scalar
config(2) = YAMLData;  % Now 1x2 (row vector)
config(5) = YAMLData;  % Now 1x5 (row vector)
```

This matches struct behavior:
```matlab
s(1).name = "Alice";
s(2).name = "Bob";     % Creates 1x2 struct array
```

**3. Common array construction:**
```matlab
configs = [config1 config2 config3];  % 1x3 (horizontal concatenation)
```

**Note:** Users CAN create Nx1 or MxN arrays intentionally:
```matlab
configs = [config1; config2; config3];  % 3x1 (vertical concatenation)
```

Our design must support all shapes, but optimize for the 1xN common case.

### Current Implementation Details

#### 1. Base Class (`ConfigurationData.m`)

**Storage:** Array values stored in `xInternal__.Data` dictionary as cells without orientation enforcement.

**Concatenation Logic (`tryConcatenate`, lines 917-1041):**
```matlab
% Line 1006 - Scalar concatenation
result = reshape([values{:}], inputShape);  % Preserves input shape

% Line 1013 - Non-scalar concatenation
result = cat(1, values{:});  % Preserves input shape

% Line 927 comment:
% "The shape of the result matches the shape of the values cell array"
```

**Key Finding:** The base class is **orientation-agnostic** - it preserves whatever shape comes in.

#### 2. Reader Implementations

**readyaml.m - Column Normalization (lines 356-393):**
```matlab
% Line 362 in consolidateArray function
if size(parsedItems, 1) == 1 && size(parsedItems, 2) > 1
    parsedItems = parsedItems(:);  % Convert row to column
end
```

**readjson.m - Column Normalization (lines 248-309):**
```matlab
% Lines 271-303 in consolidateArray function
result = vertcat(cellArray{:});  # Always column vectors
```

**readini.m - Row Normalization (lines 117-132):**
```matlab
% Line 126
value = numArray';  % Transpose to row vector

% Line 132
value = parts';  % Transpose to row vector
```

**readtoml.m - No Normalization (lines 730-784):**
```matlab
% Line 770
arr = [parsedElements{:}];  % Horizontal concatenation, no normalization
```

#### 3. Writer Implementations

**All writers** (YAML, TOML, JSON, INI) accept any orientation without normalizing. This creates round-trip consistency within each format but inconsistency across formats.

---

## Proposed Solution

### Design Decision 1: Column Vector Convention for Values

**Choice:** Normalize all **array values** to **column vectors (Nx1)**

**Primary Rationale:** Enables natural concatenation behavior for 1xN object arrays (the common case)

When users do `objArray.key` on a **1xN object array** (common workflow):
- Values as columns → `horzcat` produces clean MxN result ✅
- Values as rows → `horzcat` produces flattened 1x(M*N) mess ❌

**Example:**
```matlab
% 3 configs in 1x3 array, each has ports = [8080; 8443; 9000]
configs = [config1 config2 config3];
ports = configs.ports;  % 3x3: each column is one config's ports ✅

% If ports were rows: [8080 8443 9000]
ports = configs.ports;  % 1x9: [8080 8443 9000 8080 8443 9000 8080 8443 9000] ❌
```

**Secondary Benefits:**
1. **MATLAB convention** - Column-major indexing is MATLAB's default
2. **Two formats already compliant** - YAML and JSON already use columns
3. **Test alignment** - Existing tests expect column vectors
4. **Issue #74 compatibility** - Missing key behavior returns `missing`, which concatenates naturally with column vectors

**Alternative Considered:** Row vectors would break the natural concatenation behavior for 1xN object arrays (common case), require changing YAML/JSON (more widely used), break more tests, and conflict with MATLAB's column-major convention. ❌ Rejected.

### Design Decision 2: Centralized Implementation

**Choice:** Implement normalization in `ConfigurationData.tryConcatenate`

**Rationale:**
1. **Single point of control** - All array sources (readers, subsasgn, nested creation) flow through this method
2. **Format-agnostic** - Applies uniformly to all subclasses (YAMLData, TOMLData, JSONData, INIData)
3. **Minimal code duplication** - One normalization point vs. 4+ reader modifications
4. **Architectural consistency** - Keeps normalization with concatenation logic
5. **Catches all cases** - Including user code like `config.newfield = [1 2 3]` (row input)

**Alternative Considered:** Normalizing in each reader would scatter the logic, miss cases like nested object creation via subsasgn, and create maintenance burden. ❌ Rejected.

### Design Decision 3: Normalization Scope

**What Gets Normalized:**
- ✅ Numeric arrays (`double`, `single`, `int*`, `uint*`)
- ✅ String arrays
- ✅ Logical arrays
- ✅ ConfigurationData object arrays

**What Does NOT Get Normalized:**
- ❌ Cell arrays (no clear orientation semantics - each cell independent)
- ❌ Struct arrays (rarely used in configs, complex semantics)
- ❌ Scalar values (already orientation-neutral)
- ❌ Empty arrays `[]` (no orientation)
- ❌ Multi-dimensional arrays (only true vectors - one dimension is 1)

---

## Implementation Details

### Phase 1: Core Normalization in ConfigurationData

**File:** `toolbox/+matlab/+io/+config/ConfigurationData.m`

**Step 1:** Add private helper method (around line 1800):

```matlab
function array = normalizeVectorOrientation(array)
    % Normalize vectors to column orientation for consistent concatenation
    % behavior across all configuration formats (YAML, TOML, JSON, INI).
    %
    % Rationale: Column vector values enable natural concatenation when
    % extracting from 1xN object arrays (common case). For 1xN objArray:
    %   objArray.key with column values → clean MxN array via horzcat
    %   objArray.key with row values → flattened 1x(M*N) via horzcat
    %
    % See Issue #77 and Claude/ISSUE_77_ARRAY_ORIENTATION_PLAN.md

    if isempty(array) || isscalar(array)
        return;  % No normalization needed
    end

    sz = size(array);

    % Only normalize true vectors (one dimension is 1)
    if numel(sz) == 2 && sz(1) == 1 && sz(2) > 1
        % Row vector (1xN) → transpose to column (Nx1)
        array = array(:);
    end
    % Column vectors (Nx1) and multi-dimensional arrays pass through unchanged
end
```

**Step 2:** Modify `tryConcatenate` method to call normalization:

```matlab
% After line 987 (char array handling):
result = char(values);
result = obj.normalizeVectorOrientation(result);  % NEW

% After line 992 (ConfigurationData objects):
result = [values{:}];
result = obj.normalizeVectorOrientation(result);  % NEW

% After line 1006 (scalar concatenation):
result = reshape([values{:}], inputShape);
result = obj.normalizeVectorOrientation(result);  % NEW

% After line 1013 (non-scalar concatenation):
result = cat(1, values{:});
result = obj.normalizeVectorOrientation(result);  % NEW
```

### Phase 2: Remove Redundant Reader Normalizations

Now that normalization is centralized, remove format-specific logic:

**readyaml.m (line 362):**
```matlab
% BEFORE:
if size(parsedItems, 1) == 1 && size(parsedItems, 2) > 1
    parsedItems = parsedItems(:);  % Convert row to column
end

% AFTER:
% (Remove - normalization now handled by ConfigurationData.tryConcatenate)
```

**readjson.m (lines 271-303):**
```matlab
% SIMPLIFY: The explicit vertcat calls can be replaced with simple
% concatenation since normalization now happens in ConfigurationData
% This is optional cleanup - existing code will still work
```

**readini.m (lines 126, 132):**
```matlab
% BEFORE:
value = numArray';  % Transpose to row vector

% AFTER:
value = numArray;  % No transpose - let ConfigurationData normalize

% BEFORE:
value = parts';  % Transpose to row vector

% AFTER:
value = parts;  % No transpose - let ConfigurationData normalize
```

**readtoml.m:**
- No changes needed (no current normalization)

### Phase 3: Test Updates

**tests/initest.m (lines 106-107):**
```matlab
% BEFORE:
testCase.verifyEqual(ports, [8080 8443 9000])
testCase.verifyEqual(hosts, ["alpha" "beta" "gamma"])

% AFTER:
testCase.verifyEqual(ports, [8080; 8443; 9000])
testCase.verifyEqual(hosts, ["alpha"; "beta"; "gamma"])
```

**tests/tomltest.m (line 445):**
```matlab
% BEFORE:
testCase.verifyEqual(restored.numbers(:), [1; 2; 3])  % Workaround

% AFTER:
testCase.verifyEqual(restored.numbers, [1; 2; 3])  % Direct comparison
```

**Create tests/arrayOrientationTest.m:**

New comprehensive test file covering:
1. **Format consistency** - All formats return column vectors
2. **Object array extraction** - Key extraction from 1xN and Nx1 object arrays
3. **Concatenation behavior** - Verify horzcat/vertcat work as expected
4. **Round-trip preservation** - Orientation preserved through read/write
5. **Edge cases** - Empty arrays, scalars, nested arrays

```matlab
classdef arrayOrientationTest < matlab.unittest.TestCase
    % Tests for consistent array orientation across all formats (Issue #77)

    methods(Test)
        function testYAMLArraysAreColumns(testCase)
            % YAML array values should be column vectors
        end

        function testJSONArraysAreColumns(testCase)
            % JSON array values should be column vectors
        end

        function testINIArraysAreColumns(testCase)
            % INI comma-separated values should be column vectors
        end

        function testTOMLArraysAreColumns(testCase)
            % TOML array values should be column vectors
        end

        function testObjectArrayExtraction1xN(testCase)
            % Extract values from 1xN object array (common case)
            % Verify horzcat produces clean MxN result
        end

        function testObjectArrayExtractionNx1(testCase)
            % Extract values from Nx1 object array
            % Verify vertcat stacks values correctly
        end

        function testNestedArrayOrientation(testCase)
            % Nested arrays should maintain column orientation
        end

        function testConcatenationNoError(testCase)
            % Concatenating arrays from different formats should work
        end

        function testEmptyArrayOrientation(testCase)
            % Empty arrays should not error during normalization
        end

        function testScalarArrayNotAffected(testCase)
            % Scalar values should pass through unchanged
        end

        function testMixedFormatConcatenation(testCase)
            % Combine YAML, TOML, JSON, INI arrays without error
        end

        function testUserAssignedRowVectorNormalized(testCase)
            % User assigns row vector via subsasgn, gets normalized
            % config.field = [1 2 3] should store as [1; 2; 3]
        end
    end
end
```

### Phase 4: Documentation Updates

**CLAUDE.md - Add section under "Architecture":**

```markdown
### Array Value Orientation

All array **values** are normalized to **column vectors** internally. This enables natural concatenation behavior when extracting values from ConfigurationData object arrays.

#### Why Column Vectors?

ConfigurationData object arrays can be any shape (1xN, Nx1, MxN), but common workflows produce **1xN arrays** (row vectors):
- Readers return 1xN arrays
- Single-index expansion creates 1xN arrays (e.g., `config(2) = YAMLData` makes 1x2)
- This matches MATLAB struct behavior

When extracting values from a **1xN object array** using dot notation, MATLAB uses `horzcat`:
```matlab
% 3 configs, each with ports = [8080; 8443; 9000] (3x1 column)
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat combines the values
% Result: 3x3 array where each column is one config's ports ✅
```

If values were row vectors, `horzcat` would flatten them into a 1x9 mess. Column vectors preserve structure.

#### Format Behavior

All formats normalize array values to columns:
- YAML: `[1, 2, 3]` → `[1; 2; 3]`
- JSON: `[1, 2, 3]` → `[1; 2; 3]`
- INI: `values=1,2,3` → `[1; 2; 3]`
- TOML: `values = [1, 2, 3]` → `[1; 2; 3]`

This ensures:
- Consistent behavior across formats
- Natural concatenation for 1xN object arrays (common case)
- Alignment with MATLAB's column-major convention

#### Breaking Change

**Prior to v2.x:** INI arrays were row vectors.

**Migration:** Code expecting row vectors should use transpose: `config.values'`.

#### Implementation

Normalization occurs in `ConfigurationData.tryConcatenate` via the `normalizeVectorOrientation` helper method, applying uniformly to all formats and nested structures.
```

**Claude/TAB_COMPLETION_DESIGN.md - Add note:**

```markdown
### Array Orientation Normalization (Issue #77)

ConfigurationData.tryConcatenate normalizes all vector **values** to column orientation after concatenation (lines 987, 992, 1006, 1013). This ensures natural concatenation behavior when extracting values from ConfigurationData object arrays.

**Key Insight:** 1xN object arrays (common case) use `horzcat` for dot extraction. Column vector values produce clean MxN results; row vector values would flatten into 1x(M*N).

**Design Choice:** Centralized in base class rather than scattered across readers to catch all array sources (readers, subsasgn, nested object creation).

See `normalizeVectorOrientation` helper method and Claude/ISSUE_77_ARRAY_ORIENTATION_PLAN.md.
```

---

## Edge Cases & Handling

| Case | Input | Output | Rationale |
|------|-------|--------|-----------|
| **Empty arrays** | `[]` | `[]` | No orientation to normalize |
| **Scalars** | `42` | `42` | Orientation-neutral |
| **Column vectors** | `[1; 2; 3]` | `[1; 2; 3]` | Already correct (no-op) |
| **Row vectors** | `[1 2 3]` | `[1; 2; 3]` | Transpose to column |
| **Multi-dimensional** | `[1 2; 3 4]` | `[1 2; 3 4]` | Not a true vector |
| **Cell arrays** | `{1, 2, 3}` | `{1, 2, 3}` | No clear orientation semantics |
| **ConfigData objects** | `[obj1 obj2]` | `[obj1; obj2]` | Normalize like numeric arrays |
| **Missing values** | `[1 missing 3]` | `[1; missing; 3]` | MATLAB's `missing` works with columns |

---

## Breaking Changes

**Affected:** INI format only

**Change:** Array values change from row vectors (1xN) to column vectors (Nx1)

**Impact Assessment:**
- **Usage:** Low - INI is the least-used format in this toolbox
- **Frequency:** CSV values in INI files are relatively rare
- **Severity:** Low - Simple transpose fixes existing code

**Migration Path:**
```matlab
% OLD behavior (pre-v2.x):
ports = config.ports;  % [8080 8443 9000] (1x3 row)

% NEW behavior (v2.x+):
ports = config.ports;  % [8080; 8443; 9000] (3x1 column)

% If row vectors are needed:
ports = config.ports';  % Transpose to row
```

**Documentation:** Add migration note in release notes and CHANGELOG.

---

## Alternatives Considered

### Alternative 1: User-Configurable Orientation
**Approach:** Add `ArrayOrientation='column'|'row'` parameter to all readers

**Pros:**
- User choice for backward compatibility
- Flexibility for different workflows

**Cons:**
- Adds complexity to every reader and writer
- Inconsistent codebases (different projects choose different conventions)
- API surface area grows
- No single source of truth
- Migration path still needed for existing code
- **Doesn't solve the fundamental problem:** 1xN object arrays with row values still produce flattened results

**Verdict:** ❌ Rejected - Configurability doesn't address the root cause (concatenation behavior)

### Alternative 2: Normalize in Readers Only
**Approach:** Add normalization logic to readyaml, readtoml, readjson, readini

**Pros:**
- Explicit in each reader
- Easy to trace where normalization happens

**Cons:**
- Scattered implementation (4+ locations)
- Misses arrays created via subsasgn (e.g., `config.new.field = [1 2 3]`)
- Code duplication
- Harder to maintain consistency

**Verdict:** ❌ Rejected - Centralized approach in `tryConcatenate` is architecturally cleaner

### Alternative 3: Row Vector Convention
**Approach:** Normalize all array values to row vectors (1xN)

**Pros:**
- Matches INI's current behavior (no change needed there)
- Sequence notation `[1, 2, 3]` feels row-like

**Cons:**
- Breaks YAML and JSON (more widely used formats)
- **Breaks the fundamental use case:** 1xN object arrays with row values produce flattened 1x(M*N) results via horzcat
- Conflicts with MATLAB's column-major convention
- More tests to update
- Less idiomatic MATLAB

**Verdict:** ❌ Rejected - Fundamentally incompatible with 1xN object array concatenation

### Alternative 4: Store Values as Row, Transpose on Extraction
**Approach:** Store values as rows internally, transpose to columns when extracting from object arrays

**Pros:**
- Display matches storage (rows shown as rows)

**Cons:**
- Complex detection logic (how do we know when extraction is from object array?)
- Performance overhead (transpose on every extraction)
- Breaks explicit access (e.g., `config.ports` would have inconsistent behavior)
- Violates principle of least surprise

**Verdict:** ❌ Rejected - Too complex, unpredictable behavior

---

## Implementation Checklist

### Phase 1: Core Logic
- [ ] Add `normalizeVectorOrientation` helper method to ConfigurationData (private section)
- [ ] Add detailed comment explaining concatenation rationale (Issue #77)
- [ ] Call `normalizeVectorOrientation` after char array handling (line 987)
- [ ] Call `normalizeVectorOrientation` after ConfigData object handling (line 992)
- [ ] Call `normalizeVectorOrientation` after scalar concatenation (line 1006)
- [ ] Call `normalizeVectorOrientation` after non-scalar concatenation (line 1013)

### Phase 2: Reader Cleanup
- [ ] readyaml.m: Remove `parsedItems(:)` at line 362
- [ ] readjson.m: Optional - simplify consolidateArray (lines 271-303)
- [ ] readini.m: Remove transpose `'` at line 126
- [ ] readini.m: Remove transpose `'` at line 132

### Phase 3: Test Updates
- [ ] Update initest.m line 106 to expect column vector
- [ ] Update initest.m line 107 to expect column vector
- [ ] Update tomltest.m line 445 to remove workaround
- [ ] Create arrayOrientationTest.m with test cases including:
  - [ ] Format consistency tests (YAML, JSON, INI, TOML)
  - [ ] Object array extraction tests (1xN and Nx1)
  - [ ] Concatenation behavior tests
  - [ ] Edge case tests
- [ ] Run yamltest.m (should pass unchanged)
- [ ] Run jsontest.m (should pass unchanged)
- [ ] Run tomltest.m (should pass with updates)
- [ ] Run initest.m (should pass with updates)
- [ ] Run arrayOrientationTest.m (all should pass)

### Phase 4: Documentation
- [ ] Add "Array Value Orientation" section to CLAUDE.md
- [ ] Update Claude/TAB_COMPLETION_DESIGN.md with normalization note
- [ ] Add breaking change note to CHANGELOG or release notes
- [ ] Update function help text in readyaml, readjson, readtoml, readini

---

## Success Criteria

- ✅ All formats return column vectors for array values
- ✅ Extracting from 1xN object arrays produces clean MxN results (not flattened)
- ✅ Extracting from Nx1 object arrays stacks values correctly
- ✅ No `horzcat`/`vertcat` errors when concatenating arrays from different formats
- ✅ Round-trip tests pass for all formats
- ✅ Existing YAML/JSON tests pass unchanged
- ✅ INI tests updated and passing
- ✅ TOML tests passing
- ✅ New arrayOrientationTest.m passes all cases
- ✅ Documentation clearly explains convention and rationale
- ✅ Migration path documented for INI users

---

## Critical Files

| File | Lines | Changes |
|------|-------|---------|
| `ConfigurationData.m` | 917-1041, ~1800 | Add `normalizeVectorOrientation`, call from `tryConcatenate` |
| `readini.m` | 126, 132 | Remove transpose operations |
| `readyaml.m` | 362 | Remove `parsedItems(:)` |
| `readjson.m` | 271-303 | Optional simplification |
| `initest.m` | 106-107 | Update expected values to columns |
| `tomltest.m` | 445 | Remove workaround |
| `arrayOrientationTest.m` | New file | Create with comprehensive test cases |
| `CLAUDE.md` | Architecture section | Document orientation convention and rationale |
| `TAB_COMPLETION_DESIGN.md` | Add note | Document normalization location and rationale |

---

## Next Steps

1. **Finalize plan** - Address any remaining questions
2. **Create feature branch** - Per branching strategy in CLAUDE.md
3. **Implement Phase 1** - Core normalization in ConfigurationData
4. **Implement Phase 2** - Reader cleanup
5. **Implement Phase 3** - Test updates and new test file
6. **Implement Phase 4** - Documentation
7. **Run full test suite** - Verify no regressions
8. **Manual verification** - Test with sample files from all formats, verify object array extraction
9. **Create pull request** - With detailed description and migration notes

---

**Author:** Claude Code
**Review Status:** In Discussion
**Last Updated:** 2026-03-12

# #77: Normalize YAML array orientation to avoid horzcat/vertcat issues

**State:** closed
**Created:** 2026-02-27
**Resolved:** 2026-03-12
**Labels:** design, enhancement
**Resolution:** Implemented array normalization to column vectors in ConfigurationData.tryConcatenate and setData

## Description

Array values stored in ConfigurationData objects have inconsistent orientations across formats, causing problems when extracting values from object arrays using dot notation.

## Background

Working with configuration arrays in MATLAB can lead to unexpected orientation mismatches when extracting values from ConfigurationData object arrays. The toolbox currently does not enforce a consistent orientation convention for **array values**, which causes `horzcat`/`vertcat` issues.

### Current State (Inconsistent)

| Format | Current Orientation | Implementation Location |
|--------|-------------------|------------------------|
| **YAML** | Column vectors (Nx1) | `readyaml.m:362` - `parsedItems(:)` |
| **JSON** | Column vectors (Nx1) | `readjson.m:271-303` - `vertcat(...)` |
| **INI** | **Row vectors (1xN)** ⚠️ | `readini.m:126,132` - `array'` |
| **TOML** | No normalization | `readtoml.m:770-776` - natural shape |

## Problem Statement

When extracting values from ConfigurationData object arrays using dot notation, **MATLAB's concatenation behavior depends on the object array shape**:
- **1xN object array** (common case) → uses `horzcat` to combine values
- **Nx1 object array** → uses `vertcat` to combine values

Common workflows produce **1xN object arrays** (row vectors):
- Readers return 1xN arrays: `configs = readyaml('config*.yaml')`
- Single-index expansion creates 1xN arrays: `config(2) = YAMLData` makes 1x2
- This matches MATLAB struct behavior: `mystruct(2).field` expands to 1x2

### The Problem with Row Vector Values

If each object stores a **row vector value** (e.g., 1x3 array) and you have a **1xN object array** (common case):

```matlab
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat([8080 8443 9000], [8080 8443 9000], [8080 8443 9000])
% Result: 1x9 flattened array - structure lost! ❌
```

### Why Column Vector Values Work

If values are **column vectors** (3x1):

```matlab
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat([8080;8443;9000], [8080;8443;9000], [8080;8443;9000])
% Result: 3x3 array where each column is one config's ports ✅
```

**Root Cause:** `ConfigurationData.tryConcatenate` (lines 917-1041) preserves whatever orientation it receives without enforcing consistency.

## Approved Solution

**Decision:** Normalize all **array values** to **column vectors (Nx1)** centrally in `ConfigurationData.tryConcatenate`.

### Rationale

1. **Enables natural concatenation** for 1xN object arrays (the common case)
2. **MATLAB convention** - Column-major indexing is MATLAB's default
3. **Two formats already compliant** - YAML and JSON already use columns
4. **Test alignment** - Existing tests expect column vectors
5. **Format-agnostic** - Applies uniformly to all subclasses when implemented in base class

### Scope

**What Gets Normalized:**
- ✅ Numeric arrays (`double`, `single`, `int*`, `uint*`)
- ✅ String arrays
- ✅ Logical arrays
- ✅ ConfigurationData object arrays

**What Does NOT Get Normalized:**
- ❌ Cell arrays (no clear orientation semantics)
- ❌ Struct arrays (complex semantics)
- ❌ Scalar values (orientation-neutral)
- ❌ Empty arrays `[]` (no orientation)
- ❌ Multi-dimensional arrays (only true vectors)

### Implementation Location

**File:** `toolbox/+matlab/+io/+config/ConfigurationData.m`

Add private `normalizeVectorOrientation` helper method and call it from `tryConcatenate` after all concatenation operations. This catches all array sources: readers, subsasgn, nested object creation.

See detailed implementation plan in `Claude/ISSUE_77_ARRAY_ORIENTATION_PLAN.md`.

## Breaking Changes

**Affected:** INI format only

**Change:** Array values change from row vectors (1xN) to column vectors (Nx1)

**Migration:**
```matlab
% OLD behavior (pre-v2.x):
ports = config.ports;  % [8080 8443 9000] (1x3 row)

% NEW behavior (v2.x+):
ports = config.ports;  % [8080; 8443; 9000] (3x1 column)

% If row vectors are needed:
ports = config.ports';  % Transpose to row
```

**Impact:** Low - INI is the least-used format, and CSV values in INI files are relatively rare.

## Success Criteria

- ✅ All formats return column vectors for array values
- ✅ Extracting from 1xN object arrays produces clean MxN results (not flattened)
- ✅ Extracting from Nx1 object arrays stacks values correctly
- ✅ No `horzcat`/`vertcat` errors when concatenating arrays from different formats
- ✅ Clear documentation of convention and rationale
- ✅ Migration path documented for INI users

## Related Issues

- #82 - Display array values with semicolons to match their column orientation
- See `Claude/DESIGN_DECISIONS.md` for architectural philosophy
- See `Claude/ISSUE_77_ARRAY_ORIENTATION_PLAN.md` for detailed implementation plan

# Display Array Values with Semicolons to Match Their Column Orientation

**State:** open
**Created:** 2026-03-12
**Labels:** enhancement
**Related Issues:** #77 (Array orientation normalization)

## Description

Array values in ConfigurationData objects are stored internally as **column vectors** (Nx1) to enable natural concatenation behavior when extracting from 1xN object arrays (see Issue #77). However, when MATLAB displays a ConfigurationData object (via `disp()`), small arrays are shown using **space separators**, making them *appear* to be row vectors:

```matlab
>> config = readyaml('server.yaml')

  YAMLData with keys:

    ports: [8080 8443 9000]          % Looks like row vector!
    hosts: [3x1 string]               % Just shows size
```

When the user extracts these values, they get column vectors:
```matlab
config.ports  % Returns [8080; 8443; 9000] (3x1 column)
config.hosts  % Returns ["alpha"; "beta"; "gamma"] (3x1 column)
```

**This display mismatch is misleading.**

## Scope

This issue affects **ONLY** the `disp()/display()` output of ConfigurationData objects:
- ✅ Change `formatValue()` method (line 382 in ConfigurationData.m)
- ❌ No changes to `show()` - it must produce valid YAML/TOML/JSON syntax
- ❌ No changes to writers (`writeyaml`, `writetoml`, `writejson`) - they already produce correct format

## Background

### Why Values Are Column Vectors (Issue #77)

ConfigurationData object arrays are commonly 1xN (row vectors):
- Readers return 1xN arrays
- Single-index expansion creates 1xN arrays: `config(2) = YAMLData` → 1x2
- Matches MATLAB struct behavior

When extracting values from a 1xN object array, MATLAB uses `horzcat`:
```matlab
configs = [config1 config2 config3];  % 1x3 object array
ports = configs.ports;  % horzcat([8080;8443;9000], [8080;8443;9000], [8080;8443;9000])
% Result: 3x3 array - each column is one config's ports ✅
```

If values were row vectors, `horzcat` would flatten them into a 1x9 mess. **Column vectors enable natural concatenation.**

### Current Display Behavior

The `formatValue()` method (line 382) in ConfigurationData.m formats values for display:

**Numeric arrays (lines 412-424):**
```matlab
elseif isnumeric(value)
    if isscalar(value)
        str = sprintf('%g', value);
    elseif numel(value) <= 5
        % Show small arrays inline
        numStr = sprintf('%g ', value);          % Space separator
        str = sprintf('[%s]', strtrim(numStr));  % [8080 8443 9000]
    else
        % Show size and type for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s %s]', sizeStr, class(value));
    end
```

Result: `[8080 8443 9000]` (looks like row vector)

**String arrays:**
- Fall through to generic handling (line 437-441)
- Display as `[3x1 string]` (size only, no values shown)

**Logical arrays (lines 425-436):**
- Display as `[3x1 logical]` (size only)

## Requirements

1. **Display column vectors with semicolons**
   - Numeric: `[8080; 8443; 9000]` instead of `[8080 8443 9000]`
   - String: `["alpha"; "beta"; "gamma"]` instead of `[3x1 string]`
   - Logical: `[true; false; true]` instead of `[3x1 logical]`

2. **Apply only to formatValue() display method**
   - No changes to `show()` (must remain valid YAML/TOML/JSON)
   - No changes to writers (already correct)

3. **Maintain readability**
   - Show values for small arrays (≤5 elements)
   - Show size for large arrays (>5 elements)

## Current vs. Proposed Display

### When typing `config` at command line:

**Current:**
```matlab
  YAMLData with keys:

    ports: [8080 8443 9000]
    hosts: [3x1 string]
    enabled: [3x1 logical]
```

**Proposed:**
```matlab
  YAMLData with keys:

    ports: [8080; 8443; 9000]
    hosts: ["alpha"; "beta"; "gamma"]
    enabled: [true; false; true]
```

### show() output remains unchanged (valid YAML):

```yaml
ports: [8080, 8443, 9000]
hosts: [alpha, beta, gamma]
enabled: [true, false, true]
```

## Proposed Implementation

### Modify formatValue() in ConfigurationData.m

**File:** `toolbox/+matlab/+io/+config/ConfigurationData.m`
**Method:** `formatValue` (lines 382-442)

**Changes:**

#### 1. Numeric arrays (lines 412-424)

**Current:**
```matlab
elseif isnumeric(value)
    if isscalar(value)
        str = sprintf('%g', value);
    elseif numel(value) <= 5
        % Show small arrays inline
        numStr = sprintf('%g ', value);          % Space separator
        str = sprintf('[%s]', strtrim(numStr));
    else
        % Show size and type for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s %s]', sizeStr, class(value));
    end
```

**Proposed:**
```matlab
elseif isnumeric(value)
    if isscalar(value)
        str = sprintf('%g', value);
    elseif numel(value) <= 5
        % Show small arrays inline with semicolons (column vectors)
        numStrs = arrayfun(@(x) sprintf('%g', x), value, 'UniformOutput', false);
        str = sprintf('[%s]', strjoin(numStrs, '; '));
    else
        % Show size and type for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s %s]', sizeStr, class(value));
    end
```

#### 2. String arrays (add new case after line 411)

**Current:** Falls through to generic handling, shows `[3x1 string]`

**Proposed:** Add explicit string array handling:
```matlab
elseif isstring(value)
    if isscalar(value)
        % Already handled above (line 406-411)
    elseif numel(value) <= 5
        % Show small string arrays inline with semicolons
        strStrs = arrayfun(@(s) sprintf('"%s"', s), value, 'UniformOutput', false);
        str = sprintf('[%s]', strjoin(strStrs, '; '));
    else
        % Show size for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s string]', sizeStr);
    end
```

**Note:** Move this BEFORE the numeric check (before line 412) since strings need different formatting.

#### 3. Logical arrays (lines 425-436)

**Current:**
```matlab
elseif islogical(value)
    if isscalar(value)
        if value
            str = 'true';
        else
            str = 'false';
        end
    else
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s logical]', sizeStr);
    end
```

**Proposed:**
```matlab
elseif islogical(value)
    if isscalar(value)
        if value
            str = 'true';
        else
            str = 'false';
        end
    elseif numel(value) <= 5
        % Show small logical arrays inline with semicolons
        logStrs = cell(size(value));
        logStrs(value) = {'true'};
        logStrs(~value) = {'false'};
        str = sprintf('[%s]', strjoin(logStrs, '; '));
    else
        % Show size for large arrays
        sizeStr = sprintf('%dx', size(value));
        sizeStr = sizeStr(1:end-1);
        str = sprintf('[%s logical]', sizeStr);
    end
```

## Implementation Checklist

- [ ] Modify `formatValue()` numeric array handling (line 415-418)
- [ ] Add `formatValue()` string array handling (insert after line 411)
- [ ] Modify `formatValue()` logical array handling (line 425-436)
- [ ] Test with ConfigurationData display
- [ ] Verify `show()` output unchanged
- [ ] Verify writer output unchanged
- [ ] Update tests if any explicitly check display output

## Test Cases

Create test to verify display output:

```matlab
% Test numeric arrays
config.ports = [8080; 8443; 9000];
evalc('disp(config)');  % Should contain "[8080; 8443; 9000]"

% Test string arrays
config.hosts = ["alpha"; "beta"; "gamma"];
evalc('disp(config)');  % Should contain '["alpha"; "beta"; "gamma"]'

% Test logical arrays
config.flags = [true; false; true];
evalc('disp(config)');  % Should contain "[true; false; true]"

% Test large arrays (should show size)
config.bigArray = (1:100)';
evalc('disp(config)');  % Should contain "[100x1 double]"
```

## Related Code

- `toolbox/+matlab/+io/+config/ConfigurationData.m:382-442` - `formatValue()` method (CHANGE HERE)
- `toolbox/+matlab/+io/+config/ConfigurationData.m:295-330` - `displayScalarObject()` calls `formatValue()`
- `toolbox/+matlab/+io/+config/ConfigurationData.m:3` - Inherits from `matlab.mixin.CustomDisplay`

**NO changes needed:**
- `toolbox/+matlab/+io/+config/YAMLData.m:34-69` - `show()` method (unchanged)
- `toolbox/+matlab/+io/+config/TOMLData.m:35` - `show()` method (unchanged)
- `toolbox/+matlab/+io/+config/JSONData.m:36` - `show()` method (unchanged)
- `toolbox/writeyaml.m` - Writer (unchanged)
- `toolbox/writetoml.m` - Writer (unchanged)
- `toolbox/writejson.m` - Writer (unchanged)

## Success Criteria

- ✅ Typing `config` displays arrays with semicolons: `[8080; 8443; 9000]`
- ✅ String arrays display values: `["alpha"; "beta"; "gamma"]` instead of `[3x1 string]`
- ✅ Logical arrays display values: `[true; false; true]` instead of `[3x1 logical]`
- ✅ Large arrays (>5 elements) still show size: `[100x1 double]`
- ✅ `show()` output unchanged (valid YAML/TOML/JSON with commas)
- ✅ Writers produce unchanged output (valid format syntax)
- ✅ Round-trip behavior unchanged

## Design Questions

### 1. What threshold for "small" arrays?

**Current:** `numel(value) <= 5`

**Rationale:** Show values for arrays up to 5 elements, size for larger arrays

**Alternative:** Could use different thresholds for different types
- Numeric: 5 elements
- String: 3 elements (strings are longer)
- Logical: 5 elements

**Recommendation:** Keep uniform threshold of 5 for consistency.

### 2. Truncate long strings in arrays?

```matlab
config.names = ["very long name here"; "another very long name"]
```

Should we truncate individual strings if they're too long?

**Recommendation:** Yes - truncate strings >40 chars like we do for scalar strings (line 407-408).

### 3. Handle multi-dimensional arrays?

Current implementation is vector-specific. What about 2x3 matrices?

```matlab
config.matrix = [1 2 3; 4 5 6]
```

**Recommendation:** Show size only for non-vectors: `[2x3 double]`

## Impact

**Severity:** Low - Visual display only, not functional behavior

**Affects:** All users viewing ConfigurationData at command line

**Breaking Change:** No - only affects how values are displayed, not their actual values

**Workaround:** Users can directly inspect values: `config.ports` shows MATLAB's native display (already correct)

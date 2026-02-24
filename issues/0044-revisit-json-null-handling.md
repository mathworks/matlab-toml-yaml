# #44: Revisit JSON null handling

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-03  
**Labels:** bug, enhancement  

## Description

## Background

JSON `null` values are currently converted to empty double arrays `[]` when read with `readjson`. This matches the pragmatic approach used for YAML/TOML where we optimize for usability over strict type fidelity.

However, this creates ambiguity:
- JSON `null` → MATLAB `[]`
- JSON `[]` (empty array) → MATLAB `[]`
- Missing key → key doesn't exist

## Current Behavior

```matlab
% JSON: {"value": null, "empty": []}
data = readjson('file.json');
data.value   % → []
data.empty   % → []
% Can't distinguish null from empty array
```

## Options to Consider

| Option | Representation | Pros | Cons |
|--------|---------------|------|------|
| `[]` (current) | `data.value = []` | Native MATLAB, simple | Ambiguous |
| `missing` | `data.value = missing` | Native MATLAB (R2016b+), semantic "intentionally absent" | Primarily for string/categorical arrays |
| `matlab.io.config.Null` | Singleton class | Unambiguous, `isa()` checkable | Wrapper type, breaks design philosophy |
| `NullRule` option | `readjson(..., 'NullRule', 'missing')` | User choice | More options to maintain |

## Recommendation

Consider adding a `NullRule` option to `readjson`:
- `'empty'` (default) - current behavior, null → `[]`
- `'missing'` - null → `missing` value

This provides flexibility while maintaining backward compatibility.

## Related

- Issue #15 discusses JSONTree for strict JSON mode
- YAML_SCALAR_ARRAY_ROUNDTRIP.md documents the "pragmatic mapping" design philosophy

## Comments

### Comment by michellehirsch on 2026-02-02

There's also a bug here. Empty JSON arrays are exporting as "null"
```json
{
  "dependencies": []
}
```

writes out as
```json
{
  "dependencies": null
}
```

Simple repro steps:
```matlab
j = jsondata
j.dependencies = []
show(j)
```

### Comment by michellehirsch on 2026-02-02

## Implementation Plan: Add NullRule Option for JSON Null Handling

### Overview
Add a `NullRule` name-value option to `readjson` to give users control over how JSON `null` values are represented in MATLAB. Default behavior (`[]`) remains unchanged for backward compatibility.

### Solution Approach

Implement the recommendation from the issue: add a `NullRule` option with two possible values:
- `'empty'` (default) - null → `[]` (current behavior)
- `'missing'` - null → `missing` value

### Implementation Steps

#### 1. Modify [readjson.m](toolbox/readjson.m)

**Add arguments block**:
```matlab
arguments
    filename (1,1) string
    options.SequenceRule (1,1) string {mustBeMember(options.SequenceRule, ["cell", "array"])} = "array"
    options.NullRule (1,1) string {mustBeMember(options.NullRule, ["empty", "missing"])} = "empty"
end
```

**Pass to jsondecode**:
```matlab
% Convert NullRule to jsondecode's format
if options.NullRule == "missing"
    structData = jsondecode(jsonText, 'SequenceRule', options.SequenceRule);
    % Post-process to convert [] to missing where appropriate
    structData = convertEmptyToMissing(structData);
else
    structData = jsondecode(jsonText, 'SequenceRule', options.SequenceRule);
end
```

**Challenge**: `jsondecode` always returns `[]` for null. We need to:
- Parse the raw JSON to identify null locations, OR
- Parse twice (with/without conversion) and compare, OR  
- Post-process heuristically (dangerous - can't distinguish null from empty array)

**Better approach**: Store null locations as metadata in JSONData object for round-trip fidelity.

#### 2. Store Null Metadata in JSONData

Add to [ConfigurationData.m](toolbox/ConfigurationData.m):
```matlab
% In xInternal__ struct:
% NullFields - string array of field paths that were originally null
```

Parse JSON to identify null locations:
```matlab
function nullPaths = findNullFields(jsonText)
    % Parse JSON text to find paths where value is null
    % Return as string array: ["field1", "nested.field2", ...]
    % This requires custom JSON parsing or regex approach
end
```

#### 3. Modify [writejson.m](toolbox/writejson.m)

Check `NullFields` metadata when serializing:
- If a field path is in `NullFields`, write as `null` instead of `[]`
- This requires `jsonencode` to handle `missing` → `null` (which it does in R2022b+)

#### 4. Alternative Simpler Approach

Since this is primarily about user preference and the toolbox philosophy is "pragmatic config file handling":

**Option A**: Just convert all `[]` to `missing` when `NullRule="missing"`
- Pros: Simple, no metadata needed
- Cons: Loses distinction between null and empty array

**Option B**: Document current behavior as intentional
- Add to Known Limitations in CLAUDE.md
- Explain that `[]` is used for both null and empty arrays
- Point users to direct `jsondecode`/`jsonencode` for strict JSON needs

**Recommended**: Implement Option A (simple conversion) since:
1. The toolbox is for config files, not strict JSON round-tripping
2. Config files rarely need to distinguish null vs empty array
3. Users who need strict JSON should use jsondecode/jsonencode directly

### Simplified Implementation (Recommended)

```matlab
function result = readjson(filename, options)
    arguments
        filename (1,1) string
        options.NullRule (1,1) string = "empty"
    end
    
    structData = jsondecode(fileread(filename));
    
    if options.NullRule == "missing"
        structData = replaceEmptyWithMissing(structData);
    end
    
    result = JSONData(structData);
end

function s = replaceEmptyWithMissing(s)
    % Recursively replace [] with missing
    if isstruct(s)
        fields = fieldnames(s);
        for i = 1:length(fields)
            s.(fields{i}) = replaceEmptyWithMissing(s.(fields{i}));
        end
    elseif isempty(s) && isnumeric(s)
        s = missing;
    end
end
```

### Testing Strategy

Add to [tests/jsontest.m](tests/jsontest.m):

1. **Test default behavior** (backward compatibility):
   ```matlab
   data = readjson('null_test.json'); % {"value": null}
   verifyEqual(testCase, data.value, []);
   ```

2. **Test NullRule="missing"**:
   ```matlab
   data = readjson('null_test.json', 'NullRule', 'missing');
   verifyTrue(testCase, ismissing(data.value));
   ```

3. **Test nested nulls**:
   ```matlab
   % {"obj": {"nested": null}}
   data = readjson('nested_null.json', 'NullRule', 'missing');
   verifyTrue(testCase, ismissing(data.obj.nested));
   ```

4. **Test empty array ambiguity** (document behavior):
   ```matlab
   % {"arr": [], "nul": null}
   % With NullRule="missing", both become missing
   ```

### Files to Modify
- [toolbox/readjson.m](toolbox/readjson.m) - Add NullRule option and conversion logic
- [tests/jsontest.m](tests/jsontest.m) - Add test cases for null handling
- [CLAUDE.md](CLAUDE.md) - Update Known Limitations section to document ambiguity

### Decision Needed
Should we:
1. Implement simple conversion (recommended) - accept that null/empty array distinction is lost
2. Implement full metadata tracking - preserve distinction but much more complex
3. Document as intentional limitation - no code changes

I recommend **option 1** (simple conversion) as it provides user value with minimal complexity and aligns with the "pragmatic config file handling" philosophy.

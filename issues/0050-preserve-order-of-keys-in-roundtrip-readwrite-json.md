# #50: Preserve order of keys in roundtrip read/write json

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-03  

## Description

json write isn't preserving key order. It should. 

I read this file:
```json
{
  "schemaVersion": "1.0.0",
  "name": "hDeimosApp",
  "version": "1.1.1",
  "id": "12345678-1234-4321-1234-123456789002",
  "releaseCompatibility": ">=R2022b",
  "summary": "Moon of Mars",
  "description": "Deimos is a moon the 4th planet in solar system. Another moon of the same planet is Phobos",
  "dependencies": [
    {
      "name": "hMarsApp",
      "id": "ffa5d32a-bd05-4898-bbc2-1fb48efb011d",
      "compatibleVersions": "4.2.1"
    }
  ],
  "folders": [
    {
      "path": "Public"
    }
  ]
}
```

Added a field "tags", wrote it out:
```json
{
  "dependencies": {
    "compatibleVersions": "4.2.1",
    "id": "ffa5d32a-bd05-4898-bbc2-1fb48efb011d",
    "name": "hMarsApp"
  },
  "description": "Deimos is a moon the 4th planet in solar system. Another moon of the same planet is Phobos",
  "folders": {
    "path": "Public"
  },
  "id": "12345678-1234-4321-1234-123456789002",
  "name": "hDeimosApp",
  "releaseCompatibility": ">=R2022b",
  "schemaVersion": "1.0.0",
  "summary": "Moon of Mars",
  "tags": [
    "TagValue1",
    "TagValue2"
  ],
  "version": "1.1.1"
}
```

## Comments

### Comment by michellehirsch on 2026-02-02

## Implementation Plan: Preserve Order of Keys in JSON Roundtrip

### Root Cause
The key order is already being tracked in `xInternal__.OriginalKeys` during `readjson`, but `writejson` is not using this information. Instead, it's relying on `jsonencode` which alphabetically sorts keys (MATLAB's default behavior).

### Solution Approach
Modify [writejson.m](toolbox/writejson.m) to leverage the `OriginalKeys` property from ConfigurationData objects to maintain insertion order:

1. **In `convertToMap` function** (~line 80-95):
   - When processing ConfigurationData objects, iterate through `data.xInternal__.OriginalKeys` instead of using `keys(data)`
   - This ensures we preserve the original order from the source file

2. **Key Implementation**:
   ```matlab
   if isa(data, 'matlab.io.config.ConfigurationData')
       % Use OriginalKeys to preserve order
       keyList = data.xInternal__.OriginalKeys;
       result = dictionary(string.empty, cell.empty);
       for i = 1:length(keyList)
           key = keyList(i);
           value = data.(key);
           result(key) = convertToMap(value, emptyValueOption);
       end
       return;
   end
   ```

3. **Edge case**: New keys added after reading (not in OriginalKeys) should be appended at the end

### Testing Strategy
1. Add test case to [jsontest.m](tests/jsontest.m):
   - Read JSON file with specific key order
   - Write it back out
   - Verify key order is preserved byte-for-byte (or at least ordering matches)
   
2. Test with the example file in the issue description

3. Test adding new keys (should append to end, not alphabetize)

### Files to Modify
- [toolbox/writejson.m](toolbox/writejson.m) - Update `convertToMap` to preserve key order
- [tests/jsontest.m](tests/jsontest.m) - Add round-trip key order preservation test

### Expected Behavior After Fix
Reading and writing the JSON from the issue should maintain the original key order with `schemaVersion` first, followed by `name`, `version`, `id`, etc., with the newly added `tags` field appearing at the end (or wherever it was added).

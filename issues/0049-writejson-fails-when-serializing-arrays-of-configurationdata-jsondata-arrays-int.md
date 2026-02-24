# #49: writejson fails when serializing arrays of ConfigurationData (JSONData arrays) — Intermediate indexing error

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-03  

## Description

Reproduction
----------
1. In repository root, run (MATLAB or via MCP server):

   addpath('toolbox');
   m = readjson('tests/SampleFiles/nested_sample.json');
   writejson(m, 'tests/SampleFiles/nested_sample_roundtrip.json');

Observed behavior
-----------------
writejson throws an error when serializing nested arrays of JSON objects (JSONData arrays):

  ERROR: Intermediate dot '.' indexing produced a comma-separated list with 2 values, but it must produce a single value when followed by subsequent indexing operations.
  In matlab.io.config.ConfigurationData/keys at line 54
  In writejson>convertToMap at line 83
  In writejson>convertToMap at line 94
  In writejson>convertToMap at line 94
  In writejson at line 48

Root cause
----------
In writejson's helper convertToMap, the branch that handles matlab.io.config.ConfigurationData objects assumes the object is scalar and calls keys(data) unconditionally. If data is an array of ConfigurationData (as produced when JSON arrays contain objects), then accessing obj.xInternal__.OriginalKeys inside keys() triggers MATLAB's comma-separated-list behavior and errors when used in a single-value context.

Proposed fix
------------
Handle non-scalar ConfigurationData arrays explicitly at the top of the branch. For example:

    if isa(data, 'matlab.io.config.ConfigurationData')
        if numel(data) > 1
            % Array of objects -> convert each element to its JSON representation
            result = cell(size(data));
            for i = 1:numel(data)
                result{i} = convertToMap(data(i), emptyValueOption);
            end
            return;
        end
        % ... existing scalar handling ...
    end

This will cause arrays of objects to be emitted as JSON arrays (cell arrays passed to jsonencode) rather than attempting to treat them as scalar objects.

Suggested tests
---------------
- Add a unit test using `tests/SampleFiles/nested_sample.json` that does a readjson()/writejson() round-trip and ensures no error and that the result is valid JSON.

Additional notes
----------------
- I reproduced this using the repository's MATLAB MCP server and saved a short repro script at `tests/repro_nested_sample.m` (run via MCP server or locally). The issue appears specific to serializing object arrays returned by `readjson` when JSON arrays of objects are present.

Please assign or label as a bug; happy to open a PR with the minimal fix and tests if you'd like.


## Comments

### Comment by michellehirsch on 2026-02-02

## Implementation Plan: Fix writejson for Arrays of ConfigurationData

### Root Cause
The issue is clearly identified: in [writejson.m](toolbox/writejson.m) line ~80-95, the `convertToMap` function assumes ConfigurationData objects are always scalar when calling `keys(data)`. When `data` is an array of JSONData objects (from JSON arrays of objects), accessing `obj.xInternal__.OriginalKeys` triggers MATLAB's comma-separated list behavior, causing the error.

### Solution
The proposed fix in the issue is correct and minimal. Handle non-scalar ConfigurationData arrays explicitly:

**In [writejson.m](toolbox/writejson.m)** `convertToMap` function (~line 80):

```matlab
if isa(data, 'matlab.io.config.ConfigurationData')
    % Handle arrays of objects
    if numel(data) > 1
        % Array of objects -> convert each element to a cell array
        result = cell(size(data));
        for i = 1:numel(data)
            result{i} = convertToMap(data(i), emptyValueOption);
        end
        return;
    end
    
    % Scalar object - existing logic
    keyList = keys(data);
    result = dictionary(string.empty, cell.empty);
    for i = 1:length(keyList)
        key = keyList(i);
        value = data.(key);
        result(key) = convertToMap(value, emptyValueOption);
    end
    return;
end
```

### Implementation Steps

1. **Modify [writejson.m](toolbox/writejson.m)**:
   - Add array handling at the top of the ConfigurationData branch
   - Loop through array elements and convert each to a map
   - Return as a cell array (which jsonencode will serialize as a JSON array)

2. **Add test case** in [tests/jsontest.m](tests/jsontest.m):
   ```matlab
   function testNestedArrayRoundtrip(testCase)
       % Test from issue #49
       originalFile = 'SampleFiles/nested_sample.json';
       outputFile = tempname + ".json";
       
       % Read and write
       data = readjson(originalFile);
       writejson(data, outputFile);
       
       % Verify no error and valid JSON
       dataRoundtrip = readjson(outputFile);
       
       % Clean up
       delete(outputFile);
   end
   ```

3. **Verify the fix** with the repro case:
   ```matlab
   addpath('toolbox');
   m = readjson('tests/SampleFiles/nested_sample.json');
   writejson(m, 'tests/SampleFiles/nested_sample_roundtrip.json');
   % Should complete without error
   ```

### Testing Strategy
1. Run the exact reproduction case from the issue
2. Add the suggested test using `nested_sample.json` 
3. Test various array structures:
   - Array of objects at root level
   - Nested arrays of objects
   - Mixed arrays (objects and primitives)
   - Empty arrays

### Files to Modify
- [toolbox/writejson.m](toolbox/writejson.m) - Add ~8 lines before existing ConfigurationData handling
- [tests/jsontest.m](tests/jsontest.m) - Add test case for array round-trip

### Complexity: Low
This is a straightforward fix with clear root cause and solution. The proposed fix is minimal and handles the edge case without affecting existing scalar object behavior.

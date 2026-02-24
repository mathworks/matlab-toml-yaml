# #48: Fix json support for preserving scalar arrays

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-03  

## Description

Take this simple example with a single-element array:
```
{
    "images":[{
    "url":"MarineCv2_color.jpg",
    "uuid":"1F3E9A1C-DDD2-3F4D-80C1-BC5F609DC23B",
    "name":"MarineCv2_color.jpg"
    }]
}
```

It's intentional that `readjson` turns this array into a scalar, but my hope was that
```
s2 = readjson("simple.json","SequenceRule","cell")
```
would be a simple way to force arrays to stay as arrays (cell arrays), so that when we write them back out again we preserve the arrayness.

It's not working. I'm guessing the issue is our reliance on jsondecode, but perhaps it's my misunderstanding of how JSON works.

## Comments

### Comment by michellehirsch on 2026-02-02

## Implementation Plan: Fix JSON Support for Preserving Scalar Arrays

### Root Cause Analysis
The issue stems from two places:
1. **`readjson`** relies on `jsondecode` which automatically converts single-element arrays to scalars (MATLAB default behavior)
2. Even when `SequenceRule: "cell"` is passed to `jsondecode`, the post-processing in `readjson` may not be preserving this information in a way that `writejson` can use

### Solution Approach

This is a challenging problem because `jsondecode`'s behavior is baked in. Consider these options:

#### Option 1: Store Array Metadata (Recommended)
Store metadata about which keys were originally arrays in the JSONData object:

1. **Modify [readjson.m](toolbox/readjson.m)**:
   - Parse JSON twice: once with default settings, once with `SequenceRule: "cell"`
   - Compare results to identify which fields were originally arrays
   - Store this information in a new field: `xInternal__.ArrayFields` (string array of dot-notation paths)

2. **Modify [writejson.m](toolbox/writejson.m)**:
   - Check if a value's path is in `ArrayFields`
   - If so, wrap scalar values in a cell array before passing to `jsonencode`
   - For nested objects, propagate array field information down

#### Option 2: Always Use Cell Arrays (Breaking Change)
When `SequenceRule: "cell"` is specified, store all arrays as cell arrays internally:
- Pros: Simpler implementation
- Cons: Changes internal representation, may break existing code

#### Option 3: Document Limitation
Given the complexity and that this is a roundtrip issue specific to single-element arrays, document this as a known limitation of the JSON wrapper approach.

### Recommended Implementation (Option 1)

1. **In [readjson.m](toolbox/readjson.m)** (~line 40-80):
   ```matlab
   % Parse twice to detect which fields are arrays
   dataDefault = jsondecode(jsonText);
   dataWithCells = jsondecode(jsonText, 'SequenceRule', 'cell');
   
   % Compare and track array fields
   arrayFields = identifyArrayFields(dataDefault, dataWithCells);
   
   % Create JSONData object
   result = JSONData;
   result.xInternal__.ArrayFields = arrayFields;
   ```

2. **Add helper function** `identifyArrayFields` to recursively compare structures

3. **In [writejson.m](toolbox/writejson.m)** `convertToMap`:
   - Pass array field information through recursion
   - Wrap scalars in cells when they should be arrays

### Alternative: Simpler Partial Fix
If full metadata tracking is too complex, consider:
- Only support `SequenceRule: "cell"` by storing all JSON arrays as cell arrays in ConfigurationData
- Add a note that this changes the internal representation but preserves round-trip fidelity

### Testing Strategy
1. Test file: the `simple.json` example from the issue
2. Verify `readjson` + `writejson` preserves `[{...}]` array syntax
3. Test nested arrays and multiple single-element arrays
4. Test with and without `SequenceRule: "cell"` option

### Files to Modify
- [toolbox/readjson.m](toolbox/readjson.m) - Track array fields
- [toolbox/writejson.m](toolbox/writejson.m) - Use array metadata during serialization  
- [toolbox/ConfigurationData.m](toolbox/ConfigurationData.m) - Add `ArrayFields` property (if needed)
- [tests/jsontest.m](tests/jsontest.m) - Add scalar array roundtrip tests

### Decision Needed
This requires a design decision on how much complexity to add for this edge case. Given the "pragmatic config file handling" philosophy, Option 3 (document limitation) might be acceptable, but Option 1 provides the best user experience.

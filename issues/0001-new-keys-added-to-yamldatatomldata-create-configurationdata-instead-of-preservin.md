# #1: New keys added to YAMLData/TOMLData create ConfigurationData instead of preserving class type

**State:** closed  
**Created:** 2026-01-14  
**Closed:** 2026-01-14  
**Labels:** bug  

## Description

## Bug Description

When adding a new key to a `YAMLData` or `TOMLData` object via dot notation, the nested object is created as `ConfigurationData` instead of preserving the parent object's class type.

## Steps to Reproduce

```matlab
server = readyaml("examples/server_config.yaml");
server.cache.enabled = true;
disp(server);
```

## Expected Behavior

The `cache` key should be a `YAMLData` object, not `ConfigurationData`.

## Actual Behavior

```
cache: [1×1 ConfigurationData with 1 key]  % Wrong class!
```

Should be:
```
cache: [1×1 YAMLData with 1 key]
```

## Root Cause

In `ConfigurationData.m` method `dotAssign`, lines 395 and 400 hardcode:
```matlab
nested = ConfigurationData;
```

## Proposed Fix

Replace with dynamic class construction:
```matlab
nested = feval(class(obj));  % Preserves parent's class type
nested.SourceFormat = obj.SourceFormat;
```

This ensures:
- `YAMLData` objects create `YAMLData` children
- `TOMLData` objects create `TOMLData` children
- `ConfigurationData` objects create `ConfigurationData` children

## Impact

**Severity:** Medium

**Affects:**
- User experience (inconsistent display)
- Type checking (`isa(obj.cache, 'YAMLData')` fails)
- Serialization/roundtrip behavior

**Workaround:**
```matlab
server.cache = YAMLData();
server.cache.enabled = true;
```

See `Claude/ISSUE_class_preservation.md` for complete details and testing checklist.

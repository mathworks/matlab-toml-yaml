# #14: ConfigurationData can inherit from OverridesPublicDotMethodCall  to avoid naming collisions with "keys"

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-16  

## Description

I get an error if I try to add a field called `keys`, since `keys` is a reserved name in this design:

```
>> config = readyaml("examples/basic_config.yaml");
>> config.keys = "hello"
Assignment not supported because the result of method 'keys' is a temporary value.
```

We can use [`matlab.mixin.indexing.OverridesPublicDotMethodCall`](https://www.mathworks.com/help/matlab/ref/matlab.mixin.indexing.overridespublicdotmethodcall-class.html) to allow users to call `keys(tomlData)` while leaving `tomlData.keys` available for `dotAssign` and `dotReference`.

In general, I would recommend against having reserved names in the design since I've seen a lot of subtle bugs dealing with `Properties` and `:` as reserved names in table IO. The suggestion here is one alternative; another one is a `dictionary`-style syntax where parenReference/parenAssign is used instead of dotReference/dotAssign to access and set keys.

## Comments

### Comment by michellehirsch on 2026-01-16

I definitely don't want the dictionary style syntax. The structure of these files maps overall very close to structs (the big issue is handling invalid names), so I've found struct-like syntax to be the most natural.

I'm working on a solution based on your first recommendation.

### Comment by michellehirsch on 2026-01-16

Fixed in commit ad7b6e7. 

ConfigurationData now inherits from `OverridesPublicDotMethodCall`, which routes all dot notation through `dotReference` first. Data keys take priority over method names, so users can now have keys named `keys`, `isfield`, `show`, `struct`, `copy`, `empty`, etc.

**API Change:** Methods must be called with function syntax:
```matlab
% Before (no longer calls the method)
allKeys = config.keys;

% After (required for method calls)  
allKeys = keys(config);
```

This is consistent with MATLAB conventions (`keys(dict)`, `fieldnames(struct)`) and was already documented as the preferred syntax in DESIGN_DECISIONS.md.

See [Claude/ISSUE_14_RESERVED_NAMES.md](https://github.com/michellehirsch/matlab-toml-yaml/blob/main/Claude/ISSUE_14_RESERVED_NAMES.md) for full implementation details.

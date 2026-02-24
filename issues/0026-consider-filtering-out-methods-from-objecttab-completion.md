# #26: Consider filtering out methods from object.<tab> completion

**State:** open  
**Created:** 2026-01-16  
**Labels:** design  

## Description

We should likely filter out methods from object.<tab> completion.

* Users are working with these like structs. The expectation is that you are navigating the hierarchy. Right now, lists of keys can be surrounded by methods - gets awkward.
* Does obj.method() even work if method is the same name as a key?

## Comments

### Comment by michellehirsch on 2026-01-16

Now that I addressed issue #14, we definitely should do this. dot method invocation doesn't work.

```matlab
>> config = readyaml("examples/basic_config.yaml")
>> config.fieldnames
Error using [ . ](matlab:matlab.lang.internal.introspective.errorDocCallback('ConfigurationData/dotReference', '/Users/michellehirsch/Coding/AgentExperiments/MATLAB/Claude/ConfigurationFileIO/toolbox/ConfigurationData.m', 383)) ([line 383](matlab: opentoline('/Users/michellehirsch/Coding/AgentExperiments/MATLAB/Claude/ConfigurationFileIO/toolbox/ConfigurationData.m',383,0)))
Key "fieldnames" does not exist.
```

### Comment by aylindmello on 2026-01-16

This can be done by marking those methods as `Hidden=true`. I think the tab-completion engine only shows public-visible methods in the completion list by default.

It might be bad for discoverability though if the methods don't show up in `methods` or `methodsview`.

### Comment by michellehirsch on 2026-01-16

Claude wrote the following. But we handle this correctly with table, so need to figure out how that works.

## Investigation: Hiding Methods from Tab Completion

After research, there doesn't appear to be a built-in mechanism to hide methods from dot-completion while keeping them visible in `methods(obj)`.

### What Doesn't Work

1. **`functionSignatures.json`** - Only controls function/method *argument* completion, not what appears in dot-completion for objects.

2. **`Hidden` attribute on methods** - Would hide methods from both tab completion AND `methods(obj)` output. This breaks discoverability since users wouldn't see available methods.

3. **`OverridesPublicDotMethodCall`** (already in use) - Controls *behavior* when `obj.method` is used (redirects to `dotReference`), but doesn't control what the IDE *suggests* in autocomplete.

### Known MATLAB Limitation

According to [this MATLAB Answers post](https://www.mathworks.com/matlabcentral/answers/2058184-how-to-achieve-autocompletion-for-fake-properties-of-class-inheriting-from-matlab-mixin-indexing-r), tab completion doesn't support dynamic properties for `RedefinesDot` classes because predicting completions would require running MATLAB code. The IDE uses `metaclass` information for completion suggestions.

### Current Behavior

- When users type `obj.` and press Tab, they see methods like `keys`, `isfield`, `show`, etc.
- Due to `OverridesPublicDotMethodCall`, using `obj.keys` will trigger `dotReference` and look for a data key named "keys" (not call the method)
- Methods must be called with function syntax: `keys(obj)`, `isfield(obj, "key")`, etc.

### Possible Path Forward

This may require a MathWorks enhancement request for something like a `hideFromDotCompletion` method attribute, or a way for `functionSignatures.json` to control class member visibility in dot-completion contexts.

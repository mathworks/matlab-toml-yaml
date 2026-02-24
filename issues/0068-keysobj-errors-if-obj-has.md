# #68: keys(obj) errors if obj has

**State:** closed  
**Created:** 2026-02-20  
**Closed:** 2026-02-20  

## Description

## Problem Statement
`keys` errors if you pass it a a TOMLData/YAMLData with keys that vary by element

## Reproduction Step 
```
>> wf = readyaml("toolbox/examples/ci.yaml")
>> steps = wf.jobs.test.steps
>> keys(steps)
Intermediate dot '.' indexing produced a comma-separated list with 4 values, but it must produce a single value when followed by subsequent indexing operations.

Error in [matlab.io.config.ConfigurationData/keys](matlab:matlab.lang.internal.introspective.errorDocCallback('matlab.io.config.ConfigurationData/keys', '/Users/michellehirsch/Coding/AgentExperiments/MATLAB/Claude/ConfigurationFileIO/toolbox/+matlab/+io/+config/ConfigurationData.m', 54)) ([line 54](matlab: opentoline('/Users/michellehirsch/Coding/AgentExperiments/MATLAB/Claude/ConfigurationFileIO/toolbox/+matlab/+io/+config/ConfigurationData.m',54,0)))
            k = obj.xInternal__.OriginalKeys;

```

## Recommendation
It's important that `keys` not error. A user will lose confidence in their ability to introspect an object if keys sometimes fails. And calling `keys` is the first thing you do - if you don't even know what the keys are, how are you supposed to go the next step to figuring out which keys are on which array elements?

We need to be careful with the design. Starting point design is to just return an array with all key names (the union across all array elements). This should be identical to the list we should in the display for a YAMLData/TOMLData array with mixed keys. This seems uncontroversial.

But this doesn't tell you that some keys are only on some elements. Should we do something about this?
* Argument for doing nothing: Use existing mechanism. just call iskey on the array to check yourself. 
* Argument for doing something, with some ideas: 
   * It would likely be helpful to at least get information indicating that keys vary by element, as we do in the display, because this lets you know you may need to be careful. This could be a simple second output to iskey: a logical tf that's true if keys vary by element (or false; polarity to be decided).
   * It might be helpful to get the list of keys for each individual array element. This could save a lot of trial and error. If `steps` is 1x4 `YAMLData`, this would probably be a 1x4 cell array, with each element containing a string array with the names of the keys for the corresponding array element. This seems potentially pretty nice. Instead of or in addition to the first idea? If this output is `k`, `isequal(k{:})` gives the first answer. We could just document that.


Anything we do, we need to update the corresponding `fieldnames` and any relevant documentation and examples. 


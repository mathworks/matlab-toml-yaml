# #17: Add convenience functions to convert between struct⇄ConfigurationData and dictionary⇄ConfigurationData

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-29  

## Description

It is very natural for users to already have a core MATLAB datatype representing their configuration data, or to want to work with a MATLAB datatype for their workflows.

I see that the implementation already has some `structToYaml` and `structToToml` converters in the `write*` functions implementation. It would be nice to expose these converters so that users can quickly create a ConfigurationData out of another container-like datatype (struct/dictionary/table/containers.Map) or convert a ConfigurationData to one of these datatypes.

## Comments

### Comment by michellehirsch on 2026-01-16

Sounds good. 
Here's what we have now:
* struct() to convert from ConfigurationData (and subclasses) to struct
* Direct support for struct as an input to the file writers

Design idea: Accept struct as input to YAMLData, TOMLData constructors

### Comment by michellehirsch on 2026-01-29

Implemented in commit 7d9cd6f on branch `mhirsch-struct-dict-conversion`:

## Summary

Added struct/dictionary conversion support with:

### TO ConfigurationData (constructors)
```matlab
s = struct('name', 'test', 'nested', struct('value', 42));
config = YAMLData(s);      % Also works with TOMLData, INIData
config = YAMLData(myDict); % From dictionary
config = YAMLData(myMap);  % From containers.Map
```

### FROM ConfigurationData (dictionary method)
```matlab
config = readyaml('config.yaml');
d = dictionary(config);  % Convert to dictionary
s = struct(config);      % Existing method
```

### Write functions accept native types
```matlab
writeyaml(myStruct, 'config.yaml');
writeyaml(myDict, 'config.yaml');
writetoml(myStruct, 'pyproject.toml');
```

All existing tests pass plus new functionality verified.

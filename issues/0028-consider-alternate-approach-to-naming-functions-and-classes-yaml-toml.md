# #28: Consider alternate approach to naming functions and classes: yaml, toml

**State:** open  
**Created:** 2026-01-16  
**Labels:** design  

## Description

From Jeremy:
Naming of the classes/functions - e.g. `YAMLData` vs. `yaml`: If the object represents a YAML doc, we could simply call the object a `yaml` object. Then,  `readyaml` returns a `yaml` just like read<type> pattern in MATLAB. Then the invariant of the object should be that it can always be serialized into yaml (i.e. without loss / perfect round-tripping).
* This is my preferred approach.
* The main benefit of this is that it preserves the "yaml-ness" of the data at every step, so you can do document transform and creation workflows without dealing with data model issues.
* This is closer to what jsontree is (and I also prefer the json object naming in that case as well)

An alternate of that could be `readconfig`/`writeconfig`, and these all return a "`config`" object that can be written to yaml/toml/json/xml/ini... whatever we decide to support. 
* In this case, we're designing a "config" object that can be imported/exported from/to multiple formats.
* To be clear, I'm not suggesting this, but it's worth thinking though. 
* My expectation is that the same data-model issues that exist between MATLAB and JSON will arise in a design using this approach.
* If we go with this approach, then I would name the object YAMLConfiguration which is a sub-class of ConfigurationData object.
* No one's going to not-use this object for not-configuration related work if it functionally solves their problem too... so the "config" naming just feels like we're imposing one use-case into the workflow instead of moving up one level of abstraction.

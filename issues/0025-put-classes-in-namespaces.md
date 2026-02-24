# #25: Put classes in namespaces

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-02-02  
**Labels:** design  

## Description

These classes are all named with the intention of putting them somewhere in `matlab.io.`.

we could create a new namespace `matlab.io.config`. Or, we could create `matlab.io.toml`, `matlab.io.yaml`, and reuse existing `matlab.io.json`. If we do this, put ConfigurationData in `matlab.io`

## Comments

### Comment by michellehirsch on 2026-02-02

Since we made ConfigurationData abstract, we definitely want to put it in a namespace. But, we might want to keep TOMLData and YAMLData in the global namespace, renaming them to tomldata and yamldata to comply with design standards. We currently rely on their constructors as converter functions from struct and dictionary - e.g. TOMLData(s) creates a TOMLData from a struct. 

Some thoughts on use cases for direct construction/conversion:
While we expect most uses to be roundtrip - read/modify/write - it's reasonably to anticipate some that start from scratch in MATLAB. Since we get type validation as we go with TOMLData, YAMLData, it will be a nicer workflow to create it earlier in your development instead of just passing a structure to writetoml/writeyaml. 

File format conversion workflows: Data is written in json or XML, and you want to convert to YAML. Read it in as a structure or a dictionary, use the YAMLData constructor to convert to YAML, make sure everything is valid, etc. then write it out.

# #19: Restrict the types that are allowed in YAMLData/TOMLData

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-29  
**Labels:** design  

## Description

Currently the `ConfigurationData` subclasses let you assign any MATLAB type into them:

<img width="622" height="232" alt="Image" src="https://github.com/user-attachments/assets/f75c5198-fa26-4930-a328-30954d1c24ac" />

It would be more maintainable if we restricted assignment into the YAMLData/TOMLData to an allow-list of types. Users would need to intentionally convert their own datatypes to one of the allowed types before assigning into these objects.

## Comments

### Comment by michellehirsch on 2026-01-16

This makes sense. 

Hopefully we can lock this behavior down in ConfigurationData, and build on existing code for mapping datatypes so we can keep one source of truth for how datatypes map between MATLAB and the files.

### Comment by michellehirsch on 2026-01-29

Implemented by pull request #32 

# #6: Create "Working with YAML Data" and "Working with TOML Data" examples

**State:** open  
**Created:** 2026-01-15  
**Labels:** documentation  

## Description

I've focused my examples around the reading and writing functions much more so than the datatypes. This means that usage of the datatypes is generally just shown in the context of reading from files.

I think it would be helpful to have two top-level examples - one each for YAML and TOML that show an overall workflow of reading from a file, making some changes, and writing it out to a new file. The examples should both use an example file, not generate it themselves. If there are appropriate examples in toolbox/examples we can use them, if not put new ones there. The example files should represent realistic use cases - GitHub Actions CI would be good for yaml, I'm open to ideas for toml. They should exercise some particularly useful options - especially with writing, to show how to get a file to look the way a user wants.

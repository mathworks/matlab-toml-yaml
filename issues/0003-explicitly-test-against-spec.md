# #3: Explicitly test against spec

**State:** open  
**Created:** 2026-01-14  

## Description

While we designed against the specs, and built lots of tests to assess core behavior, we don't currently test explicitly against the specs for TOML, YAML, and INI. Assess the tests to see if they are sufficient; decide if we should add any individual tests or if we should have a test suite specifically dedicated to assessing performance vs specs.

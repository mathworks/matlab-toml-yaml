# #10: Test failure: yamltest/testRoundtripSimpleDockerCompose

**State:** closed  
**Created:** 2026-01-15  
**Closed:** 2026-01-15  

## Description

yamltest/testRoundtripSimpleDockerCompose is failing.

The issue is with yamlwrite. It isn't adding quotes when writing out a version number, so we go from

`version: '3.8'`

to
`version: 3.8`

which gets read back in as a number, not a string. As we work on this, we should check more broadly if we need are missing other places we should be adding quotes.

Copilot said:
##When should you quote?
Quote when any of the following apply:
1. You need a string that looks like another type
* Version numbers: version: '3.8'
* Phone numbers or IDs with leading zeros: '0123'
* Values like true, false, null, ~, on, off, yes, no (for YAML 1.1 compatibility)
* ISO-like dates: '2020-01-01'

2. You need to include special characters or preserve spacing
* A # that should not start a comment: 'look # literal hash'
* A colon followed by space (can be ambiguous in some contexts): 'key: value'
* Leading or trailing spaces you must preserve: '  padded  '
* Newlines and tabs in the text (use double quotes for escapes or block scalars for readability)

3. You need escape sequences
* Use double quotes if you want \n, \t, \", \uXXXX, etc.

## Comments

### Comment by michellehirsch on 2026-01-15

A little investigation:
writeyaml line 157 (in configDataToYaml) is where we make the string representation of the yaml data. This is somewhere around where we need to be injecting quotes. The actual fix might be in generateYAML, though - adding to the if/else for handling different data types. We need to know when it's necessary to add quotes around values before writing them to the file. We don't want to write quotes more than necessary, though.


### Comment by michellehirsch on 2026-01-15

Fixed in commit bb1818b. The YAML writer now properly quotes strings that look like numbers (e.g., '3.8') or ISO dates to preserve their string type during roundtrip.

# #20: Refactor legacy string handling (char/cellstr) to native strings

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-01-30  
**Labels:** code improvement  

## Description

Refactor the codebase to use MATLAB's native string arrays instead of legacy char vectors or cellstr. This aligns with modern MATLAB practices.

Key areas to address:
- Replace `char()` conversions with `string()` where appropriate (e.g., in `readtoml.m`, `readini.m`).
- Use string arrays instead of `cellstr` in `ConfigurationData.m`.
- Update type checks (`ischar`) to support or favor `isstring`.
- Ensure dynamic field access (e.g., `data.(char(key))`) is handled cleanly, as MATLAB now supports string keys directly for struct/object field access in recent versions, or ensure consistent conversion.

## Comments

### Comment by michellehirsch on 2026-01-30

## Completed

This issue has been addressed through the following pull requests:

### PR #35: Modernize string handling with MATLAB best practices
- Replaced `strcmp()`/`strcmpi()` with `==` operator throughout
- Removed unnecessary `char()` conversions from `ConfigurationData.m`, `writetoml.m`, `readini.m`
- Changed `properties()` to return string array instead of `cellstr`
- Updated `readini.m` to return `string` instead of `char` for text values
- Used `ismember()` with string arrays

### PR #36: Modernize writeyaml.m string handling
- Replaced `cell()` arrays with `strings()` for line collection
- Replaced `sprintf` concatenation with `+` operator
- Replaced `repmat(' ', 1, n)` with `string(blanks(n))`
- Used `join()` instead of `strjoin()` for string arrays
- Used `compose()` for bulk formatting

### Bugfix: Fix char array comparison in key aliasing
- Fixed issue where `validKey ~= key` failed for char arrays of different lengths
- Reverted to `~strcmp()` for key aliasing comparisons where char input is possible

**Files modified:** ConfigurationData.m, writetoml.m, writeyaml.m, readtoml.m, readini.m, writeini.m, INIData.m, tests/initest.m

**Note:** Some `char()` calls remain in `readtoml.m` for dynamic field access during nested structure parsing. These are low-priority edge cases that work correctly and could be addressed in future refactoring if desired.

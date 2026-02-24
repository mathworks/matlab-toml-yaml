# #21: Replace cellfun/arrayfun with loops or vectorization

**State:** closed  
**Created:** 2026-01-16  
**Closed:** 2026-02-02  
**Labels:** code improvement  

## Description

Optimize performance and readability by replacing `arrayfun` and `cellfun` with explicit `for` loops or vectorized operations.

Context: 
- `readyaml.m` and `writeyaml.m` use `cellfun`/`arrayfun` for filtering lines and formatting.
- `ConfigurationData.m` uses them for struct conversion and error messaging.

Tasks:
- Evaluate each usage of `cellfun` and `arrayfun`.
- If the operation is not easily vectorized, use a standard `for` loop (often faster due to MATLAB's JIT).
- Look for vectorization opportunities (e.g., replacing `arrayfun` with vectorized string or numeric operations).

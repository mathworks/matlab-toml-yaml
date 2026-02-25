# Spec: `show()` for format-neutral ConfigurationData

**Author:** Michelle Hirsch
**Date:** February 2026
**Status:** Draft — design agreed, implementation in progress
**Issue:** [#75](https://github.com/michellehirsch/matlab-toml-yaml/issues/75)

---

## Problem

`show()` on format-specific subclasses (YAMLData, TOMLData, JSONData, INIData) writes data to a temp file in native format and prints it — very useful, shows all values. But `ConfigurationData` objects created via `configdata()` have no native format, so the base class `show()` just delegates to `describe()`. `describe()` is a structural overview that shows types but does not show values for ConfigurationData arrays. Result: calling `show(runs)` on a 1x4 array of `ConfigurationData` shows only types, not values.

### Concrete example (before fix)

```matlab
baseParams = configdata();
baseParams.model = "linear";
baseParams.epochs = 50;
baseParams.optimizer = "sgd";
runs = [];
learningRates = [0.001, 0.01, 0.1, 0.5];
for i = 1:numel(learningRates)
    params = merge(baseParams, configdata(struct('learning_rate', learningRates(i))));
    runs = [runs, params];
end
show(runs)

  1x4 array

    model:              string       ← type only, not useful
    epochs:             double
    optimizer:          string
    learning_rate:      double
```

Also affects embedded arrays within a scalar object: the `layers` field in a struct with a `ConfigurationData` array shows only types.

---

## Design goals

- `show()` is a **value viewer** — always shows actual data values
- `describe()` is a **schema inspector** — shows types and structure, less focused on values
- The two are complementary; this change sharpens the distinction

---

## Final design

### For scalar `ConfigurationData`

Same indented tree as now, but **without type annotations**. Type annotations belong to `describe()`, not `show()`.

```
  ConfigurationData with 4 keys

    name:               "experiment-1"
    version:            2
    training:
        optimizer:          "adam"
        learning_rate:      0.001
        scheduler:
            type:               "cosine"
            warmup_steps:       500
        layers:         1x3 array
        layers(1) =
            type:       "conv"
            filters:    64
        layers(2) =
            type:       "dense"
            units:      128
        layers(3) =
            type:       "dense"
            units:      10
    evaluation:
        metric:             "accuracy"
        threshold:          0.95
```

### For top-level arrays (`show(runs)`)

Inspired directly by MATLAB's ND array display (`X(:,:,1) =`). Each element is labeled with its index using the caller's variable name (from `inputname(1)`), falling back to `ans` if unavailable.

```
runs(1) =

    model:          "linear"
    epochs:         50
    optimizer:      "sgd"
    learning_rate:  0.001


runs(2) =

    model:          "linear"
    epochs:         50
    optimizer:      "sgd"
    learning_rate:  0.01

...
```

### Embedded vs. top-level array spacing

- **Top-level arrays**: blank line after `=` and double blank between elements, matching MATLAB's ND array convention exactly
- **Embedded arrays**: no blank lines around `key(i) =` headers — keeps the parent object compact and readable

---

## Alternatives considered

### A: Keep delegating to `describe()` (status quo)
Rejected. `describe()` is a schema tool. Showing types without values defeats the purpose of `show()`.

### B: `[1]`, `[2]` numbered style
```
  [1]
    model: "linear"
    ...
```
Rejected. Feels like viewing a comma-separated list or Python's `repr()`. Not idiomatic MATLAB.

### C: `(1)`, `(2)` numbered style (inline)
```
  (1)  model:  "linear"
       epochs: 50
```
Considered. The inline style is compact for small structures but harder to read when elements have many keys. The ND-array style with `=` scales better to larger elements.

### D: YAML `-` bullet style
```
  - type: "conv"
    filters: 64
```
Rejected. Looks like valid YAML, confusing since this is format-neutral data. Mixes display notation with serialization notation.

### E: Table display (like MATLAB's `table`)
```
    type      filters    units
    _______   _______    _____
    "conv"    64         NaN
    "dense"   NaN        128
```
Rejected as primary display. Breaks down when elements have different keys, nested objects, or non-scalar values. Could be a future separate feature for homogeneous arrays.

### F: Type annotations in `show()` (keep from `describe()`)
Rejected. `show()` goal is readability of values. Type annotations are noise when you're trying to read data. `describe()` is already there for type inspection.

---

## Open questions (deferred)

- **Truncation for large arrays**: Should `show()` truncate after N elements with `... and M more`? Deferred — implement without truncation first, add if it proves necessary in practice.
- **`Depth` parameter for `show()`**: Should `show()` support `show(obj, Depth=N)`? Deferred — `describe(obj, Depth=N)` already exists for depth-limited structural views.

---

## Implementation

### Files changed

- `toolbox/+matlab/+io/+config/ConfigurationData.m`

### Approach

- `show()`: use `inputname(1)` for variable name; call new `buildShowText()`
- `buildShowText()`: handles scalar (header + `buildShowKeysText`) and top-level arrays (ND-array style loop)
- `buildShowKeysText()`: like `buildKeysText` but (1) no type annotations on leaf values, (2) uses ND-array `key(i) =` style for embedded arrays instead of `buildArrayKeysText`
- `formatShowLeafValue()`: like `formatLeafValue` but strips `(type)` annotations

Format-specific subclasses (`YAMLData`, `TOMLData`, `JSONData`, `INIData`) are unchanged — they continue to use their own `show()` implementations.

---

## Test plan

Add tests to `tests/configdataTest.m` (or new `tests/showTest.m`):

1. Scalar with all leaf types — values shown, no type annotations
2. Nested scalar — indentation correct, nested keys expanded
3. Embedded ConfigurationData array — `key(i) =` style, values shown
4. Top-level array — `varname(i) =` style with blank line after `=`
5. `inputname` fallback — called without a named variable, `ans(i) =`
6. Empty object — no crash
7. Format-specific subclasses unchanged — `show(yamldata(...))` still prints YAML

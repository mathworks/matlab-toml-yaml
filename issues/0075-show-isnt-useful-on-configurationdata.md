# #75: show isn't useful on ConfigurationData

**State:** closed
**Created:** 2026-02-23
**Closed:** 2026-03-12

## Description

Since ConfigurationData isn't specialized to a file format, show doesn't seem to know what to do. It just does the same as describe, and doesn't show any values. Example:

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

    model:              string
    epochs:             double
    optimizer:          string
    learning_rate:      double
```

We should probably show a generic tree structure, likely just simple indenting, but optionally with some ascii art to better show alignment.

## Resolution

Implemented a format-neutral `show()` for `ConfigurationData` that displays **values** (not types). This sharpens the distinction between `show()` and `describe()`:
- `show(obj)` — value viewer; always shows actual data values
- `describe(obj)` — schema inspector; shows types and structure

### Design: Scalar ConfigurationData

Shows an indented tree **without type annotations**. Type annotations belong to `describe()`, not `show()`.

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

### Design: Top-Level Arrays

Inspired by MATLAB's ND array display (`X(:,:,1) =`). Each element is labeled with its index using the caller's variable name (from `inputname(1)`), falling back to `ans` if unavailable.

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

**Spacing rules:**
- **Top-level arrays**: blank line after `=` and double blank between elements (matches MATLAB's ND array convention)
- **Embedded arrays**: no blank lines around `key(i) =` headers (keeps parent object compact)

### Alternatives Considered

| Option | Decision |
|--------|----------|
| Keep delegating to `describe()` | ❌ Rejected — `describe()` is a schema tool; showing types without values defeats the purpose of `show()` |
| `[1]`, `[2]` numbered style | ❌ Rejected — feels like Python's `repr()`, not idiomatic MATLAB |
| YAML `-` bullet style | ❌ Rejected — looks like valid YAML, confusing for format-neutral data |
| Table display (like MATLAB `table`) | ❌ Rejected — breaks down with heterogeneous keys or nested objects |
| Type annotations in `show()` | ❌ Rejected — `show()` goal is readability of values; `describe()` is for types |
| ND-array style `varname(i) =` | ✅ **Chosen** — idiomatic MATLAB, scales well to large elements |

### Implementation

- **Files changed**: `toolbox/+matlab/+io/+config/ConfigurationData.m`
- **Approach**:
  - `show()`: uses `inputname(1)` for variable name; calls new `buildShowText()`
  - `buildShowText()`: handles scalar (header + `buildShowKeysText`) and top-level arrays (ND-array style loop)
  - `buildShowKeysText()`: like `buildKeysText` but (1) no type annotations on leaf values, (2) uses ND-array `key(i) =` style for embedded arrays
  - `formatShowLeafValue()`: like `formatLeafValue` but strips `(type)` annotations
- **Format-specific subclasses** (`YAMLData`, `TOMLData`, `JSONData`, `INIData`) unchanged — they continue to use their own `show()` implementations

### References

- **Full spec**: `specs/toml-yaml/ConfigurationDataShow.md`
- **Working demo**: `toolbox/examples/ConfigurationDataDemo.m` (lines 21-24)
- **Tests**: `tests/configdataTest.m`

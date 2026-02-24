# #4: Parser should support mappings inside flow sequences

**State:** closed  
**Created:** 2026-01-14  
**Closed:** 2026-01-14  

## Description

# Parser should support mappings inside flow sequences

## Summary
When reading YAML that uses **mappings inside a flow sequence**, the parser returns a list of strings instead of a structured mapping-like object. Since the parser exposes a `YAMLData` type (largely struct-like), users expect items like `timeout: 30` to be parsed as key/value pairs, not as the literal string `"timeout: 30"`.

## Example YAML
```yaml
# mappings.yaml
settings: [timeout: 30, retries: 3, debug: true]
```

## Current Behavior
```matlab
m = readyaml("mappings.yaml");

% What users currently get
m.settings

ans = 

  3×1 string array

    "timeout: 30"
    "retries: 3"
    "debug: true"
```

## Expected Behavior
`settings` should be parsed as a collection of key/value pairs available via the `YAMLData` interface (not as strings). For example:

```matlab
m = readyaml("mappings.yaml");

% What users expect
m.settings

ans = 

  YAMLData with keys:
       timeout: 30
       retries: 3
       debug: true
```

This matches how YAML flow sequences containing mappings are typically interpreted—i.e.,

```yaml
settings:
  - {timeout: 30}
  - {retries: 3}
  - {debug: true}
```

…which conceptually corresponds to a list of one-pair mappings, not strings.

## Rationale
- Improves consistency with user expectations for YAML key/value data.
- Aligns behavior between flow style (`[ ... ]`) and block style, reducing surprises.
- Keeps `YAMLData` semantics “struct-like,” enabling property-style access (`m.settings.timeout`).

## Steps to Reproduce
1. Save the example YAML above as `mappings.yaml`.
2. In MATLAB, run:
   ```matlab
   m = readyaml("mappings.yaml");
   m.settings
   ```
3. Observe that `m.settings` is a string array rather than a `YAMLData` mapping.

## Proposed Change
- Update the parser to detect and correctly parse **mapping nodes inside flow sequences**. Specifically:
  - When tokenizing items within `[...]`, if an item contains a key separator `:` (outside quotes), parse it as a mapping node rather than a scalar string.
  - Construct a `YAMLData` (or `YAMLData`-compatible) object for each mapping item.
  - Optionally, if all items are single-pair mappings with unique keys, allow collapsing into a single `YAMLData` mapping, so that `m.settings.timeout` is valid.

### Backward Compatibility Considerations
- If existing users rely on the current string-array behavior, consider a parser option:
  - `FlowMappingBehavior = "strings" | "mappings" (default)`
- Emit a warning when encountering ambiguous cases (e.g., quoted items like `"timeout: 30"` should remain strings).

## Acceptance Criteria
- Given `settings: [timeout: 30, retries: 3, debug: true]`:
  - `m.settings` is a `YAMLData` (mapping-like) object exposing keys `timeout`, `retries`, and `debug`.
  - `m.settings.timeout` returns `30` (numeric).
  - `m.settings.debug` returns logical `true`.
- Given quoted forms (e.g., `"timeout: 30"`), items remain strings.
- Unit tests cover: flow sequence of mappings, block sequence of mappings, and single block mapping; all yield consistent, struct-like access via `YAMLData`.

## Additional Notes
- Please document in the README and function help that mappings inside flow sequences are parsed as mappings, not strings, and provide examples for both flow and block styles.


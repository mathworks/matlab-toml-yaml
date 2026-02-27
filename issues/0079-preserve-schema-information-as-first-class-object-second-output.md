# #79: Preserve schema information as a first-class object (second output)

**State:** open
**Created:** 2026-02-27
**Labels:** enhancement, design, round-tripping

## Description

## Background

Current YAML/TOML round-tripping can lose schema information:
- Scalar vs. array distinction (MATLAB treats `5` and `[5]` identically)
- Intended array-ness for empty or single-element arrays
- Original nesting structure intentions
- Type hints that matter for serialization

This information is often critical for configuration files where schemas are strict (e.g., CI/CD configs, API specs).

## Proposal

Design a read/write workflow where schema information is preserved explicitly through a second output argument.

### API Design

```matlab
% Reading with schema capture
[data, schema] = readyaml('config.yaml');
[data, schema] = readtoml('config.toml');

% Writing with schema preservation
writeyaml(data, 'output.yaml', schema);
writetoml(data, 'output.toml', schema);
```

### Schema Object Requirements

The schema object should:
1. **Mirror the data hierarchy**: Same key structure as the data
2. **Capture type metadata**:
   - Scalar vs. array distinction
   - Array dimensions and intended shape
   - Empty array markers
   - Nesting depth and structure
3. **Be itself hierarchical**: Ideally represented as a YAML/TOML-like object for consistency
4. **Be optional**: If not provided to writer, fall back to current heuristics

### Example

```yaml
# Original YAML
ports: [8080]
tags: []
settings:
  timeout: 30
```

```matlab
% After reading
data.ports = 8080;           % Scalar in MATLAB
data.tags = [];              % Empty
data.settings.timeout = 30;

% Schema captures intent
schema.ports.type = 'array';
schema.ports.minLength = 1;
schema.tags.type = 'array';
schema.tags.minLength = 0;
schema.settings.timeout.type = 'scalar';

% Writing with schema preserves structure
writeyaml(data, 'out.yaml', schema);
% => ports: [8080]
% => tags: []
% => settings:
% =>   timeout: 30
```

## Design Questions

1. **Schema representation**:
   - Use a `SchemaData` class (similar to `ConfigurationData`)?
   - Use plain struct with metadata fields?
   - Use a separate schema format (JSON Schema, custom)?

2. **Granularity**: What level of detail should the schema capture?
   - Just array-ness?
   - Full type information (string vs. number)?
   - Validation rules?

3. **Default behavior**: When no schema is provided:
   - Use current heuristics (backward compatible)
   - Emit warning about potential schema loss?

4. **Automatic schema inference**: Should `readyaml` always return schema, or only on request?

5. **Schema editing**: Should users be able to modify the schema directly?

6. **Failure modes**: What happens when data and schema are inconsistent?
   - Validation errors?
   - Schema takes precedence?
   - Data takes precedence?

## Implementation Considerations

- Schema should be lightweight and not duplicate data
- Must handle nested objects and arrays of objects
- Should support partial schemas (only specify what matters)
- Consider performance impact of dual-output reading

## Related Issues

- #48: Fix JSON support for preserving scalar arrays
- #46: Fix JSON support for arbitrary keys
- #50: Preserve order of keys in round-trip read/write JSON
- #27: Arrays with 1 element do not round-trip through readyaml and writeyaml
- #70: Design question: format-specific types vs. generic hierarchical type

## Success Criteria

- Round-trip preservation: `readyaml` + `writeyaml` with schema produces byte-identical output
- User-friendly API that feels natural in MATLAB
- Minimal performance overhead when schema is not used
- Clear documentation of schema structure and usage

# Documentation Notes

## Existing Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| README.md | Project root | User-facing quick start and overview |
| GettingStarted.mlx | Project root | Interactive MATLAB tutorial |
| examples/*.m | examples/ | Runnable example scripts |
| Claude/*.md | Claude/ | Development documentation and design decisions |

## Documentation Deliverables

- [ ] Function reference pages (readyaml, writeyaml, readtoml, writetoml)
- [ ] Class reference page (ConfigurationData, YAMLData, TOMLData) with `matlab.io.config` namespace
- [ ] Note on informal vs formal interface (`yamldata` vs `matlab.io.config.YAMLData`)
- [ ] Round-trip behavior guide: SequenceRule tradeoffs with concrete examples
- [ ] "Working with YAML Data" example
- [ ] "Working with TOML Data" example
- [ ] Limitations and troubleshooting guide

## Key Documentation Points

1. **Minimum MATLAB Version:** R2022b (for dictionary support)
2. **Subset Parser:** Not full YAML 1.2 or TOML 1.0 compliance
3. **Value Semantics:** Assignment creates copies (unlike handle classes)
4. **Special Characters:** Use `("key-name")` syntax for keys with hyphens
5. **Round-Trip:** Data preserved, but comments and formatting may change; single-element arrays may become scalars with default `SequenceRule="auto"`
6. **Method Calls:** Use function syntax — `keys(config)`, not `config.keys`
7. **Reserved Key:** `xInternal__` cannot be used as a configuration key

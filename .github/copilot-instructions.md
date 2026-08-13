# Copilot instructions for ConfigurationFileIO

Goal: Help an AI coding assistant be immediately productive in this MATLAB toolbox.

Key project facts
- Language: MATLAB (R2019b+). No external toolboxes required.
- Primary purpose: Read/write YAML and TOML with MATLAB-style dot access.
- Main API files: `toolbox/readtoml.m`, `toolbox/writetoml.m`, `toolbox/readyaml.m`, `toolbox/writeyaml.m`, `toolbox/TOMLData.m`, `toolbox/YAMLData.m`, `toolbox/ConfigurationData.m`.

Big-picture architecture
- `ConfigurationData` is the base container; `TOMLData` and `YAMLData` extend it and provide format-specific behavior (ordering, datetimes, inline tables).
- I/O functions (`read*`/`write*`) produce/consume the data objects. Modification is done via dot-notation on those objects, then written back.
- Key aliasing: original keys (with hyphens/spaces) are preserved, but MATLAB-valid aliases are provided for convenience.

Important patterns & gotchas
- Dot notation + dynamic field names: prefer `config.field` for simple keys and `config.("build-system")` for keys with hyphens/spaces.
- Handle-class semantics: `TOMLData` and `YAMLData` are handle classes. Assignment creates references; use `copy` to create independent copies.
- Use `obj.show` to preview serialized output without writing files.
- Arrays are auto-typed; control output with writer options: `ArrayStyle`, `NumIndentationSpaces`, `SectionSpacing`, `Precision`, `SequenceRule`.

Developer workflows (quick commands)
- Add toolbox to MATLAB path:
  addpath('path/to/ConfigurationFileIO/toolbox')
- Open the project: `ConfigurationFileIO.prj` (recommended for MATLAB IDE use).
- Run examples interactively: open files in `examples/` (e.g. `readtomlExample.m`, `writetomlExample.m`) or run them from MATLAB.
- Run individual tests/scripts from terminal (MATLAB must be installed):
  matlab -batch "run('tests/tomltest.m')"
  matlab -batch "run('tests/yamltest.m')"

Integration & important files to inspect first
- `toolbox/ConfigurationData.m` — base behavior (aliasing, keys, storage).
- `toolbox/TOMLData.m` and `toolbox/YAMLData.m` — format specifics (datetime, ordering).
- `toolbox/readtoml.m` / `toolbox/readyaml.m` — parsers and conversion entrypoints.
- `toolbox/writetoml.m` / `toolbox/writeyaml.m` — writer options and formatting knobs.
- `examples/` — real-world sample files: `pyproject_complex.toml`, `github-actions-ci.yaml`, `kubernetes-*.yaml`.

What to modify or suggest when editing code
- Preserve insertion-order behavior and alias maps when refactoring: tests and file round-trip depend on stable order.
- When changing API surfaces, update `toolbox/doc/*.md` and examples under `examples/`.
- Prefer small, local changes; respect handle/reference semantics (use `copy` where mutation should not be global).

Pull requests and CI hints
- CI workflows are example-based in `examples/` (see `github-actions-ci.yaml`). Tests are simple .m scripts; CI should call `matlab -batch` to run them.

If you need more
- Read `README.md` for a full quickstart and options reference.

Questions for the maintainer
- Which MATLAB versions are validated in CI? (README lists R2019b+, but exact matrix helps.)
- Any preferred MATLAB command-line flags for CI runs (display/logging preferences)?

Repository rules
- Follow the rules published at https://github.com/matlab/rules for coding conduct, contribution guidelines, licensing, and security practices. When making edits or suggestions, ensure changes align with those rules (style, attribution, privacy). If a rule conflicts with a requested change, flag it for the maintainer instead of applying it unilaterally.

End of instructions.

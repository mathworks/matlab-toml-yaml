# Requirements Analysis

## User Roles and Goals

| **ID** | **Priority** | **User Role** | **User Goal** | **Notes** |
|--------|--------------|---------------|---------------|-----------|
| RG_Platform | HIGH | Platform Engineer / Toolbox Author | Programmatically generate CI/CD workflow files (GitHub Actions YAML) from MATLAB — project setup tools, release automation, bulk config updates | Primary driver for YAML write support |
| RG_PYTHON_INTEROP | HIGH | MATLAB Power User | Access Python project metadata from pyproject.toml and MATLAB project metadata from matlab.toml in MATLAB workflows | Primary driver for TOML support |
| RG_ML_RESEARCHER | HIGH | ML/AI Researcher | Store and load experiment hyperparameter configurations in YAML for reproducible ML workflows | Common in Python-style ML pipelines migrated to MATLAB |
| RG_CONFIG_MGMT | MEDIUM | Application Developer | Store application settings in human-readable config files | Supports YAML and TOML |
| RG_CONTAINER | MEDIUM | Platform Engineer | Programmatically generate Docker Compose configurations | YAML with complex nesting |
| RG_DEVOPS_MATLAB | MEDIUM | DevOps/MATLAB Engineer | Manage YAML configs for MATLAB server deployments (MATLAB Online Server, Production Server, Parallel Server on Kubernetes) | Deployment configs are YAML |

## Use Cases

### Use Case UC_PIPELINE_GENERATION

| **User Role** | Platform Engineer / Toolbox Author (RG_Platform) |
|---------------|--------------------------------------------------|

CI/CD pipeline configuration needs to be **generated programmatically**. Examples:

- A **project setup tool** that inspects a MATLAB project (which toolboxes it uses, which MATLAB versions it targets) and emits a ready-to-use `.github/workflows/ci.yaml` tailored to that project — driven by MATLAB logic, not hand-authoring
- A **bulk update script** that reads existing workflow files across many repositories, modifies the test matrix (e.g., adds a new MATLAB release), and writes them back — automation at scale rather than repeated manual editing
- A **toolbox packaging tool** that generates CI workflows as part of a release pipeline, filling in project-specific values (name, test paths, artifact names) from MATLAB data structures

MathWorks' [`ci-configuration-examples`](https://github.com/mathworks/ci-configuration-examples) provides static YAML templates today; this toolbox enables MATLAB code to generate them dynamically. GitHub Actions uses YAML throughout, so YAML write support is the key capability here.

**Concrete example — a typical GitHub Actions workflow:**

```yaml
name: MATLAB CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        matlab-version: [ R2023b, R2024a, R2024b ]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup MATLAB
        uses: matlab-actions/setup-matlab@v2
        with:
          release: ${{ matrix.matlab-version }}
      - name: Run tests
        uses: matlab-actions/run-tests@v2
```

A platform engineer wants to read this file, add `R2025a` to the test matrix, and write it back — entirely from a MATLAB script that manages a collection of repositories. They also want to generate new workflow files from scratch for newly created toolboxes, populating values from MATLAB data.

**Current workarounds and their pain:**

Today, MATLAB developers generating YAML either switch to Python/shell, or build YAML via string operations:

```matlab
% Today: brittle string assembly
yaml = sprintf('name: %s\njobs:\n  test:\n    runs-on: ubuntu-latest\n', projectName);
fid = fopen('.github/workflows/ci.yaml', 'w');
fprintf(fid, '%s', yaml);
fclose(fid);
```

This approach has no structure: there is no way to navigate into the document, validate nesting, or safely insert into an existing file. Any modification to an existing workflow means parsing it manually or regenerating it from scratch.

| Step | **Current Workflow** | **Pain Point ID(s)** |
|------|---------------------|---------------------|
| 1 | Need to generate or update a workflow file from MATLAB logic | PP_NO_YAML_WRITE |
| 2 | Construct YAML as a string with `sprintf` or write via Python | PP_FRAGILE |
| 3 | Validate output by committing and pushing | PP_NO_LOCAL_GEN |

**Pain Points:**
- **PP_NO_YAML_WRITE:** No native MATLAB way to construct and write structured YAML
- **PP_FRAGILE:** String-based YAML generation is brittle and hard to maintain
- **PP_NO_LOCAL_GEN:** Cannot generate, validate, or preview structured config files locally from within MATLAB

**Format features required by this use case:**

| YAML construct | Where it appears | Requirement |
|----------------|-----------------|-------------|
| Read YAML | Load existing workflow for modification | R_READ_YAML |
| Write YAML | Generate and save workflow files | R_WRITE_YAML |
| Nested mappings | `jobs` → `test` → `strategy` → `matrix` | RY_MAPPINGS |
| Sequences (flow style) | `branches: [ main, develop ]`, `matlab-version: [ R2023b, ... ]` | RY_SEQUENCES |
| Sequences (block style) | `steps:` list | RY_SEQUENCES |
| Sequence of mappings | Each entry under `steps:` is a structured record | RY_SEQ_OF_MAPS |
| Hyphenated keys | `runs-on`, `pull_request`, `matlab-version` | R_SPECIAL_CHARS |
| Data round-trip | Read → add release → write back | R_ROUNDTRIP |
| Formatting control | Generate files that match GitHub Actions conventions | R_FORMAT_OPTIONS |

---

### Use Case UC_ML_EXPERIMENTS

| **User Role** | ML/AI Researcher (RG_ML_RESEARCHER) |
|---------------|--------------------------------------|

Data scientists running MATLAB alongside Python ML tooling use YAML configuration files to define hyperparameters, model architectures, and training schedules. This pattern is standard in the Python ML ecosystem (Hydra, W&B, Kubernetes-style operator configs) and increasingly used by MATLAB researchers working in hybrid environments.

**Concrete example — a Hydra-style experiment config:**

```yaml
model:
  architecture: resnet50
  pretrained: true
  num_classes: 10

training:
  learning_rate: 0.001
  epochs: 100
  batch_size: 32
  optimizer: adam

data:
  dataset: cifar10
  augmentation: true
  splits:
    train: 0.8
    val: 0.1
    test: 0.1
```

The researcher wants to run a learning rate sweep: load the baseline config, vary `training.learning_rate` across a range, run each experiment, and save the variant config alongside the results so the experiment is reproducible. They also want to compare results across runs by loading the saved configs back into MATLAB.

This workflow is entirely driven by YAML — the config file is the contract between the researcher and the training code. MATLAB has no native way to participate.

**Current workarounds and their pain:**

The researcher either maintains a Python script to convert YAML to a `.mat` file before running MATLAB, or duplicates config values between a YAML file (for the Python side) and hardcoded MATLAB variables (for the MATLAB side). Neither approach is reproducible: the `.mat` file is not human-readable, and hardcoded values drift out of sync with the YAML.

| Step | **Current Workflow** | **Pain Point ID(s)** |
|------|---------------------|---------------------|
| 1 | Write hyperparameter config in YAML | PP_NO_YAML |
| 2 | Load config from Python, pass to MATLAB | PP_WORKAROUND |
| 3 | Run experiment, log results | PP_NOT_REPRODUCIBLE |

**Pain Points:**
- **PP_NO_YAML:** MATLAB cannot natively read YAML experiment configs
- **PP_WORKAROUND:** Requires Python interop or format conversion
- **PP_NOT_REPRODUCIBLE:** Hard to load/save configs programmatically for experiment tracking

**Format features required by this use case:**

| YAML construct | Where it appears | Requirement |
|----------------|-----------------|-------------|
| Read YAML | Load experiment configs | R_READ_YAML |
| Write YAML | Save config variants alongside results | R_WRITE_YAML |
| Nested mappings | `model`, `training`, `data`, `splits` sections | RY_MAPPINGS |
| Scalar types | Strings, booleans, integers, floats throughout | RY_SCALARS |
| Data round-trip | Load → modify one value → save variant | R_ROUNDTRIP |

---

### Use Case UC_PYPROJECT

| **User Role** | MATLAB Power User (RG_PYTHON_INTEROP) |
|---------------|---------------------------------------|

Python projects that interop with MATLAB describe their metadata in `pyproject.toml`. MATLAB toolbox projects will soon have an analogous `matlab.toml`. MATLAB developers working in these mixed-language environments need to read and write these files from MATLAB — for build scripts, release tools, and dependency management.

**Concrete example — a fragment of `pyproject.toml`:**

```toml
[build-system]
requires = ["setuptools>=65.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-matlab-python-bridge"
version = "0.1.0"
requires-python = ">=3.9"
dependencies = ["numpy>=1.23", "scipy"]

[[project.authors]]
name = "Jane Smith"
email = "jane@example.com"

[[project.authors]]
name = "John Doe"
```

A MATLAB build script needs to extract the project name and version to stamp release artifacts, check the Python version constraint for compatibility, and read the author list to populate release notes — without leaving MATLAB.

**Current workarounds and their pain:**

MATLAB has no TOML reader. The workaround is to call a Python subprocess to convert the file to JSON, then read the JSON into MATLAB with `jsondecode`. This loses comments, requires Python to be installed and configured, and adds a subprocess call to what should be a simple file read. Alternatively, users write a custom line-by-line parser — fragile and project-specific.

| Step | **Current Workflow** | **Pain Point ID(s)** |
|------|---------------------|---------------------|
| 1 | Need to read Python package metadata from `pyproject.toml` | PP_NO_TOML |
| 2 | Call Python subprocess to convert TOML to JSON | PP_WORKAROUND |
| 3 | Read JSON into MATLAB | PP_DATA_LOSS |

**Pain Points:**
- **PP_NO_TOML:** MATLAB has no native TOML support
- **PP_WORKAROUND:** Requires external tools or manual parsing
- **PP_DATA_LOSS:** Conversion loses structure and comments

**Format features required by this use case:**

| TOML construct | Where it appears | Requirement |
|----------------|-----------------|-------------|
| Read TOML | Load project metadata | R_READ_TOML |
| Standard tables | `[build-system]`, `[project]` | RT_TABLES |
| Arrays | `requires = [...]`, `dependencies = [...]` | RT_ARRAYS |
| Array of tables | `[[project.authors]]` — one entry per author | RT_ARRAY_OF_TABLES |
| Dotted table names | `[project.urls]`, `[tool.ruff.lint]` | RT_TABLES |
| Hyphenated keys | `[build-system]`, `build-backend`, `requires-python` | R_SPECIAL_CHARS, RT_HYPHEN_KEYS |
| Scalar types | Strings, version numbers | RT_SCALARS |

---

### Use Case UC_APP_CONFIG

| **User Role** | Application Developer (RG_CONFIG_MGMT) |
|---------------|----------------------------------------|

MATLAB applications that need to be configured by end users or system administrators benefit from a human-readable config file. The user may not be a MATLAB programmer — they just need to adjust settings like server addresses, thresholds, or file paths without touching code.

**Concrete example — a MATLAB application config:**

```yaml
server:
  host: production.example.com
  port: 8443
  timeout: 30

logging:
  level: info
  output: /var/log/myapp.log
  max-size-mb: 100

processing:
  batch-size: 256
  parallel-workers: 4
  output-dir: /data/results
```

The application reads this file at startup, applies the settings, and the administrator can change them without a MATLAB license or code change. The developer also wants to save a modified config back (e.g., after an auto-tuning run) and have the result be a readable YAML file — not a binary `.mat`.

**Current workarounds and their pain:**

Application configuration in MATLAB today is typically stored in `.mat` files (binary, unreadable without MATLAB), hardcoded constants in `.m` files (requires code changes and re-deployment), or JSON files (readable but verbose and awkward for config). None of these are human-friendly for administrators to edit directly.

| Step | **Current Workflow** | **Pain Point ID(s)** |
|------|---------------------|---------------------|
| 1 | Store config as `.mat` file or hardcoded constants | PP_NOT_EDITABLE |
| 2 | Load config at runtime | PP_NOT_PORTABLE |
| 3 | Share config with non-MATLAB users or system administrators | PP_INTEROP |

**Pain Points:**
- **PP_NOT_EDITABLE:** Users cannot easily modify configuration without MATLAB
- **PP_NOT_PORTABLE:** `.mat` files not readable or editable outside MATLAB
- **PP_INTEROP:** JSON/XML are verbose and unfamiliar for human-authored config

**Format features required by this use case:**

| YAML construct | Where it appears | Requirement |
|----------------|-----------------|-------------|
| Read YAML | Load config at application startup | R_READ_YAML |
| Write YAML | Save auto-tuned config back to file | R_WRITE_YAML |
| Nested mappings | `server`, `logging`, `processing` sections | RY_MAPPINGS |
| Scalar types | Strings, integers, file paths throughout | RY_SCALARS |
| Hyphenated keys | `max-size-mb`, `batch-size`, `parallel-workers`, `output-dir` | R_SPECIAL_CHARS |
| Data round-trip | Load → auto-tune → write readable result | R_ROUNDTRIP |
| Formatting control | Output should be human-readable for administrators | R_FORMAT_OPTIONS |

---

### Use Case UC_DEVOPS_INFRA

| **User Role** | DevOps/MATLAB Engineer (RG_DEVOPS_MATLAB) |
|---------------|-------------------------------------------|

MathWorks products including MATLAB Online Server, MATLAB Parallel Server, and MATLAB Production Server deploy on Kubernetes using YAML manifests and Helm values files. Platform engineers managing these deployments want to script configuration changes from within MATLAB rather than context-switching to shell or Python.

**Concrete example — a Kubernetes deployment fragment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: matlab-production-server
  namespace: matlab-production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: matlab-server
  template:
    spec:
      containers:
        - name: matlab-server
          image: mathworks/matlab-production-server:R2024b
          resources:
            requests:
              memory: 8Gi
              cpu: "4"
            limits:
              memory: 16Gi
              cpu: "8"
```

A platform engineer wants to scale up the deployment (change `replicas`), update the container image to a new release, and adjust resource limits — all from a MATLAB script that manages a fleet of deployments. They may also generate Helm `values.yaml` files tailored to each deployment environment from a MATLAB data model of their infrastructure.

**Current workarounds and their pain:**

Platform engineers context-switch to shell or Python to edit these files, then return to MATLAB to run validation or analysis. There is no way to script the full workflow — read the current config, apply a change, write back, trigger a re-deployment — from a single MATLAB session.

| Step | **Current Workflow** | **Pain Point ID(s)** |
|------|---------------------|---------------------|
| 1 | Need to modify a Kubernetes deployment YAML | PP_MANUAL_EDIT |
| 2 | Context-switch to shell or Python to edit the file | PP_CONTEXT_SWITCH |
| 3 | Re-apply and iterate | PP_SLOW_ITERATION |

**Pain Points:**
- **PP_CONTEXT_SWITCH:** Must leave MATLAB to edit deployment configs
- **PP_SLOW_ITERATION:** No programmatic generation of deployment configurations from MATLAB

**Format features required by this use case:**

| YAML construct | Where it appears | Requirement |
|----------------|-----------------|-------------|
| Read YAML | Load current deployment config | R_READ_YAML |
| Write YAML | Save modified deployment config | R_WRITE_YAML |
| Deeply nested mappings | `spec` → `template` → `spec` → `containers` → `resources` | RY_MAPPINGS |
| Sequence of mappings | `containers:` list — each container is a structured record | RY_SEQ_OF_MAPS |
| Scalar types | Strings, integers, quoted strings (`"4"`, `"8"`) | RY_SCALARS |
| Data round-trip | Read → change replica count or image tag → write back | R_ROUNDTRIP |

---


## Benchmarks

Benchmarking existing YAML/TOML implementations in Python and MATLAB informed the central design question: **how much fidelity should we target through a read-modify-write cycle?** Three levels of fidelity are possible, each representing a significant jump in implementation complexity:

| Level | What it preserves | Implication |
|-------|-------------------|-------------|
| **Basic reader** | Data values only; write support absent or limited | Useful for one-way data extraction; cannot support modify-and-write-back workflows |
| **Data round-trip** | All data values and types; comments and formatting may change | Supports all read-modify-write use cases; the de facto standard for config tooling |
| **Perfect round-trip** | Comments, whitespace, key ordering, blank lines — structural fidelity | Required only when human-readable formatting or comments must survive automation |

The implementations below were examined to calibrate which level to target.

---

### Category: Basic parsers and single-direction readers

#### [matlab-toml](https://www.mathworks.com/matlabcentral/fileexchange/67858-matlab-toml) (File Exchange #67858)

A MATLAB TOML parser with 609 downloads and 2.0 stars (3 reviews). Read-focused: it parses TOML into MATLAB data structures, but write support is limited and was never a design priority.

**Key limitations:**
- **Requires unrelated toolboxes** as dependencies, adding installation friction for users who don't already have them
- **Returns `containers.Map`** for TOML tables, which produces awkward workflows: `containers.Map` is a handle class (not value semantics), so copies are not independent; access requires `map('key')` syntax rather than dot notation; and iteration is cumbersome
- **No special-character key support** — keys with hyphens (`build-system`, `x-custom-header`) cannot be represented in `containers.Map` without custom handling
- **No updates since May 2023**, 8 open GitHub issues as of February 2026

**Lesson:** `containers.Map` is the wrong return type for config data. It leaks implementation details, breaks value semantics, and makes common operations awkward.

#### [tomllib](https://docs.python.org/3/library/tomllib.html) (Python stdlib, Python 3.11+)

Python's built-in TOML reader, added in 3.11. Intentionally read-only by design — the stdlib maintainers explicitly chose not to include a writer, on the grounds that TOML files are usually hand-authored and should not be machine-rewritten.

**Key limitations:**
- Read-only: no write support at all
- Available only in Python 3.11+; earlier versions need the third-party [`tomli`](https://pypi.org/project/tomli/) package

**Lesson:** Read-only is a valid choice for some tools (e.g., a build system that only reads `pyproject.toml`), but does not serve use cases that need to construct or modify configuration programmatically.

---

### Category: Data round-trip implementations

#### [readstruct / writestruct](https://www.mathworks.com/help/matlab/ref/readstruct.html) with JSON (MATLAB built-in, R2021b+)

MATLAB's built-in structured data I/O. `readstruct` and `writestruct` support XML and JSON backends. With the JSON backend, they provide data round-trip fidelity for structured config data natively in MATLAB.

**Capabilities:**
- No external dependencies
- Supports nested structures with dot notation (via struct fields)
- JSON backend provides data type preservation

**Limitations:**
- JSON only — no YAML or TOML support
- Returns plain `struct`, which has specific ergonomic limitations:
  - **Keys with special characters are silently coerced** to valid MATLAB identifiers (e.g., `key-name` becomes `key_name`), with no way to recover the original key on write-back — the round-trip is structurally lossy for such keys
  - **Arrays of objects become struct arrays**, which return comma-separated lists when indexed across the array (e.g., `s.field` returns a comma-separated list, not an array). Extracting values into a typed array requires an extra step, and writing modified values back typically requires `arrayfun`
- **Single-element arrays lose their arrayness**: a JSON array `[5]` reads back as scalar `5`, not `[5]`

**Lesson:** `readstruct`/`writestruct` shows that MATLAB users do want structured read/write I/O and that MATLAB's struct type is the obvious baseline return type. The gap is format support (YAML, TOML) and ergonomics for edge cases (special-character keys, array fidelity).

#### [MartinKoch123/yaml](https://www.mathworks.com/matlabcentral/fileexchange/106765-yaml) (File Exchange #106765)

The most widely-used MATLAB YAML implementation, with 3.4K downloads and 5.0 stars (2 reviews). Actively maintained (v1.6, October 2024). Targets data round-trip fidelity.

**Capabilities:**
- YAML 1.1 support with bidirectional read/write
- Handles nested structures and arrays
- Actively maintained

**Limitations:**
- **Requires Java SnakeYAML** — the parser is built on top of the Java SnakeYAML library, which must be on the Java classpath. This works in desktop MATLAB but can fail in headless or deployed environments and introduces a non-MATLAB dependency
- **Returns plain structs** — same limitations as `readstruct`: no dot notation for special-character keys, no structural inspection methods

**Lesson:** The community has converged on this as the best available YAML option for MATLAB, but the Java dependency is a friction point and plain structs leave ergonomic gaps. A pure-MATLAB implementation returning a more capable object type is a meaningful improvement.

#### [PyYAML](https://pyyaml.org/) (Python)

The dominant Python YAML library with hundreds of millions of monthly downloads. Provides `yaml.safe_load()` for reading and `yaml.dump()` for writing.

**Capabilities:**
- Full YAML 1.1 support
- `yaml.dump(yaml.safe_load(text))` preserves all data values and types

**Round-trip behavior:**
- Data values are preserved exactly
- Comments are discarded
- Key ordering may change (depends on Python version and YAML version)
- Formatting and whitespace are normalized to PyYAML's defaults

This is the de facto standard for config file tooling in Python. PyYAML's authors made a deliberate choice not to target comment preservation — the added complexity was not justified for the primary use cases.

**Lesson:** Data round-trip fidelity is the right target. PyYAML's widespread adoption with this behavior validates that users accept comment loss in programmatic workflows.

---

### Category: Perfect round-trip

#### [ruamel.yaml](https://yaml.readthedocs.io/en/latest/) (Python)

A Python YAML library specifically designed for round-trip preservation. Uses `YAML(typ='rt')` (round-trip) mode to build a comment-preserving AST.

**Capabilities:**
- Preserves comments, blank lines, key ordering, flow/block style per node
- Near byte-for-byte fidelity through a round-trip

**Cost:**
- Substantially more complex to use: the round-trip mode returns special `CommentedMap` and `CommentedSeq` objects rather than plain dicts and lists; code that processes the output must handle these types
- The library itself is significantly larger and more complex than PyYAML (the codebase is roughly 5× larger)
- Used primarily in tools where comment preservation is a hard requirement (e.g., `pip-tools`, `conda`)

**Lesson:** Perfect round-trip is achievable but costly. It is the right choice only when comments must survive automation — for example, tooling that edits config files that humans also maintain by hand and care about keeping their comments intact. For our use cases, data fidelity is sufficient.

---

### Summary of Findings

The benchmarks suggest several conclusions that informed requirements:

1. **Data round-trip fidelity is the right target.** PyYAML's widespread adoption demonstrates that users accept comment loss in programmatic workflows. The added complexity of perfect round-trip (as seen in `ruamel.yaml`) is not justified for config file tooling.

2. **Plain struct is not sufficient as a return type.** Both `readstruct`/`writestruct` and the MATLAB File Exchange submissions return plain structs, and each hits the same walls: special-character keys require silent coercion, struct array indexing is awkward, and there is no method layer for validation or inspection. A value class with dot notation addresses these gaps.

## Requirements

### Common Requirements

These apply to both YAML and TOML support.

| **ID** | **Statement** | **Pain Point ID(s)** | **Priority** |
|--------|---------------|---------------------|--------------|
| R_ACCESS | Users can access nested configuration values using natural MATLAB expressions | PP_ERROR_PRONE | MUST HAVE |
| R_SPECIAL_CHARS | Keys with hyphens and other characters not valid as MATLAB identifiers must be accessible — such keys are ubiquitous in real YAML and TOML files (`runs-on`, `build-system`, `pull-request`) | PP_ERROR_PRONE | MUST HAVE |
| R_ROUNDTRIP | Data values must be preserved through read → modify → write cycles | PP_DATA_LOSS | MUST HAVE |
| R_SCALAR_ARRAY | Users can preserve the distinction between a scalar value and a single-element array when that distinction matters for the downstream tool consuming the file | PP_DATA_LOSS | MUST HAVE |
| R_COPY_INDEPENDENCE | Copying configuration data in MATLAB must produce an independent copy — assigning to a new variable and modifying it must not affect the original | PP_ERROR_PRONE | MUST HAVE |
| R_DESCRIBE | Users can get a structural overview of what a configuration object contains | — | NICE TO HAVE |
| R_FORMAT_OPTIONS | Users can control formatting of generated files (indentation, array style, section spacing) to match the conventions of the target tool or project | PP_NOT_EDITABLE | NICE TO HAVE |
| R_PERFORMANCE | Typical config files (<1MB) must load and save in a reasonable time | — | MUST HAVE |
| R_NO_DEPS | No external dependencies — pure MATLAB, no Java libraries, MEX files, or toolbox requirements | — | MUST HAVE |
| R_COMMENT_PRESERVE | Preserve comments through a round-trip | — | OUT OF SCOPE |

### YAML Requirements

These requirements define what YAML content the toolbox must handle. The goal is to cover the patterns found in real-world CI/CD, container orchestration, and ML experiment config files — not full YAML 1.2 compliance.


| **ID** | **Statement** | **Priority** |
|--------|---------------|--------------|
| R_READ_YAML | Users can load YAML configuration files into MATLAB for programmatic access and manipulation | PP_MANUAL_EDIT, PP_NO_YAML | MUST HAVE |
| R_WRITE_YAML | Users can write YAML configuration files from MATLAB data | PP_MANUAL_EDIT, PP_FRAGILE | MUST HAVE |
| RY_SCALARS | Read and write all common YAML scalar types: strings (quoted and unquoted), booleans (`true`/`false`, `yes`/`no`), integers, floats, and null | MUST HAVE |
| RY_MAPPINGS | Read and write nested mappings of arbitrary depth | MUST HAVE |
| RY_SEQUENCES | Read and write sequences in both block style (`- item`) and flow style (`[a, b, c]`) | MUST HAVE |
| RY_SEQ_OF_MAPS | Read and write sequences of mappings — the pattern used for GitHub Actions `steps:`, Docker Compose `services:`, and Kubernetes containers | MUST HAVE |
| RY_MIXED_SEQ | Read sequences containing mixed value types (heterogeneous arrays) | MUST HAVE |
| RY_COMMENTS | Parse and ignore YAML comments; comments need not be preserved on write | MUST HAVE |
| RY_GITHUB_ACTIONS | Must correctly read and round-trip a GitHub Actions workflow file, including `runs-on`, `pull-request`, `matrix`, and `steps` patterns | MUST HAVE |
| RY_DOCKER_COMPOSE | Must correctly read and round-trip a Docker Compose file | SHOULD HAVE |
| RY_KUBERNETES | Must correctly read and round-trip a Kubernetes deployment manifest | SHOULD HAVE |

#### Out of Scope

| **ID** | **Statement** |
|--------|---------------|
| RY_ANCHORS | Anchors and aliases (`&anchor`, `*alias`) are not supported |
| RY_MULTIDOC | Multi-document YAML (files with `---` separators) is not supported |
| RY_BLOCK_SCALARS | Literal block scalars (`\|`) and folded scalars (`>`) are not supported |
| RY_TAGS | Custom YAML tags (`!!python/object`, etc.) are not supported |

### TOML Requirements

These requirements define what TOML content the toolbox must handle. The goal is to cover the patterns in `pyproject.toml`, `Cargo.toml`, and the forthcoming `matlab.toml`.


| **ID** | **Statement** | **Priority** |
|--------|---------------|--------------|
| R_READ_TOML | Users can load TOML configuration files into MATLAB for programmatic access and manipulation | PP_NO_TOML | MUST HAVE |
| R_WRITE_TOML | Users can write TOML configuration files from MATLAB data | PP_NO_TOML | MUST HAVE |
| RT_SCALARS | Read and write all TOML scalar types: basic strings, literal strings, integers, floats, booleans, and datetimes | MUST HAVE |
| RT_TABLES | Read and write standard tables (`[section]`) and dotted-key notation (`a.b = value`) | MUST HAVE |
| RT_ARRAYS | Read and write arrays, including multiline arrays | MUST HAVE |
| RT_ARRAY_OF_TABLES | Read and write arrays of tables (`[[section]]`) — used for `[[project.authors]]`, `[[steps]]`, etc. | MUST HAVE |
| RT_INLINE_TABLES | Read inline tables (`{key = value}`) | MUST HAVE |
| RT_STRING_TYPES | Read both basic strings (`"..."`, with escape processing) and literal strings (`'...'`, verbatim) | MUST HAVE |
| RT_HYPHEN_KEYS | Read and write tables with hyphenated names (`[build-system]`, `[build-backend]`) | MUST HAVE |
| RT_PYPROJECT | Must correctly read and round-trip a `pyproject.toml` including `[build-system]`, `[project]`, `[[project.authors]]`, and `[tool.*]` sections | MUST HAVE |
| RT_MATLAB_TOML | Must correctly read and write `matlab.toml` as the format is defined | MUST HAVE |

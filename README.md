# TOML and YAML Toolbox for MATLAB

<img src="images/matlab-toml-yaml.png" alt="TOML and YAML Toolbox for MATLAB" width="200"/>

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=mathworks/matlab-toml-yaml)
[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/XXXXX-toml-and-yaml-toolbox-for-matlab)

The TOML and YAML Toolbox for MATLAB adds support for reading and writing YAML and TOML configuration files with very strong round-trip support. The toolbox includes custom data types that make it easier to work with YAML and TOML data than structures or tables. The implementation is pure MATLAB with no third-party dependencies.

## Features

- **YAML & TOML Support** - Read and write both formats with consistent interface
- **Dot Notation Access** - Natural MATLAB syntax: `config.database.host`
- **Special Characters** - Handle keys with hyphens, spaces: `config.("build-system")`
- **Full Round-Trip** - Read, modify, write back without data loss
- **Implicit Type Conversion** - Automatic conversion to optimal MATLAB types
- **Flexible File Writing** - Control formatting, indentation, array styles

## Installation

Download the latest `.mltbx` file from [Releases](https://github.com/mathworks/matlab-toml-yaml/releases) and double-click it in MATLAB, or install programmatically:

```matlab
matlab.addons.toolbox.installToolbox("TOML_and_YAML_Toolbox_for_MATLAB.mltbx")
```

## Quick Start

### Reading Files

```matlab
% Read YAML
config = readyaml("server_config.yaml");
host = config.database.host;

% Read TOML
project = readtoml("simple_project.toml");
name = project.project.name;

% Keys with special characters
deps = project.("build-system").requires;
```

### Writing Files

```matlab
% Create data
config = matlab.io.config.YAMLData;
config.name = "MyApp";
config.database.host = "localhost";
config.database.port = 5432;

% Write YAML
writeyaml(config, "my_config.yaml");

% Write TOML
writetoml(config, "my_config.toml");
```

## Main Functions

### YAML
- `readyaml(filename)` - Read YAML file, returns YAMLData object
- `writeyaml(data, filename)` - Write YAML file
- `YAMLData` - Create YAML data object

### TOML
- `readtoml(filename)` - Read TOML file, returns TOMLData object
- `writetoml(data, filename)` - Write TOML file
- `TOMLData` - Create TOML data object

## Examples

See `toolbox/doc/GettingStarted.m` for an introductory walkthrough, or explore the `toolbox/examples/` folder:

**YAML Examples:**
- `readyamlExample.m` - Reading YAML files
- `writeyamlExample.m` - Writing YAML files
- `yamlWorkflowExample.m` - End-to-end read/modify/write workflow

**TOML Examples:**
- `readtomlExample.m` - Reading TOML files
- `writetomlExample.m` - Writing TOML files
- `tomlPyprojectExample.m` - Working with `pyproject.toml`

**Demo Scripts:**
- `conversionExample.m` - Converting between structs, dictionaries, and data objects

## Limitations

This toolbox implements a simplified YAML parser optimized for configuration files. It is **not** a full YAML 1.2 compliant parser.

- **YAML**: Subset parser. See [readyaml documentation](toolbox/doc/readyaml.md#limitations) for details on supported/unsupported features (anchors, tags, etc.).
- **TOML**: Array of tables bug in reading (writing works).
- **Chained indexing**: `obj.field(i).subfield` requires extracting array first (e.g. `tmp = obj.field; val = tmp(i).subfield`).
- **Custom tags**: Not supported.

For production use cases requiring full spec compliance (e.g. complex Kubernetes manifests with anchors), consider Java-based libraries.

## Requirements

- MATLAB R2022b or later (for `dictionary` with value semantics)
- No additional toolboxes required

## License

Copyright 2026 The MathWorks, Inc. See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues and pull requests.

---

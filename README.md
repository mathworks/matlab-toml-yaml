# Configuration File I/O Toolbox

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=michellehirsch/matlab-toml-yaml)

MATLAB&reg; has no native support for YAML or TOML configuration files. Most existing solutions require Java dependencies or external toolboxes. This toolbox fills that gap with a pure-MATLAB implementation that works out of the box — no additional setup required.

A unified MATLAB toolbox for reading and writing YAML and TOML configuration files with intuitive dot notation access and full round-trip support.

## Features

- 📄 **YAML & TOML Support** - Read and write both formats with consistent interface
- 🔑 **Dot Notation Access** - Natural MATLAB syntax: `config.database.host`
- 🔤 **Special Characters** - Handle keys with hyphens, spaces: `config.("build-system")`
- 🔄 **Full Round-Trip** - Read, modify, write back without data loss
- 📊 **Smart Arrays** - Automatic conversion to optimal MATLAB types
- 🎨 **Customizable Output** - Control formatting, indentation, array styles
- 💪 **GitHub Actions Ready** - Properly handles workflow files and sequences

## Installation

Add the toolbox to your MATLAB path:

```matlab
addpath('/path/to/ConfigurationFileIO/toolbox')
```

Or use the MATLAB Project file `ConfigurationFileIO.prj`.

## Quick Start

### Reading Files

```matlab
% Read YAML
config = readyaml('config.yaml');
host = config.database.host;

% Read TOML
project = readtoml('pyproject.toml');
name = project.project.name;

% Keys with special characters
deps = config.("build-system").requires;
```

### Writing Files

```matlab
% Create data
config = YAMLData;
config.name = 'MyApp';
config.database.host = 'localhost';
config.database.port = 5432;

% Write YAML
writeyaml(config, 'config.yaml');

% Write TOML
writetoml(config, 'config.toml');
```

### Working with Arrays

```matlab
% YAML/TOML arrays convert automatically
config.ports = [8080, 8443, 9000];        % Numeric array
config.servers = ["alpha", "beta"];       % String array

% Control output style
writeyaml(config, 'config.yaml', 'ArrayStyle', 'flow');
% Output: ports: [8080, 8443, 9000]

writeyaml(config, 'config.yaml', 'ArrayStyle', 'block');
% Output:
% ports:
%   - 8080
%   - 8443
%   - 9000
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

### Common Options

**readyaml:**
- `'SequenceRule'` - `'auto'` (default) or `'cell'` - Control array conversion

**writeyaml:**
- `'ArrayStyle'` - `'block'` (default) or `'flow'` - Array formatting
- `'NumIndentationSpaces'` - Integer (default: 2) - Indentation
- `'SectionSpacing'` - `'loose'` (default) or `'compact'` - Spacing
- `'Precision'` - Integer (default: 6) - Numeric precision

**writetoml:**
- Similar options available

## Data Objects

### YAMLData and TOMLData

Both extend `ConfigurationData` with format-specific features:

```matlab
% Create and populate
config = YAMLData;
config.version = '1.0.0';
config.database.host = 'localhost';

% Access keys
allKeys = keys(config);         % Get all keys
exists = isfield(config, 'db'); % Check existence

% Display full content
show(config);                   % Shows formatted YAML/TOML

% Convert to struct
s = struct(config);             % Standard MATLAB struct
```

### Handling Special Characters

Keys with hyphens, spaces, or other special characters use parentheses notation:

```matlab
config.("build-system").requires = ["setuptools"];
config.("my key").value = 123;

% Field names are automatically aliased
config.build_system  % Also works! (uses makeValidName)
```

### Converting Data

Convert between structs, dictionaries, and ConfigurationData:

```matlab
% Create from struct
s = struct('name', 'MyApp', 'database', struct('host', 'localhost', 'port', 5432));
config = YAMLData(s);           % Also works with TOMLData, INIData

% Convert to dictionary
d = dictionary(config);
d{"name"}                       % "MyApp"

% Write struct or dictionary directly
writeyaml(s, 'config.yaml');    % Structs work directly
writeyaml(d, 'config.yaml');    % Dictionaries work too
```

## Examples

See `toolbox/GettingStarted.m` for an introductory walkthrough, or explore the `examples/` folder:

**YAML Examples:**
- `github-actions-ci.yaml` - GitHub Actions workflow
- `docker-compose.yaml` - Docker Compose configuration
- `kubernetes-deployment.yaml` - Kubernetes deployment

**TOML Examples:**
- `pyproject.toml` - Python project configuration
- `matlab_project.toml` - MATLAB project settings

**Demo Scripts:**
- `demo_yaml_examples.m` - Interactive YAML demos
- `yamlGettingStarted.m` - YAML introduction

## Working with GitHub Actions

The toolbox fully supports GitHub Actions workflows:

```matlab
% Read workflow
workflow = readyaml('github-actions-ci.yaml');

% Access steps (returns object array)
steps = workflow.jobs.test.steps;

% Modify a step
steps(1).uses = 'actions/checkout@v5';

% Write back
writeyaml(workflow, 'updated-workflow.yaml');
```

## Supported Data Types

### Reading
- **Strings** → char or string
- **Numbers** → double
- **Booleans** → logical
- **Arrays** → numeric, string, or cell arrays (auto-detected)
- **Objects** → YAMLData/TOMLData with nested fields
- **Dates** → datetime objects (TOML)

### Writing
- All MATLAB types: numeric, string, char, logical, datetime
- Nested structures
- Arrays (with formatting control)
- Object arrays

## Limitations

This toolbox implements a simplified YAML parser optimized for configuration files. It is **not** a full YAML 1.2 compliant parser.

- **YAML**: Subset parser. See [LIMITATIONS.md](LIMITATIONS.md) for details on supported/unsupported features (anchors, tags, etc.).
- **TOML**: Array of tables bug in reading (writing works).
- **Chained indexing**: `obj.field(i).subfield` requires extracting array first (e.g. `tmp = obj.field; val = tmp(i).subfield`).
- **Custom tags**: Not supported.

For production use cases requiring full spec compliance (e.g. complex Kubernetes manifests with anchors), consider Java-based libraries.

## Requirements

- MATLAB R2019b or later (for `arguments` blocks)
- No additional toolboxes required

## Project Structure

```
ConfigurationFileIO/
├── toolbox/              ← Add this to path
│   ├── readyaml.m
│   ├── writeyaml.m
│   ├── readtoml.m
│   ├── writetoml.m
│   ├── YAMLData.m
│   ├── TOMLData.m
│   └── ConfigurationData.m
├── examples/             ← Example files and demos
├── tests/                ← Test files
└── Claude/               ← Development documentation
```

## Development Documentation

Detailed development notes, design decisions, and implementation details are in the `Claude/` folder:
- `Claude/YAML/` - YAML implementation notes
- `Claude/TOML/` - TOML implementation notes  
- `Claude/ConfigurationData/` - Base class design

## License

Copyright 2025 The MathWorks, Inc. See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues and pull requests.

---

**Version:** 1.0.0  
**Last Updated:** December 31, 2025

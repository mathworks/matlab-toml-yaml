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
- **Smart Arrays** - Automatic conversion to optimal MATLAB types
- **Customizable Output** - Control formatting, indentation, array styles

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

### Working with Arrays

```matlab
% Read a file with arrays
arrays = readyaml("arrays_config.yaml");
arrays.web.ports          % [8080; 8443; 9000] numeric array
arrays.web.hosts          % ["alpha"; "beta"; "gamma"] string array

% Control output style
writeyaml(arrays, "my_arrays.yaml", ArrayStyle="flow");
% Output: ports: [8080, 8443, 9000]

writeyaml(arrays, "my_arrays.yaml", ArrayStyle="block");
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
- `SequenceRule` - `"auto"` (default) or `"cell"` - Control array conversion

**writeyaml:**
- `ArrayStyle` - `"block"` (default) or `"flow"` - Array formatting
- `NumIndentationSpaces` - Integer (default: 2) - Indentation
- `SectionSpacing` - `"loose"` (default) or `"compact"` - Spacing
- `Precision` - Integer (default: 6) - Numeric precision

**writetoml:**
- Similar options available

## Data Objects

### YAMLData and TOMLData

Both extend `ConfigurationData` with format-specific features:

```matlab
% Create and populate
config = matlab.io.config.YAMLData;
config.version = "1.0.0";
config.database.host = "localhost";

% Access keys
allKeys = keys(config);              % Get all keys
exists = isfield(config, "database"); % Check existence

% Display full content
show(config);                   % Shows formatted YAML/TOML

% Convert to struct
s = struct(config);             % Standard MATLAB struct
```

### Handling Special Characters

Keys with hyphens, spaces, or other special characters use parentheses notation:

```matlab
project = readtoml("simple_project.toml");
project.("build-system").requires    % ["setuptools>=61.0", "wheel"]
project.("my key").value = 123;      % Create keys with spaces

% Field names are automatically aliased
project.build_system  % Also works! (uses makeValidName)
```

### Converting Data

Convert between structs, dictionaries, and ConfigurationData:

```matlab
% Create from struct
s = struct("name", "MyApp", "database", struct("host", "localhost", "port", 5432));
config = yamldata(s);           % Also works with tomldata

% Convert to dictionary
d = dictionary(config);
d{"name"}                       % "MyApp"

% Write struct or dictionary directly
writeyaml(s, "my_config.yaml");    % Structs work directly
writeyaml(d, "my_config.yaml");    % Dictionaries work too
```

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
- `ConfigurationDataDemo.m` - Tour of the data object API
- `conversionExample.m` - Converting between structs, dictionaries, and data objects

## Working with GitHub Actions

The toolbox fully supports GitHub Actions workflows:

```matlab
% Read workflow
workflow = readyaml("ci.yaml");

% Access steps (returns object array)
steps = workflow.jobs.test.steps;

% Modify a step and assign back (value semantics)
steps(1).uses = "actions/checkout@v5";
workflow.jobs.test.steps = steps;

% Write back
writeyaml(workflow, "ci_updated.yaml");
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

- **YAML**: Subset parser. See [readyaml documentation](toolbox/doc/readyaml.md#limitations) for details on supported/unsupported features (anchors, tags, etc.).
- **TOML**: Array of tables bug in reading (writing works).
- **Chained indexing**: `obj.field(i).subfield` requires extracting array first (e.g. `tmp = obj.field; val = tmp(i).subfield`).
- **Custom tags**: Not supported.

For production use cases requiring full spec compliance (e.g. complex Kubernetes manifests with anchors), consider Java-based libraries.

## Requirements

- MATLAB R2022b or later (for `dictionary` with value semantics)
- No additional toolboxes required

## Project Structure

```
matlab-toml-yaml/
├── buildfile.m           ← Build tasks (test, package)
├── images/               ← Toolbox icon, README assets
├── toolbox/              ← Add this to path
│   ├── readyaml.m
│   ├── writeyaml.m
│   ├── readtoml.m
│   ├── writetoml.m
│   ├── doc/              ← GettingStarted + function reference
│   ├── examples/         ← Example scripts and sample files
│   └── +matlab/+io/+config/
│       ├── ConfigurationData.m
│       ├── YAMLData.m
│       └── TOMLData.m
└── tests/                ← Test files
```

## License

Copyright 2026 The MathWorks, Inc. See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting issues and pull requests.

---

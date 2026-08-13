# Experimental: JSON and INI support

This folder holds **unsupported, experimental** JSON and INI support that is
**not** part of the shipped *TOML and YAML Toolbox for MATLAB*. It is not
included in the MLTBX release artifact or the public GitHub repository — it
lives here in the staging repository pending a future decision about whether to
develop these formats further, ship them separately, or retire them.

Do not treat anything in this folder as a supported feature.

## Status

- **Not shipped.** The release manifest (`release/manifest.txt`) includes only
  `toolbox/` and `tests/`. This folder is deliberately excluded.
- **Not on the default path.** Adding `toolbox/` to your MATLAB path (or opening
  the project) does *not* make any of this code available.
- **No support guarantees.** APIs, behavior, and file layout here may change or
  disappear without notice.

## Contents

Function wrappers:

- `readjson.m` / `writejson.m` — read and write JSON files
- `readini.m` / `writeini.m` — read and write INI files
- `jsondata.m` / `inidata.m` — constructor wrappers for the data objects

Classes (in the `matlab.io.config` namespace):

- `+matlab/+io/+config/JSONData.m`
- `+matlab/+io/+config/INIData.m`

Both subclass `matlab.io.config.ConfigurationData`, whose base class ships in
`toolbox/`. MATLAB merges a namespace across every folder on the path, so these
subclasses resolve only when **both** `toolbox/` and this `experimental/` folder
are on the path (see [Using this code](#using-this-code)).

Supporting material:

- `doc/` — reference pages for `readini`, `writeini`, and `INIData`
- `examples/` — example scripts for the JSON and INI wrappers
- `tests/` — companion tests (`jsontest.m`, `initest.m`, and the
  `*ExperimentalTest.m` files) plus JSON/INI sample files in
  `tests/SampleFiles/`

## Using this code

Because these subclasses depend on the shipped base class, put both folders on
the path — the shipped `toolbox/` first, then this folder:

```matlab
addpath('toolbox')
addpath('experimental')
```

Then the wrappers work as before:

```matlab
config = readjson('tests/SampleFiles/01_package.json');
writeini(config, 'out.ini');
```

## Running the experimental tests

The companion tests add both folders to the path via fixtures, so they can be
run directly:

```matlab
run_matlab_test_file('experimental/tests/jsontest.m')
run_matlab_test_file('experimental/tests/initest.m')
run_matlab_test_file('experimental/tests/describeExperimentalTest.m')
run_matlab_test_file('experimental/tests/arrayOrientationExperimentalTest.m')
run_matlab_test_file('experimental/tests/ExperimentalPerformanceTest.m')
```

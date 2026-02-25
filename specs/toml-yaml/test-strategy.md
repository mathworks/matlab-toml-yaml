# Test Strategy & Testability

## Test Strategy

### Unit Tests

| Test File | Coverage |
|-----------|----------|
| `tests/yamltest.m` | YAML read, write, round-trip, edge cases |
| `tests/tomltest.m` | TOML read, write, round-trip, arrays of tables |
| `tests/subsasgnTest.m` | Array element assignment patterns |

### Test Categories

1. **Basic Reading Tests**
   - Simple key-value pairs
   - Nested structures
   - Arrays (block and flow style)
   - Special characters in keys

2. **Basic Writing Tests**
   - Simple data output
   - Nested structures
   - Array formatting options
   - Section spacing

3. **Round-Trip Tests**
   - Read → Write → Read produces identical data
   - `SequenceRule="auto"` and `SequenceRule="cell"` round-trip behavior
   - Real-world files: GitHub Actions, Docker Compose, Kubernetes, pyproject.toml
   - Complex nesting and arrays

4. **Edge Cases**
   - Empty files
   - Comments (should be ignored)
   - Quoted strings
   - Boolean variations (`true`, `yes`, `on`)
   - Null values

5. **Value Semantics Tests**
   - Assignment creates independent copy
   - Modification doesn't affect original
   - Nested modification behavior

6. **Array Indexing Tests**
   - `data.users(2).name = value` assignment
   - `data.users(2).permissions.admin = true` chained assignment
   - Array element read access

### Sample Test Files

Located in `tests/SampleFiles/`:
- `server_config.yaml`
- `arrays_config.yaml`
- `simple-github-actions.yaml`
- `simple-docker-compose.yaml`
- `kubernetes-service.yaml`
- `github-actions-ci.yaml`
- `kubernetes-deployment.yaml`

### Test Execution

```matlab
% Run all YAML tests
results = runtests("tests/yamltest.m");

% Run specific test
results = runtests("yamltest/testRoundtripSimpleDockerCompose");

% Run all tests in project
results = runtests(pwd, IncludeSubfolders=true);
```

## Testability Features

- **Pure MATLAB:** No external dependencies simplify test environment
- **Sample Files:** Curated collection of real-world config files
- **Temporary Files:** Tests use `TemporaryFolderFixture` for isolation
- **Round-Trip Pattern:** Standard verification approach

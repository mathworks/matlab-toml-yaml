# #80: Implement key-search + pattern-based selection over hierarchical data

**State:** open
**Created:** 2026-02-27
**Labels:** enhancement, feature

## Description

## Background

Users working with large hierarchical configuration data need to:
- Find keys anywhere in the hierarchy without knowing the exact path
- Use patterns (wildcards, regex) to match multiple keys
- Select subsets of data based on search results
- Handle heterogeneous arrays where keys may be missing in some elements

## Requirements

### 1. Recursive Key Search
```matlab
% Find all keys named "port" anywhere in hierarchy
results = search(config, 'port');

% Find keys matching a pattern
results = search(config, 'database.*');
results = search(config, 'server_[0-9]+');
```

### 2. Search Results as Selection
```matlab
% Search should return something that can be used for selection
results = search(config, '*.timeout');
subset = select(config, results);
```

### 3. Multiple Match Handling
```matlab
% When pattern matches multiple keys
results = search(config, 'server*');
% => Returns: 'server_name', 'server_port', 'server_host'

% Select all matching keys
data = select(config, results);
```

### 4. Heterogeneous Array Support
```matlab
% Config array where not all elements have the same keys
configs = [config1, config2, config3];
% config1.database exists, config2 doesn't, config3 does

results = search(configs, 'database');
% Should handle missing keys gracefully
```

## Proposed API

### Search Function
```matlab
results = search(obj, pattern, options)
% Inputs:
%   obj     - ConfigurationData object or array
%   pattern - String pattern (literal, wildcard, or regex)
%   options - Name-value pairs:
%             'Type': 'literal' | 'wildcard' | 'regex'
%             'Recursive': true | false
%             'CaseSensitive': true | false
% Outputs:
%   results - SearchResults object containing:
%             - Matched keys
%             - Full paths to each match
%             - Reference to parent objects
```

### Select Function
```matlab
subset = select(obj, results)
% or
subset = select(obj, keyPattern)
% Inputs:
%   obj     - ConfigurationData object or array
%   results - SearchResults object or key pattern string
% Outputs:
%   subset  - ConfigurationData containing only matched keys
```

## Design Questions

1. **Search result representation**:
   - Custom `SearchResults` class?
   - Simple struct with paths and keys?
   - String array of full paths?

2. **Path notation**: How to represent nested paths?
   - Dot notation: `'server.database.port'`
   - Cell array: `{'server', 'database', 'port'}`
   - Struct with fields?

3. **Selection semantics**:
   - Preserve hierarchy (include parent keys)?
   - Flatten to matched keys only?
   - User-configurable?

4. **Pattern syntax**:
   - MATLAB's `strcmp` wildcards (`*`, `?`)?
   - Full regex support?
   - Both with explicit opt-in?

5. **Missing key handling**:
   - Return `missing` for array elements lacking the key?
   - Skip those elements?
   - Return partial array?

6. **Performance**: For large configs with deep nesting
   - Index keys at creation time?
   - Lazy search on demand?
   - Cache search results?

## Example Use Cases

### Use Case 1: Extract all timeout values
```matlab
config = readyaml('complex_config.yaml');
results = search(config, '*timeout*', 'Type', 'wildcard');
timeouts = select(config, results);
show(timeouts);
```

### Use Case 2: Find database credentials anywhere
```matlab
results = search(config, 'database\..*\.(user|password)', 'Type', 'regex');
creds = select(config, results);
```

### Use Case 3: Work with heterogeneous service array
```matlab
services = readyaml('services.yaml').services;  % Array of configs
ports = search(services, 'port');
% Handle services that don't have a port defined
portNumbers = arrayfun(@(s) getOrDefault(s, 'port', 8080), services);
```

## Algorithm Sketch

### Recursive Search
```matlab
function results = search(obj, pattern, options)
    results = SearchResults();
    searchRecursive(obj, pattern, '', results);
end

function searchRecursive(obj, pattern, currentPath, results)
    for key = keys(obj)
        fullPath = appendPath(currentPath, key);
        if matches(key, pattern)
            results.add(key, fullPath, obj);
        end

        if isa(obj.(key), 'ConfigurationData')
            searchRecursive(obj.(key), pattern, fullPath, results);
        end
    end
end
```

### Selection
```matlab
function subset = select(obj, results)
    subset = ConfigurationData();
    for each result in results
        % Build nested structure preserving hierarchy
        setNestedValue(subset, result.path, result.value);
    end
end
```

## Related Issues

- #72: Wildcard key search for ConfigurationData
- #73: `describe` could give more useful information when keys aren't the same across all elements
- #74: Design question: should `arrfield` return `missing` for elements that lack the key?
- #76: Can/should we get tab completion to work when there are heterogeneous keys?

## Success Criteria

- Can find keys anywhere in deeply nested hierarchies
- Pattern matching works reliably (literal, wildcard, regex)
- Results can be passed to `select()` to extract subsets
- Handles heterogeneous arrays gracefully
- Performance acceptable for configs with 1000+ keys
- Clean, MATLAB-idiomatic API

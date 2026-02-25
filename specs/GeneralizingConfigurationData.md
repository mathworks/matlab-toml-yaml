# Generalizing ConfigurationData: Design Assessment

**Date:** 2026-02-25
**Status:** Pre-spec assessment — exploring generalization beyond configuration files
**Context:** Evaluating whether ConfigurationData is "struct 2.0" and identifying appropriate terminology

---

## Executive Summary

ConfigurationData combines features from multiple paradigms (Pandas-like vectorized extraction, JavaScript-style hierarchical access, R-style flexible lists) into MATLAB's type system. It's not a strict replacement for struct, but rather a **specialized tool optimized for different use cases** — specifically heterogeneous hierarchical data with vectorized operations.

**Key Innovation:** Direct dot notation on arrays with type-strict extraction and no requirement for homogeneous schemas.

---

## What Are We Building?

### Core Features

1. **Heterogeneous Arrays** — Elements don't need the same keys
2. **Vectorized Field Extraction** — `products.name` returns typed arrays
3. **Hierarchical Dot Notation** — `config.database.host` with arbitrary nesting
4. **Value Semantics** — Assignment creates copies (not references)
5. **Type-Strict Array Operations** — Errors on type mismatches, no surprise cells
6. **Key Aliasing** — `build-system` auto-aliased to `build_system`
7. **Method Override** — Data keys take priority over methods

### Cross-Language Analogues

| Feature | ConfigurationData | Similar To |
|---------|------------------|------------|
| Heterogeneous arrays | ✓ | Python `list[dict]`, JS arrays |
| Array field extraction | `arr.name` → string array | Pandas `df['col']`, R `sapply` |
| Dot notation hierarchy | `obj.a.b.c` | JS objects, Python `SimpleNamespace` |
| Value semantics | Copy on assign | MATLAB struct, R (copy-on-modify) |
| Type-strict extraction | Errors if types differ | R `sapply`, Rust |
| No reserved methods | `obj.keys` accesses data | Rare (most languages prioritize methods) |

**The Combination is Novel:** No other language offers Pandas-like vectorization on heterogeneous hierarchical data with struct-like ergonomics and MATLAB's type discipline.

---

## Is This "Struct 2.0"?

### No — It's "Struct's Specialized Cousin"

ConfigurationData and struct serve **different use cases**, both legitimate:

| Dimension | Struct | ConfigurationData |
|-----------|--------|------------------|
| **Schema** | Homogeneous (enforced) | Heterogeneous (flexible) |
| **Array Access** | Comma-separated lists | Typed array concatenation |
| **Use Case** | Tabular/database-like | Hierarchical/config-like |
| **Complexity** | Minimal (primitive type) | Sophisticated (custom indexing) |
| **Reserved Names** | None | `xInternal__` |
| **Method Calling** | N/A (no methods) | Function syntax required |
| **Performance** | Fast (primitive) | Overhead (custom indexing) |

---

## When Struct is Legitimately Better

Even ignoring legacy/performance/familiarity, struct has advantages:

### 1. **Comma-Separated Lists** (Biggest Advantage)

```matlab
% Struct: varargs expansion
s(1).name = "Alice"; s(2).name = "Bob";
fprintf('%s\n', s.name)  % Expands to 2 args

plot(data.x, data.y, args.LineStyle, args.Color)  % Struct wins
```

ConfigurationData always returns a single concatenated array — no varargs.

### 2. **Schema Enforcement**

```matlab
% Struct enforces homogeneity
patients(1).name = "Alice"; patients(1).age = 30;
patients(2).name = "Bob";  % patients(2).age is REQUIRED

% ConfigurationData allows inconsistency (can be a footgun)
data(1).required_field = "value";
data(2) = configdata();  % No required_field - silent until accessed
```

**Use case:** Modeling databases, records, anything schema-like.

### 3. **Simplicity**

- Struct has zero custom behavior — what you see is what you get
- ConfigurationData requires learning: method syntax, priority rules, reserved names
- **Use case:** Teaching, prototyping, simple scripts

### 4. **Cell Array Output Control**

```matlab
% Struct: explicit choice
[s.mixed]  % Try concatenate, error if heterogeneous
{s.mixed}  % Always cell array

% ConfigurationData: decides for you (errors on heterogeneity)
arr.mixed  % Must use arrayfun workaround
```

---

## When ConfigurationData is Better

### 1. **Heterogeneous Arrays**

```matlab
% ConfigurationData: naturally heterogeneous
cfg(1).email = "a@example.com";
cfg(2).admin = true;  % No padding needed

% Struct: requires manual padding
s(2).email = "";  % Must pad missing fields
```

### 2. **Special Characters in Keys**

```matlab
% ConfigurationData: automatic aliasing
cfg.build_system  % Works!
cfg.("build-system")  % Also works

% Struct: only dynamic access
s.("build-system")  % Verbose
```

### 3. **Data Keys That Are Reserved Words**

```matlab
% ConfigurationData: methods use function syntax
cfg.keys = "value";    % Works (data priority)
keys(cfg)              % Call method

% Struct: cannot have "keys" field without collision
```

### 4. **Type-Safe Array Extraction**

```matlab
% ConfigurationData: immediate error if types differ
names = users.name  % All must be strings or error

% Struct: silent heterogeneity or confusing concatenation
[s.field]  % Might concatenate unexpectedly
```

### 5. **Nested Type Preservation**

```matlab
% ConfigurationData: preserves subclass type
yaml.database  % Still a YAMLData object

% Struct: flattens to generic struct
s.database     % Just a struct
```

---

## Naming Considerations

### Options Evaluated

#### Option 1: Emphasize Structure
- **`HierarchicalData`** — Generic, clear about structure
- **`NestedData`** — Simple, emphasizes nesting
- **`FlexibleStruct`** — Emphasizes relationship to struct
- **`DynamicStruct`** — But "dynamic" often means runtime dispatch

#### Option 2: Emphasize Behavior
- **`DataRecord`** — Like R's tibbles (records with flexible schema)
- **`DataObject`** — Generic but clear
- **`DotData`** — Playful, emphasizes dot notation

#### Option 3: Emphasize Implementation
- **`mapping`** — Industry standard (Python, Go, YAML/JSON/TOML specs)
- **`datamap`** — Hybrid: MATLAB-ish + industry standard
- **`record`** — Database terminology, implies flexible schema

#### Option 4: Keep Current
- **`ConfigurationData`** — Broader than initial use case (like Pandas DataFrame)

### Recommendation

**For generalization beyond config files:**

**Primary choice: `NestedData` or `HierarchicalData`**
- Descriptive of structure (not tied to configs)
- MATLAB users understand "nested" and "hierarchical"
- Precedent: Pandas DataFrame is used far beyond data frames

**Alternative: `mapping`**
- Aligns with YAML/TOML/JSON specs (all use "mapping" for key-value hierarchies)
- Industry-standard terminology
- Target users (software developers) expect this term

**Hybrid approach:**
- Base class: `NestedData` or `HierarchicalData`
- Config subclasses: `ConfigurationData`, `YAMLData`, `TOMLData`, etc.
- Wrapper function: `nesteddata()` or `mapping()`

---

## Strategic Considerations

Three fundamental questions shape whether this becomes a core MATLAB type or remains specialized:

### 1. Should We Enhance Struct Instead?

Rather than creating a new type, could we add these capabilities to struct itself?

**Candidate enhancements:**

#### A. Invalid MATLAB Identifiers (Strongest Case)
- **Precedent:** `table` already supports this via `Properties.VariableNames`
- **Mechanism:** Could add `Properties.FieldNames` to struct arrays
- **Example:**
  ```matlab
  s.("build-system") = "cmake"  % Already works
  s.build_system                % Could auto-alias like ConfigurationData
  ```
- **Pros:** Users already know struct; no new type to learn
- **Cons:** Adds complexity to a primitive type; potential performance impact

#### B. Array Extraction Function
- **Current gap:** No built-in way to do `[s.name]` robustly
- **Possible solution:** New function `extractfield(s, 'name')` or `pluck(s, 'name')`
- **Example:**
  ```matlab
  names = extractfield(patients, 'name')  % Returns typed array if homogeneous
  ```
- **Pros:** Works with existing struct; no syntax changes needed
- **Cons:** Less ergonomic than `arr.name` dot notation

#### C. Typed Fields
- **Request:** Explicit field typing like object properties
- **Example:**
  ```matlab
  % Hypothetical typed struct
  patient = struct();
  patient.name (1,1) string = "Alice";  % Enforced type/size
  patient.age (1,1) double {mustBePositive} = 30;
  ```
- **Pros:** Better validation; IDE support; clearer contracts
- **Cons:** Changes struct from dynamic to semi-static; major design shift

**Assessment:**
- Invalid identifiers → **Could reasonably enhance struct** (table precedent)
- Array extraction → **Could add utility function** (no struct changes needed)
- Typed fields → **Major design shift**; better suited for new type or objects

**Deeper analysis:**

**Why invalid identifiers in struct is technically feasible:**
- Table already has `Properties.VariableNames` that can differ from valid identifiers
- Access: `T.("Variable-1")` works today for tables
- Tab completion: Could work like table (show aliased names)
- Backward compatible: Existing code unaffected
- Performance: Alias lookup is O(1) with dictionary
- **Blocker:** Struct is primitive type; adding Properties might require fundamental changes

**Why array extraction is harder than it looks:**
- ConfigurationData's `arr.field` behavior requires:
  - Type checking across all elements (homogeneity enforcement)
  - Shape preservation (`arr` shape → `result` shape)
  - Clear error messages (which elements missing key, which have type mismatch)
  - Pre-filtering support: `arr.field(1:5)` syntax
- A function like `extractfield(s, 'name')` could provide this, but:
  - Less ergonomic than dot notation
  - Doesn't support chaining: `s.a.b.c` vs `extractfield(extractfield(s, 'a'), 'b'), 'c')`
  - Can't preserve shape as naturally
- **Could work as utility**, but loses the ergonomic advantage

**Why typed fields would fundamentally change struct:**
- Struct today: *container of values* (primitive)
- Typed struct: *schema with validation* (object-like)
- This crosses the line from data structure to class
- At that point, might as well use a proper class with properties
- Or: Create new type (this one) that *is* a class with typed properties option

**Conclusion:**
- **Best hybrid approach:** Add `extractfield()` utility function that works with existing struct
- **Keep ConfigurationData** for users who want:
  - Ergonomic dot notation
  - Hierarchical chaining
  - Type-safe operations built in
  - File I/O integration
- **Don't add typed fields** to struct (changes its nature too much)

### 2. Positioning Relative to Struct and Table

If this becomes a fundamental type, how do users learn when to use it?

**Current fundamental types taught in introductory courses:**
- **Struct:** Group related data with named fields
- **Table:** Columns of data with row/column names (database-like)
- **Cell arrays:** Heterogeneous collections
- **Containers.Map:** Key-value lookup with hash performance

**Where does this fit?**

| Use Case | Current Solution | ConfigurationData Advantage |
|----------|-----------------|----------------------------|
| Grouped data (homogeneous) | struct | None — struct is simpler |
| Tabular data | table | None — table is specialized |
| Heterogeneous arrays | cell arrays | Dot notation + type-safe extraction |
| Key-value lookup | containers.Map | Hierarchical nesting + dot notation |
| Config files | struct via `readstruct` | Format awareness + vectorization |
| Nested JSON/YAML | struct via `jsondecode` | Heterogeneous arrays + aliasing |

**Teaching story challenge:**
- Struct is taught because grouping data is universal
- Table is taught because tabular data is universal
- This type addresses: "heterogeneous hierarchical data with vectorized extraction"
- **That's less universal** → suggests specialized tool, not fundamental type

**Possible positioning:**
1. **Specialized (like containers.Map)** — Taught when needed for specific use cases
2. **Fundamental but advanced** — Introduced after struct/table once users hit their limitations
3. **Enhance struct instead** — Don't create new type; make struct more capable

### 3. User Reasoning Model

If this exists alongside struct, when do users choose which?

**Decision tree users need:**

```
Need to group related data?
├─ Fixed schema, homogeneous? → struct
├─ Tabular with columns? → table
├─ Heterogeneous hierarchy with vectorized ops? → NestedData/ConfigurationData
└─ Simple collection? → cell array
```

**Key distinction must be clear:**
- Struct = "I know my schema; all elements have same fields"
- This = "My schema varies; I want vectorized extraction when possible"

**Example scenarios:**

| Scenario | Struct ✓ | NestedData ✓ |
|----------|---------|--------------|
| Patient records (all same fields) | ✓ | ❌ |
| Config files (optional sections) | ❌ | ✓ |
| Parsing JSON API (varying responses) | ❌ | ✓ |
| Function return values (fixed fields) | ✓ | ❌ |
| Experimental data (consistent schema) | ✓ | ❌ |
| Kubernetes manifests (varying keys) | ❌ | ✓ |

**Concern:** If the distinction isn't obvious, users will be confused about which to use.

### 4. Typed Fields: New Type or Struct Enhancement?

Explicit field typing is a common enhancement request. Where should it live?

**Option A: Add to Struct**
```matlab
% Hypothetical: Typed struct
patient = typedstruct();
patient.name (1,1) string = "Alice";
patient.age (1,1) double {mustBePositive} = 30;
```

**Pros:**
- Users already know struct
- Natural evolution of existing type
- Could be opt-in (regular struct vs typed struct)

**Cons:**
- Struct is primitive → adding type system is major change
- Performance implications (validation on every assignment)
- Breaks "struct is simple" principle
- At this complexity level, why not use objects?

**Option B: Add to ConfigurationData/New Type**
```matlab
% Example: Typed NestedData
schema = nesteddata();
schema.name = string.empty;       % Type inference from assignment
schema.age = double.empty;
data = nesteddata(schema);        % Creates with schema
data.name = "Alice";              % Validated
data.age = "thirty";              % ERROR: Expected double
```

**Pros:**
- This is already a class → validation is expected
- Doesn't complicate struct
- Can be optional feature (schemaless by default)
- Aligns with "power user tool" positioning

**Cons:**
- Yet another way to do structured data
- Schema enforcement → less flexible (maybe that's the point?)

**Option C: Don't Add Typed Fields Anywhere**

**Argument:**
- MATLAB already has typed properties in objects
- Users wanting typed structs should use objects
- Adding types to containers blurs the line between data and objects
- Keep containers flexible; use classes when you need types

**Assessment:**
- If typed fields are needed, **Option B (new type) is better than Option A (struct)**
- But **Option C (use objects)** may be the right answer
- Question: Is there a gap between "simple struct" and "full object with methods"?
  - Typed data class without behavior?
  - Maybe: `dataclass` (like Python) or `record` (like Java)?
  - This could be separate from ConfigurationData/NestedData

---

## Synthesis: Three Possible Paths Forward

Based on the strategic considerations above, here are three coherent approaches:

### Path 1: Enhance Struct (Conservative)

**Don't create a new fundamental type. Enhance struct ecosystem instead.**

**Actions:**
1. Add utility function: `extractfield(s, 'fieldname')` for type-safe array extraction
2. Consider: Alias support for invalid identifiers (requires struct changes)
3. Keep ConfigurationData as **specialized tool for config file I/O only**
4. Promote `readstruct`/`writestruct` for general hierarchical data

**Pros:**
- Minimal new concepts for users to learn
- Leverages existing struct knowledge
- No confusion about when to use which type
- ConfigurationData stays focused on file I/O use case

**Cons:**
- `extractfield(s, 'field')` less ergonomic than `s.field`
- No chaining: `extractfield(extractfield(s, 'a'), 'b')` is clunky
- Doesn't address heterogeneous array use case well
- Missed opportunity for better hierarchical data tools

**Best for:** Organizations prioritizing simplicity and minimal API surface

---

### Path 2: Specialize ConfigurationData (Moderate)

**Keep ConfigurationData specialized for file I/O and related workflows.**

**Actions:**
1. Position ConfigurationData as "struct for config files"
2. Target users: DevOps, software developers, CI/CD workflows
3. Emphasize file format awareness (YAML/TOML/JSON/INI)
4. Don't try to generalize beyond hierarchical config-like data
5. Add `extractfield()` utility for struct users who don't need full ConfigurationData

**Pros:**
- Clear positioning: "Use struct unless you're working with config files"
- Avoids competition with fundamental types
- Target audience is well-defined
- File I/O remains killer feature

**Cons:**
- Doesn't help users with non-file hierarchical data (JSON APIs, etc.)
- Leaves gap: heterogeneous arrays with vectorized operations
- Users might misunderstand scope ("Can I use this for X?")

**Best for:** Focusing on config management as primary use case

---

### Path 3: Generalize as New Fundamental Type (Ambitious)

**Make this a fundamental MATLAB type for heterogeneous hierarchical data.**

**Actions:**
1. Rename to `NestedData` or `HierarchicalData` (generalize beyond configs)
2. Position as: "struct for heterogeneous, hierarchical data"
3. Develop clear teaching story: when to use vs struct/table
4. Keep file I/O subclasses (YAMLData, TOMLData) as specializations
5. Add to introductory materials (after struct, before/alongside table)
6. Consider optional typed fields feature

**Pros:**
- Fills genuine gap in MATLAB's type system
- Addresses heterogeneous array pain points
- Modern, ergonomic API for hierarchical data
- Aligns with JSON/YAML as data interchange formats

**Cons:**
- Requires clear "when to use" guidance for users
- Another container type to learn (cognitive load)
- Risk of confusion with struct
- Needs strong justification for fundamental status
- Performance may lag struct (not primitive)

**Best for:** Long-term investment in modernizing MATLAB's data structures

---

### Recommendation: Start with Path 2, Enable Path 3

**Phase 1 (Now):**
- Keep ConfigurationData specialized for config/file I/O
- Target: DevOps, software developers, config management
- Add `extractfield()` utility for struct users
- Validate use cases and adoption

**Phase 2 (Future):**
- If usage grows beyond config files → generalize (Path 3)
- If usage stays focused → enhance struct instead (Path 1)
- Let user demand guide the decision

**Why this works:**
- De-risks the decision (can always generalize later)
- Focuses on proven use case (config files)
- Doesn't preclude future generalization
- Gives time to validate positioning and teaching story

---

## Key Questions for Next Phase

Before finalizing terminology and scope:

### Core Use Cases

1. **What's the primary use case beyond config files?**
   - Nested JSON from web APIs?
   - Experimental data hierarchies with optional metadata?
   - General-purpose struct replacement?
   - Parsing structured documents (HTML/XML as hierarchies)?

2. **Who is the target user?**
   - Software developers (prefer "mapping", "key"; familiar with JSON/YAML)?
   - Data scientists (prefer "nested", "hierarchical"; exploratory analysis)?
   - General MATLAB users (prefer "struct-like"; traditional workflows)?
   - DevOps/SRE (config management; CI/CD pipelines)?

### Design Strategy

3. **Should we enhance struct instead of creating a new type?**
   - Add invalid identifier support to struct (like table did)?
   - Create utility functions (`extractfield`, `pluck`) for array operations?
   - Keep ConfigurationData as specialized tool for file I/O?

4. **Is vectorized extraction the killer feature?**
   - Should naming emphasize the Pandas-like array operations?
   - Or the hierarchical flexibility?
   - Or the heterogeneity support?

5. **Should this support typed fields?**
   - Like object properties: `patient.age (1,1) double {mustBePositive}`
   - Or stay dynamically typed like struct?
   - Would typed fields distinguish this from struct?

### Technical Architecture

6. **Class hierarchy strategy?**
   - Keep `ConfigurationData` as base, generalize later?
   - Create new base (`NestedData`), make `ConfigurationData` a subclass?
   - Separate classes for different use cases?

7. **Compatibility with existing code?**
   - Can we evolve `ConfigurationData` without breaking changes?
   - Should file I/O subclasses (`YAMLData`) stay separate?
   - How does this relate to `readstruct`/`writestruct`?

### Positioning & Adoption

8. **How do we position this relative to struct?**
   - As a fundamental type (teach in intro courses)?
   - As a specialized tool (teach when needed)?
   - As a power-user feature (advanced workflows)?

9. **What's the "when to use this vs struct" story?**
   - Can we articulate a clear decision rule?
   - Are there example workflows that clearly benefit?
   - Would users naturally discover when they need this?

10. **If this is fundamental, what's the learning path?**
    - Variables → Arrays → Struct → **This** → Table?
    - Or: Struct/Table (basics) → **This** (when you need flexibility)?
    - Do we risk confusing beginners with too many container types?

---

## Use Case Analysis: Where ConfigurationData Wins

To inform the path decision, here are specific scenarios where ConfigurationData provides clear value over struct:

### Scenario 1: Parsing YAML/TOML Config Files ✅ **Clear Win**

```matlab
% ConfigurationData
config = readtoml('pyproject.toml');
authors = config.project.authors.name;  % String array
dependencies = config.project.dependencies;

% Struct (via readstruct)
s = readstruct('pyproject.toml', 'FileType', 'toml');
authors = arrayfun(@(x) x.name, s.project.authors, 'UniformOutput', false);
authors = string(authors);  % Manual conversion
```

**Why ConfigurationData wins:** Format awareness, vectorized extraction, ergonomic syntax

---

### Scenario 2: Consuming JSON APIs 🤔 **Moderate Win**

```matlab
% JSON API returning array of users with optional fields
data = webread('https://api.example.com/users');

% ConfigurationData
users = jsondata(data);
emails = users(iskey(users, 'email')).email;  % Filter + extract

% Struct
hasEmail = arrayfun(@(x) isfield(x, 'email'), data);
emails = arrayfun(@(x) x.email, data(hasEmail), 'UniformOutput', false);
```

**Why ConfigurationData wins:** Handles heterogeneity, vectorized `iskey`, cleaner syntax
**Counterpoint:** `jsondecode` already exists; is this enough benefit?

---

### Scenario 3: dir() Output Processing 🤔 **Marginal Win**

```matlab
files = dir('*.m');

% ConfigurationData
files = configdata(files);
names = files.name;        % String array (no cell gymnastics)
big = files(files.bytes > 1e4);

% Struct
names = string({files.name});  % Manual cell → string conversion
big = files([files.bytes] > 1e4);
```

**Why ConfigurationData wins:** Slight syntax improvement
**Counterpoint:** struct syntax isn't *that* bad for this case

---

### Scenario 4: Patient Records (Homogeneous Schema) ❌ **Struct Wins**

```matlab
patients(1).name = "Alice"; patients(1).age = 30;
patients(2).name = "Bob";   patients(2).age = 45;

% Struct enforces schema
[patients.age]  % Works: [30, 45]

% ConfigurationData allows inconsistency
cfg(1).name = "Alice"; cfg(1).age = 30;
cfg(2).name = "Bob";   % age missing - silent until accessed
cfg.age  % ERROR: Key "age" missing in elements [2]
```

**Why struct wins:** Schema enforcement is desired here

---

### Scenario 5: Kubernetes Manifest Parsing ✅ **Clear Win**

```matlab
k8s = readyaml('deployment.yaml');

% ConfigurationData
containers = k8s.spec.template.spec.containers;
images = containers.image;  % String array
ports = containers.ports.containerPort;  % Numeric array (if homogeneous)

% Struct
containers = k8s.spec.template.spec.containers;
images = arrayfun(@(x) string(x.image), containers);
% ports would require nested arrayfun (ports is array within array)
```

**Why ConfigurationData wins:** Deep nesting + vectorization + heterogeneous arrays

---

### Verdict from Use Cases

**Clear wins for ConfigurationData:**
- Config file parsing (YAML/TOML/JSON/INI)
- Structured documents with deep nesting (Kubernetes, CI/CD configs)
- Heterogeneous arrays with optional fields

**Marginal/questionable wins:**
- dir() output processing (struct + string() is fine)
- Simple JSON APIs (struct + arrayfun works)

**Clear losses:**
- Homogeneous record-like data (struct's schema enforcement is better)

**Implication:** ConfigurationData's value is strongest for **config/document parsing** use cases. Generalizing to "all hierarchical data" may be overreach.

---

## Design Philosophy Comparison

### Struct Philosophy
- **Primitive container** — minimal behavior
- **Schema enforcement** — homogeneity required
- **Predictable** — no surprises, no magic
- **Fast** — optimized primitive type
- **Simple** — easy to teach and understand

### ConfigurationData Philosophy
- **Power user tool** — sophisticated behavior
- **Schema flexibility** — heterogeneity allowed
- **Ergonomic** — optimized for hierarchical access patterns
- **Type-safe** — strict type checking on operations
- **Specialized** — optimized for specific use cases

**Both are valid!** Not every tool needs to be a Swiss Army knife.

---

## If We Started MATLAB Today

Would both still exist? **Yes.**

Hypothetical clean-slate design:

- **`record`** (today's struct) — Simple, homogeneous containers with schema enforcement
- **`mapping`** (today's ConfigurationData) — Flexible, heterogeneous hierarchical data

### Why Both?

1. **Simplicity matters** — Not everything needs ConfigurationData's power
2. **Schema enforcement matters** — Homogeneity is often desirable (databases, records)
3. **Performance matters** — Primitives are faster
4. **Comma-separated lists matter** — Genuinely useful for varargs

---

## Summary

**ConfigurationData is not "struct done right."** It's a specialized tool for a different job:

- **Struct:** Simple containers for homogeneous, schema-enforced data
- **ConfigurationData:** Flexible hierarchies for heterogeneous, exploratory data with vectorized operations

The right tool depends on the use case. Both deserve to exist.

**Key strategic questions:**
1. Should we enhance struct instead of creating a new type? (Add `extractfield()` utility; consider invalid identifier support)
2. How do we position this relative to struct/table if it becomes fundamental?
3. Should typed fields be added to this (or struct), or should users just use objects?
4. Should this stay specialized for config files, or generalize to all hierarchical data?

**Recommended approach:** Start specialized (config files), let usage guide future generalization.

---

## Next Steps

### Immediate Decisions Needed

1. **Choose a path forward:**
   - Path 1: Enhance struct ecosystem (conservative)
   - Path 2: Keep ConfigurationData specialized (moderate, **recommended**)
   - Path 3: Generalize as fundamental type (ambitious)

2. **If Path 2 (recommended):**
   - Validate config management as primary use case
   - Identify target users (DevOps, software developers, CI/CD)
   - Keep ConfigurationData name (signals config focus)
   - Develop `extractfield()` utility for struct users
   - Document when to use ConfigurationData vs struct

3. **If Path 3 (generalize):**
   - Choose new name: `NestedData`, `HierarchicalData`, or `mapping`
   - Draft full spec for generalized use beyond config files
   - Develop clear teaching story and positioning
   - Define "when to use this vs struct/table" decision tree
   - Design class hierarchy (rename base class?)

### Research & Validation

4. **User research:**
   - Survey potential users: What hierarchical data workflows do they have?
   - Validate whether config files are the primary pain point
   - Identify if there's demand for general heterogeneous hierarchical type
   - Check if `extractfield()` utility would satisfy struct users

5. **Competitive analysis:**
   - How do Python, R, Julia handle this space?
   - What do users coming from other languages expect?
   - Are we solving problems they've already encountered elsewhere?

### Technical Exploration

6. **Prototype `extractfield()` utility:**
   - Design API: `extractfield(s, 'name', 'TypeCheck', 'strict')`
   - Implement homogeneity checking and shape preservation
   - Test with real struct arrays from common workflows
   - Evaluate if this satisfies the need without new type

7. **Evaluate typed fields:**
   - Is there user demand for typed struct/data fields?
   - Would this feature distinguish ConfigurationData/NestedData from struct?
   - Or should users wanting types just use objects?
   - Consider Python `dataclass` or Java `record` as models

### Documentation & Positioning

8. **Draft positioning document:**
   - Clear explanation of struct vs ConfigurationData use cases
   - Example workflows that clearly benefit from each
   - Decision tree or flowchart for choosing
   - Migration guide: when to switch from struct

9. **Update CLAUDE.md:**
   - Reflect chosen path (specialized vs generalized)
   - Document strategic decisions made
   - Capture "why we didn't generalize" (if Path 2) or "why we generalized" (if Path 3)

---

## References

- Current implementation: [`toolbox/+matlab/+io/+config/ConfigurationData.m`](../toolbox/+matlab/+io/+config/ConfigurationData.m)
- Design documentation: [`Claude/`](../Claude/) folder (14 design documents)
- Array behavior: [`Claude/DESIGN_array_dot_reference.md`](../Claude/DESIGN_array_dot_reference.md)
- Test examples: [`tests/SampleFiles/`](../tests/SampleFiles/) (27+ real-world config files)

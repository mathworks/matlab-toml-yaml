%[text] # ConfigurationData: Core Features Demo
%[text] This demo showcases the key features of ConfigurationData through exploration of a rich, multi-environment application configuration. The focus is on **what makes this type unique** compared to struct.
%[text] 
%[text] **Key Features Demonstrated:**
%[text] - Heterogeneous arrays (elements with different schemas)
%[text] - Vectorized field extraction with type safety
%[text] - Hierarchical dot notation
%[text] - Automatic key aliasing (hyphens → underscores)
%[text] - Method calling convention (function syntax)
%[text] - Filtering and querying heterogeneous data \
%[text]
%[text:tableOfContents]{"heading":"Table of Contents"}
%%
%[text] ## Show the file
% edit demo_application.yaml
%%
%[text] ## Load Configuration
%[text] We'll use this single object for the entire demo:
config = readyaml("demo_application.yaml") %[output:28721226]
%%
%[text] ## Initial Exploration
%[text] ### See the entire data structure
%[text] Just click on "show all values" link, or call show. show pretty prints to look like a YAML file.
show(config) %[output:935e7fdc]
%[text] ### High-Level Structure
%[text] The `describe()` function provides a schema overview - especially useful for complex nested data:
describe(config) %[output:37672812]
%%
%[text] ### What Keys Are Available?
%[text] **Note:** Methods must use function syntax (not dot notation) because data keys take priority:
keys(config) %[output:3899c216]
%%
%[text] ## Hierarchical Access with Dot Notation
%[text] ### Simple Values
%[text] Basic dot access works exactly like struct:
config.version %[output:3b3ae415]
%%
%[text] ### Key Aliasing: Automatic Handling of Special Characters
%[text] YAML/TOML keys often contain hyphens (invalid in MATLAB). Access them two ways:
config.("app-name")     % Original key with dynamic indexing %[output:55baa46a]
%%
%[text] Or use the automatically aliased version:
config.app_name         % Hyphen → underscore alias %[output:0ff5df81]
%%
%[text] ### Nested Access
%[text] Chain dot notation for deep hierarchies:
config.("database-connections")(1).pool.max_size %[output:6934927b]
%%
%[text] ## Heterogeneous Arrays
%[text] ### Environments with Different Schemas
%[text] Each environment has only the fields it needs. **This is where ConfigurationData differs fundamentally from struct**:
envs = config.environments %[output:0a2103dc]
%%
%[text] List of all keys (union):
keys(envs) %[output:76f79ab7]
%%
%[text] Check which environments have specific keys using vectorized `iskey()`:
hasAutoScaling = iskey(envs, "auto-scaling") %[output:037da8aa]
%%
%[text] ### Vectorized Field Extraction
%[text] Extract a field from all elements as a typed MATLAB array:
envNames = envs.name %[output:41cc6b7d]
%%
%[text] ### Type-Safe Extraction
%[text] If you try to extract a field that doesn't exist in all elements, you get a clear error:
try %[output:group:27c4b1b0]
    envs.("auto-scaling")  % Only exists in production
catch ME
    disp(ME.message) %[output:5cb1acb2]
end %[output:group:27c4b1b0]
%%
%[text] ### Filtering Heterogeneous Arrays
%[text] Use `iskey()` to filter before extraction:
prodEnv = envs(iskey(envs, "auto-scaling")) %[output:2e8447ad]
%%
%[text] Now extraction works:
prodEnv.("auto-scaling") %[output:67735d11]
%%
%[text] ## Vectorized Operations
%[text] Extract all service ports as a numeric array:
config.services.port %[output:7d925521]
%%
%[text] Standard MATLAB operations work directly:
mean(config.services.port) %[output:1c46a5b2]
%%
%[text] ### Combining Filters and Extractions
%[text] Get instance types for all non-production environments 
nonProd = envs(config.environments.name ~= "production").("instance-type") %[output:64eac47a]
%%
%[text] ### Vectorized Assignment
%[text] Upgrade all non-production instance types at once:
envs(config.environments.name ~= "production").("instance-type") = "t3.large";
envs(config.environments.name ~= "production").("instance-type") %[output:941eae2d]
%%
%[text] Update multiple fields across filtered elements:
devAndStaging = envs(envs.name ~= "production");
devAndStaging.("backup-enabled") = true;
devAndStaging.("backup-schedule") = "0 3 * * *";
show(devAndStaging(1)) %[output:11b14c37]
%%
%[text] ### What Doesn't Work: Direct Nested Assignment
%[text] You **cannot** do `config.environments(1).region = "new-value"` directly. This is a fundamental MATLAB limitation with custom indexing - you need to extract the array first, modify it, then assign back:
%[text] %TODO FIX This. This totally works. 
envs = config.environments;
envs(1).region = "us-west-1";  % Works: modify extracted array
config.environments = envs;     % Assign back
config.environments(1).region %[output:7f3f7b03]
%%
%[text] ## Mixed-Type Data
%[text] The features section contains booleans, strings, numbers, and nested objects:
show(config.features) %[output:28a13514]
%%
%[text] ## Why Not Struct?
%[text] ### What Struct Would Require
%[text] For the heterogeneous `services` array, struct would force you to:
%[text] 1. **Pad all elements with all possible fields** - Every service needs `database`, `smtp`, `spark-master`, etc. (even if empty)
%[text] 2. **Use loops or arrayfun for extraction** - No direct vectorized `services.name`
%[text] 3. **Manual aliasing** - Always use `s.("instance-type")` (no underscore shortcut)
%[text] 4. **Try-catch for optional fields** - No vectorized `iskey()` for filtering \
%[text] 
%[text] ### What ConfigurationData Provides
%[text] ✓ **Per-element schemas** - Only store what's actually there
%[text] ✓ **Vectorized extraction** - `services.name` returns typed arrays
%[text] ✓ **Automatic aliasing** - `instance_type` works alongside `("instance-type")`
%[text] ✓ **Explicit filtering** - `iskey()` returns logical arrays for clean filtering
%[text] ✓ **Type safety** - Clear errors if types don't match, no surprise cells
%%
%[text] ## Practical Example: Deployment Summary
%[text] Combine multiple operations to create a deployment overview table:
envs = config.environments;

%[text] Handle optional SSL field with `iskey()` guard:
hasSsl = iskey(envs, "ssl-enabled");
sslEnabled = false(size(envs));
sslEnabled(hasSsl) = [envs(hasSsl).("ssl-enabled")];
%%

summary = table(... %[output:group:6ab0ff1e] %[output:1bac20f9]
    envs.name', ... %[output:1bac20f9]
    envs.region', ... %[output:1bac20f9]
    envs.("instance-type")', ... %[output:1bac20f9]
    sslEnabled', ... %[output:1bac20f9]
    'VariableNames', ["Environment", "Region", "InstanceType", "SSL"]) %[output:group:6ab0ff1e] %[output:1bac20f9]
%%
%[text] ## Key Takeaways
%[text] ConfigurationData is designed for **heterogeneous hierarchical data** where:
%[text] - Elements in arrays don't share the same schema
%[text] - You want vectorized extraction (Pandas-like operations)
%[text] - Configuration files have special characters in keys
%[text] - Type safety matters (no silent cells or concatenation surprises) \
%[text] 
%[text] It's **not a struct replacement** - it's a specialized tool for configuration-like workflows.
%[text] 
%[text] **When to use struct:** Homogeneous records (database rows, patient data)
%[text] 
%[text] **When to use ConfigurationData:** Config files, heterogeneous event logs

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":6.2}
%---
%[output:28721226]
%   data: {"dataType":"textualVariable","outputData":{"name":"config","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    app-name: \"DataPipeline\"\n    version: \"3.2.1\"\n    build-system: \"gradle\"\n    environments: [1x3 YAMLData]\n    services: [1x5 YAMLData]\n    features: [1x1 YAMLData with 5 keys]\n    monitoring: [1x1 YAMLData with 1 key]\n    database-connections: [1x3 YAMLData]\n\n    <a href=\"matlab:show(config)\">Show all values<\/a>\n"}}
%---
%[output:935e7fdc]
%   data: {"dataType":"text","outputData":{"text":"app-name: DataPipeline\n\nversion: 3.2.1\n\nbuild-system: gradle\n\nenvironments:\n  - name: development\n    region: us-east-1\n    instance-type: t2.micro\n    debug-mode: true\n    log-level: debug\n  - name: staging\n    region: us-west-2\n    instance-type: t3.medium\n    ssl-enabled: true\n    backup-schedule: 0 2 * * *\n  - name: production\n    region: eu-central-1\n    instance-type: c5.xlarge\n    ssl-enabled: true\n    auto-scaling: true\n    min-instances: 3\n    max-instances: 10\n    backup-schedule: 0 1 * * *\n    monitoring-level: detailed\n\nservices:\n  - name: api-gateway\n    port: 8080\n    endpoints:\n      - \/health\n      - \/api\/v1\n      - \/metrics\n    rate-limit: 1000\n  - name: auth-service\n    port: 8081\n    database:\n      host: auth-db.internal\n      port: 5432\n      pool-size: 20\n    jwt-expiry: 3600\n  - name: data-processor\n    port: 8082\n    database:\n      host: main-db.internal\n      port: 5432\n      pool-size: 50\n    batch-size: 100\n    cache-enabled: true\n  - name: notification-service\n    port: 8083\n    smtp:\n      host: smtp.internal\n      port: 587\n    sms-provider: twilio\n  - name: analytics-engine\n    port: 8084\n    database:\n      host: analytics-db.internal\n      port: 5432\n      pool-size: 30\n    spark-master: spark:\/\/cluster:7077\n\nfeatures:\n  new-ui: true\n  experimental-api: false\n  beta-users:\n    - user123\n    - user456\n    - user789\n  rollout-percentage: 15\n  a-b-test:\n    variant-a: 0.5\n    variant-b: 0.5\n\nmonitoring:\n  metrics:\n    - name: response_time\n      unit: milliseconds\n      threshold: 500\n      alert: true\n    - name: error_rate\n      unit: percentage\n      threshold: 1\n      alert: true\n    - name: cpu_usage\n      unit: percentage\n      threshold: 80\n    - name: memory_usage\n      unit: percentage\n      threshold: 85\n      alert: true\n\ndatabase-connections:\n  - name: primary\n    host: main-db.internal\n    port: 5432\n    pool:\n      min-size: 5\n      max-size: 50\n      timeout: 30\n  - name: cache\n    host: redis.internal\n    port: 6379\n  - name: analytics\n    host: analytics-db.internal\n    port: 5432\n    read-only: true\n\n","truncated":false}}
%---
%[output:37672812]
%   data: {"dataType":"text","outputData":{"text":"\n  YAMLData with 8 keys\n\n    app-name:             \"DataPipeline\" (string)\n    version:              \"3.2.1\" (string)\n    build-system:         \"gradle\" (string)\n    environments:         1x3 array\n        name:               string\n        region:             string\n        instance-type:      string\n        debug-mode:         logical\n        log-level:          string\n        ssl-enabled:        logical\n        backup-schedule:    string\n        auto-scaling:       logical\n        min-instances:      double\n        max-instances:      double\n        monitoring-level:   string\n    services:             1x5 array\n        name:               string\n        port:               double\n        endpoints:          string\n        rate-limit:         double\n        database:           (3 keys)\n        jwt-expiry:         double\n        batch-size:         double\n        cache-enabled:      logical\n        smtp:               (2 keys)\n        sms-provider:       string\n        spark-master:       string\n    features:\n        new-ui:             true (logical)\n        experimental-api:   false (logical)\n        beta-users:         3x1 string\n        rollout-percentage: 15 (double)\n        a-b-test:\n            variant-a:          0.5 (double)\n            variant-b:          0.5 (double)\n    monitoring:\n        metrics:            1x4 array\n            name:               string\n            unit:               string\n            threshold:          double\n            alert:              logical\n    database-connections: 1x3 array\n        name:               string\n        host:               string\n        port:               double\n        pool:               (3 keys)\n        read-only:          logical\n\n","truncated":false}}
%---
%[output:3899c216]
%   data: {"dataType":"matrix","outputData":{"columns":8,"header":"1×8 string array","name":"ans","rows":1,"type":"string","value":[["app-name","version","build-system","environments","services","features","monitoring","database-connections"]]}}
%---
%[output:3b3ae415]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"3.2.1\""}}
%---
%[output:55baa46a]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"DataPipeline\""}}
%---
%[output:0ff5df81]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"DataPipeline\""}}
%---
%[output:6934927b]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"50"}}
%---
%[output:0a2103dc]
%   data: {"dataType":"textualVariable","outputData":{"name":"envs","value":"  1x3 <a href=\"matlab:helpPopup matlab.io.config.YAMLData\">YAMLData<\/a> array with keys:\n\n    name\n    region\n    instance-type\n    debug-mode\n    log-level\n    ssl-enabled\n    backup-schedule\n    auto-scaling\n    min-instances\n    max-instances\n    monitoring-level\n\n    (keys vary by element)\n\n    <a href=\"matlab:show(envs)\">Show all values<\/a>\n"}}
%---
%[output:76f79ab7]
%   data: {"dataType":"matrix","outputData":{"columns":11,"header":"1×11 string array","name":"ans","rows":1,"type":"string","value":[["name","region","instance-type","debug-mode","log-level","ssl-enabled","backup-schedule","auto-scaling","min-instances","max-instances","monitoring-level"]]}}
%---
%[output:037da8aa]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 logical array","name":"hasAutoScaling","rows":1,"type":"logical","value":[["0","0","1"]]}}
%---
%[output:41cc6b7d]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"envNames","rows":1,"type":"string","value":[["development","staging","production"]]}}
%---
%[output:5cb1acb2]
%   data: {"dataType":"text","outputData":{"text":"Key \"auto-scaling\" is missing in elements [1 2].\nUse iskey(arr, 'auto-scaling') to check which elements have this key.\n","truncated":false}}
%---
%[output:2e8447ad]
%   data: {"dataType":"textualVariable","outputData":{"name":"prodEnv","value":"  <a href=\"matlab:helpPopup('matlab.io.config.YAMLData')\" style=\"font-weight:bold\">YAMLData<\/a> with keys:\n\n    name: \"production\"\n    region: \"eu-central-1\"\n    instance-type: \"c5.xlarge\"\n    ssl-enabled: true\n    auto-scaling: true\n    min-instances: 3\n    max-instances: 10\n    backup-schedule: \"0 1 * * *\"\n    monitoring-level: \"detailed\"\n"}}
%---
%[output:67735d11]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   1\n"}}
%---
%[output:7d925521]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"ans","rows":1,"type":"double","value":[["8080","8081","8082","8083","8084"]]}}
%---
%[output:1c46a5b2]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"8082"}}
%---
%[output:64eac47a]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 string array","name":"nonProd","rows":1,"type":"string","value":[["t2.micro","t3.medium"]]}}
%---
%[output:941eae2d]
%   data: {"dataType":"matrix","outputData":{"columns":2,"header":"1×2 string array","name":"ans","rows":1,"type":"string","value":[["t3.large","t3.large"]]}}
%---
%[output:11b14c37]
%   data: {"dataType":"text","outputData":{"text":"name: michelle\n\nregion: us-east-1\n\ninstance-type: t3.large\n\ndebug-mode: true\n\nlog-level: debug\n\nbackup-enabled: true\n\nbackup-schedule: 0 3 * * *\n\n","truncated":false}}
%---
%[output:7f3f7b03]
%   data: {"dataType":"textualVariable","outputData":{"name":"ans","value":"\"us-west-1\""}}
%---
%[output:28a13514]
%   data: {"dataType":"text","outputData":{"text":"new-ui: true\n\nexperimental-api: false\n\nbeta-users:\n  - user123\n  - user456\n  - user789\n\nrollout-percentage: 15\n\na-b-test:\n  variant-a: 0.5\n  variant-b: 0.5\n\n","truncated":false}}
%---
%[output:1bac20f9]
%   data: {"dataType":"tabular","outputData":{"columnNames":["Environment","Region","InstanceType","SSL"],"columns":4,"dataTypes":["string","string","string","logical"],"header":"3×4 table","name":"summary","rows":3,"type":"table","value":[["\"development\"","\"new value\"","\"t2.micro\"","false"],["\"staging\"","\"us-west-2\"","\"t3.medium\"","true"],["\"production\"","\"eu-central-1\"","\"c5.xlarge\"","true"]]}}
%---

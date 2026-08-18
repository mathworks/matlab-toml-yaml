function result = merge(base, override)
%MERGE Recursively merge two configuration data objects
%   result = MERGE(base, override) returns a new object with all keys from
%   base, with any keys present in override taking the override value.
%   Nested objects are merged recursively.
%   Keys present only in override are added to the result.
%   The result has the same class as base.
%
%   Merge semantics:
%     - Override wins for any key present in both objects
%     - Nested objects: merged recursively (deep merge)
%     - Arrays, strings, numbers: override wins atomically (no concatenation)
%     - Keys only in base: kept as-is
%     - Keys only in override: added to result
%
%   Example:
%       defaults = yamldata();
%       defaults.timeout = 30;
%       defaults.retries = 3;
%       defaults.database.host = "localhost";
%       defaults.database.port = 5432;
%
%       userConfig = yamldata();
%       userConfig.timeout = 60;          % override
%       userConfig.database.host = "prod-db";  % override nested
%
%       config = merge(defaults, userConfig);
%       config.timeout            % 60 (from userConfig)
%       config.retries            % 3 (from defaults)
%       config.database.host      % "prod-db" (from userConfig)
%       config.database.port      % 5432 (from defaults)
%
%   See also: yamldata, tomldata, select

    arguments
        base matlab.io.config.ConfigurationData
        override matlab.io.config.ConfigurationData
    end

    % Start with a copy of base (same class preserved by value semantics)
    result = base;

    overrideKeys = keys(override);
    for i = 1:numel(overrideKeys)
        k = overrideKeys(i);
        overrideValue = getData(override, k);

        if iskey(result, k)
            baseValue = getData(result, k);
            % Recurse into nested ConfigurationData objects
            if isa(baseValue, 'matlab.io.config.ConfigurationData') && ...
               isa(overrideValue, 'matlab.io.config.ConfigurationData') && ...
               isscalar(baseValue) && isscalar(overrideValue)
                result.(k) = merge(baseValue, overrideValue);
            else
                % Atomic override: arrays, strings, numbers, etc.
                result.(k) = overrideValue;
            end
        else
            % Key only in override: add it
            result.(k) = overrideValue;
        end
    end
end

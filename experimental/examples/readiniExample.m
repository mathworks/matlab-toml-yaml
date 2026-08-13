;%  [text] Example: Reading INI Configuration Files
;%
;%  This example demonstrates readini functionality, showing how to work with INI 
;%  configuration files, access data with dot notation, handle special characters, 
;%  and work with sections.

%% Reading a Simple INI File

% Create sample INI file
iniContent = string([
    "[server]"
    "host=localhost"
    "port=8080"
    "ssl=false"
    ""
    "[database]"
    "host=db.example.com"
    "port=5432"
    "name=myapp"
]);
writematrix(iniContent, 'example_config.ini', 'FileType', 'text', 'Delimiter', '');

% Read the INI file
config = readini('example_config.ini');

% Access values using dot notation
host = config.server.host;
port = config.server.port;
ssl = config.server.ssl;

disp("Server Configuration:");
fprintf("  Host: %s\n", host);
fprintf("  Port: %s\n", port);
fprintf("  SSL: %s\n", ssl);

%% Access Section Data

dbHost = config.database.host;
dbPort = config.database.port;
dbName = config.database.name;

disp("Database Configuration:");
fprintf("  Host: %s\n", dbHost);
fprintf("  Port: %s\n", dbPort);
fprintf("  Database: %s\n", dbName);

%% Working with Different Data Types

% Create INI with various types
iniContent = string([
    "[settings]"
    "enabled=true"
    "debug=false"
    "port=9000"
    "timeout=30.5"
    "servers=alpha,beta,gamma"
]);
writematrix(iniContent, 'types_config.ini', 'FileType', 'text', 'Delimiter', '');

config = readini('types_config.ini');

% Values are auto-typed
enabled = config.settings.enabled;      % logical
port = config.settings.port;            % double
servers = config.settings.servers;      % string array
timeout = config.settings.timeout;      % double

fprintf("Enabled: %s (class: %s)\n", string(enabled), class(enabled));
fprintf("Port: %s (class: %s)\n", port, class(port));
fprintf("Timeout: %s (class: %s)\n", timeout, class(timeout));
fprintf("Servers: %s (class: %s)\n", strjoin(servers, ", "), class(servers));

%% Special Characters in Keys

iniContent = string([
    "[connection-pool]"
    "max-size=20"
    "min-size=5"
    "idle-timeout=300"
]);
writematrix(iniContent, 'pool_config.ini', 'FileType', 'text', 'Delimiter', '');

config = readini('pool_config.ini');

% Access with dynamic field names (original names preserved)
maxSize = config.("connection-pool").("max-size");
minSize = config.("connection-pool").("min-size");

% Or use aliased names (hyphens replaced with underscores)
idleTimeout = config.connection_pool.idle_timeout;

fprintf("Pool Max Size: %s\n", maxSize);
fprintf("Pool Min Size: %s\n", minSize);
fprintf("Idle Timeout: %s\n", idleTimeout);

%% Display Section Keys

allKeys = keys(config.("connection-pool"));
fprintf("Keys in connection-pool section: ");
disp(allKeys);

%% Convert to Struct

configStruct = struct(config);
disp("Configuration as struct:");
disp(configStruct);

%% Check for Sections

if isfield(config, 'server')
    disp("Server section found");
end

if isfield(config, 'cache')
    disp("Cache section found");
else
    disp("Cache section not found");
end

%% Cleanup

delete('example_config.ini');
delete('types_config.ini');
delete('pool_config.ini');

;%  [text] Example: Writing INI Configuration Files
;%
;%  This example demonstrates writeini functionality, showing how to create,
;%  modify, and write INI configuration files using IniData objects.

%% Creating and Writing Simple INI

% Create IniData object
config = inidata();

% Add server configuration
config.server.host = 'localhost';
config.server.port = 8080;
config.server.ssl = false;

% Add database configuration
config.database.host = 'db.example.com';
config.database.port = 5432;
config.database.name = 'myapp';
config.database.pool_size = 20;

% Write to file
writeini(config, 'app.ini');
disp("Wrote app.ini");

% Display the content
disp("INI content:");
disp(readlines('app.ini'));

%% Writing Different Data Types

config = inidata();

% Logical values
config.flags.debug = true;
config.flags.verbose = false;
config.flags.enabled = true;

% Numeric values
config.limits.max_connections = 100;
config.limits.timeout = 30.5;
config.limits.retry_count = 3;

% String values
config.paths.home = '/home/user';
config.paths.logs = '/var/log/app.log';
config.paths.data = 'C:\Users\AppData\Local\myapp';

% Arrays
config.ports.http = [8080 8443];
config.servers.names = ["primary" "secondary" "tertiary"];

writeini(config, 'complete.ini');
disp("Wrote complete.ini with various data types");

%% Modifying Existing Configuration

% Read existing config
config = readini('app.ini');

% Modify values
config.server.port = 9000;
config.server.ssl = true;
config.database.pool_size = 50;

% Add new section
config.logging.level = 'INFO';
config.logging.file = '/var/log/myapp.log';

% Write back
writeini(config, 'app_updated.ini');
disp("Updated app_updated.ini");

%% Using Different Output Options

% Compact spacing (default)
config = inidata();
config.section1.key1 = 'value1';
config.section2.key2 = 'value2';
config.section3.key3 = 'value3';

writeini(config, 'compact.ini', 'SectionSpacing', 'compact');
disp("Compact spacing version:");
disp(readlines('compact.ini'));

% Loose spacing
writeini(config, 'loose.ini', 'SectionSpacing', 'loose');
disp("Loose spacing version:");
disp(readlines('loose.ini'));

%% Controlling Numeric Precision

config = inidata();
config.math.pi = pi;
config.math.e = exp(1);
config.math.golden = (1 + sqrt(5)) / 2;

% Default precision (6 significant figures)
writeini(config, 'math_default.ini', 'Precision', 6);
disp("Default precision (6):");
disp(readlines('math_default.ini'));

% Higher precision
writeini(config, 'math_precise.ini', 'Precision', 12);
disp("Higher precision (12):");
disp(readlines('math_precise.ini'));

%% Converting Struct to INI

% Create a struct
appSettings = struct();
appSettings.app.name = 'MyApplication';
appSettings.app.version = '2.0.0';
appSettings.app.author = 'John Doe';
appSettings.ui.theme = 'dark';
appSettings.ui.language = 'en-US';
appSettings.performance.cache_size = 1024;
appSettings.performance.thread_pool = 8;

% Write struct directly
writeini(appSettings, 'settings.ini');
disp("Converted struct to settings.ini");
disp(readlines('settings.ini'));

%% Using containers.Map

% Create a Map-based config
configMap = containers.Map();

serverMap = containers.Map();
serverMap('host') = 'localhost';
serverMap('port') = 8080;
configMap('server') = serverMap;

dbMap = containers.Map();
dbMap('host') = 'database.local';
dbMap('name') = 'appdb';
configMap('database') = dbMap;

% Write Map to INI
writeini(configMap, 'map_config.ini');
disp("Wrote map_config.ini from containers.Map");

%% Create Configuration from Struct then Modify

% Start with struct
config = struct();
config.database.host = 'localhost';
config.database.port = 5432;

% Convert to IniData
iniData = inidata();
iniData.database.host = config.database.host;
iniData.database.port = config.database.port;

% Add more sections
iniData.caching.enabled = true;
iniData.caching.ttl = 3600;

writeini(iniData, 'hybrid.ini');
disp("Created hybrid.ini from combined struct and manual config");

%% Create Independent Copy and Verify

original = inidata();
original.app.name = 'Original';
original.app.value = 100;

% Create independent copy
modified = copy(original);
modified.app.value = 200;

disp("Original value: " + original.app.value);
disp("Modified value: " + modified.app.value);

writeini(original, 'original.ini');
writeini(modified, 'modified.ini');

%% Cleanup

delete('app.ini');
delete('app_updated.ini');
delete('complete.ini');
delete('compact.ini');
delete('loose.ini');
delete('math_default.ini');
delete('math_precise.ini');
delete('settings.ini');
delete('map_config.ini');
delete('hybrid.ini');
delete('original.ini');
delete('modified.ini');

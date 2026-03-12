%[text] # Issue \#74: Missing Returns for Absent Keys
%[text] Comparison of current vs proposed behavior for heterogeneous arrays.
%%
%[text] ## Setup: Heterogeneous Event Array
events = yamldata();
events(1).type = "reading";
events(1).sensor = "temperature";
events(1).value = 72.5;
events(1).timestamp = datetime('now');
events(2) = yamldata;
events(2).type = "reading";
events(2).sensor = "humidity";
events(2).value = 45.2;
events(2).timestamp = datetime('now') + minutes(5);
events(3) = yamldata;
events(3).type = "start";
events(3).message = "System started";
events(3).timestamp = datetime('now') + minutes(10);
events(4) = yamldata;
events(4).type = "error";
events(4).message = "Connection timeout";
events(4).code = 503;
events(4).timestamp = datetime('now') + minutes(15);
events(5) = yamldata;
events(5).type = "reading";
events(5).sensor = "temperature";
events(5).value = 73.1;
events(5).timestamp = datetime('now') + minutes(20);
events %[output:7eaf2c04]
[k,keysByElement] = keys(events);
keysByElement{:} %[output:28720b8b] %[output:5a08e5d9] %[output:484722a8] %[output:4494c655] %[output:526ef7ec]
%%
%[text] ## Scenario 1: Filter by Sensor Type
%[text] **CURRENT (3 steps):**
hasSensor = iskey(events, "sensor");
eventsWithSensor = events(hasSensor);
tempReadings = eventsWithSensor(eventsWithSensor.sensor == "temperature");
numel(tempReadings)
%%
%[text] **PROPOSED (1 step):**
%[text] ```matlabCodeExample
%[text] tempReadings = events(events.sensor == "temperature");
%[text] % events.sensor → ["temperature", "humidity", missing, missing, "temperature"]
%[text] % == comparison → [true, false, false, false, true]
%[text] % Result: 1x2 YAMLData with elements [1, 5]
%[text] ```
%%
%[text] ## Scenario 2: Count Events by Sensor
%[text] Code is similar. In both cases, we need to filter the array before calling unique.
%[text] **CURRENT:** Use iskey
sensorTypes = events(iskey(events, "sensor")).sensor;
[uniqueSensors, ~, ic] = unique(sensorTypes);
counts = accumarray(ic, 1);
%%
%[text] **PROPOSED:** Use iskey or ismissing
%[text] ```matlabCodeExample
%[text] sensorTypes = events.sensor(~ismissing(events.sensor));  % ["temperature", "humidity", "temperature"]
%[text] [uniqueSensors, ~, ic] = unique(sensorTypes);
%[text] counts = accumarray(ic, 1);
%[text] % Result: ["humidity"; "temperature"] with counts [1; 2]
%[text] ```
%%
%[text] ## Scenario 3: Extract Multiple Fields for Plotting
%[text] **CURRENT (3 lines):**
hasSensor = iskey(events, "sensor");
sensors = events(hasSensor).sensor;
values = events(hasSensor).value;
times = events(hasSensor).timestamp;
[sensors; values; times]
%%
%[text] **PROPOSED (3 lines with reusable mask):**
%[text] ```matlabCodeExample
%[text] mask = ~ismissing(events.sensor);  % 1x5 logical: [T T F F T]
%[text] sensors = events.sensor(mask);     % 1x3 string: ["temperature", "humidity", "temperature"]
%[text] values = events.value(mask);       % 1x3 double: [72.5, 45.2, 73.1]
%[text] times = events.timestamp(mask);    % 1x3 datetime
%[text] ```
%[text] Both approaches are 3 lines, but proposed computes mask once and reuses it.
%%
%[text] ## Scenario 4: Conditional Logic in Loop
%[text] **CURRENT:**
for i = 1:numel(events) %[output:group:9c27beb8]
    if iskey(events(i), "sensor")
        fprintf("%s: %s = %.1f\n", events(i).type, events(i).sensor, events(i).value); %[output:6d925854] %[output:075af7e2]
    else
        fprintf("%s: %s\n", events(i).type, events(i).message); %[output:15d37069]
    end
end %[output:group:9c27beb8]
%%
%[text] **PROPOSED:**
%[text] ```matlabCodeExample
%[text] for i = 1:numel(events)
%[text]     sensor = events(i).sensor;
%[text]     if ~ismissing(sensor)
%[text]         fprintf("%s: %s = %.1f\n", events(i).type, sensor, events(i).value);
%[text]     else
%[text]         fprintf("%s: %s\n", events(i).type, events(i).message);
%[text]     end
%[text] end
%[text] ```
%%
%[text] ## Scenario 5: Data Validation
%[text] Find events that should have sensor but don't.
%[text] **CURRENT (3 lines):**
hasSensor = iskey(events, "sensor");
isReading = (events.type == "reading");
invalid = isReading & ~hasSensor;
find(invalid)
%%
%[text] **PROPOSED (1 line):**
%[text] ```matlabCodeExample
%[text] invalid = (events.type == "reading") & ismissing(events.sensor);
%[text] % Result: empty (all readings have sensors in this example)
%[text] ```
%%
%[text] ## Scenario 6: Update Values Back into Original Array
%[text] Scale all temperature readings by 1.1x
%[text] **CURRENT (complex index mapping):**
hasSensor = iskey(events, "sensor");
sensorIndices = find(hasSensor);  % Keep track of indices of original array with key sensor
eventsWithSensor = events(hasSensor);
tempMask = eventsWithSensor.sensor == "temperature";
tempIndices = sensorIndices(tempMask);
events(tempIndices).value = events(tempIndices).value * 1.1;
events(tempIndices).value %[output:536621db]
%%
%[text] **PROPOSED (direct boolean indexing):**
%[text] ```
%[text] tempSensors = (events.sensor == "temperature");  % [T F F F T]
%[text] events(tempMask).value = events(tempSensors).value*1.1;
%[text] 
%[text] % Or 1-liner
%[text] events(events.sensor == "temperature").value = events(events.sensor == "temperature").value * 1.1;
%[text] ```
%[text] 
%%
%[text] ## Key Design Property: Keys Aren't Actually Added
%[text] ```matlabCodeExample
%[text] events(3).sensor           % returns: missing
%[text] iskey(events(3), "sensor") % returns: false
%[text] keys(events(3))            % returns: ["type", "message", "timestamp"]
%[text] ```
%[text] This is read-only convenience without side effects!
%%
%[text] ## Composability of `missing`
%[text] - `missing == "value"` → `false`
%[text] - `missing ~= "value"` → `false`
%[text] - `ismissing(missing)` → `true`
%[text] - Works with: `any()`, `all()`, `mean(..., "omitmissing")`, `sort()`
%[text] - Concatenates: `[val1, missing, val3]` becomes `NaN` for double \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:7eaf2c04]
%   data: {"dataType":"textualVariable","outputData":{"name":"events","value":"  1x5 <a href=\"matlab:helpPopup matlab.io.config.YAMLData\">YAMLData<\/a> array with keys:\n\n    type\n    sensor\n    value\n    timestamp\n    message\n    code\n\n    (keys vary by element)\n\n    <a href=\"matlab:show(events)\">Show all values<\/a>\n"}}
%---
%[output:28720b8b]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["type","sensor","value","timestamp"]]}}
%---
%[output:5a08e5d9]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["type","sensor","value","timestamp"]]}}
%---
%[output:484722a8]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["type","message","timestamp"]]}}
%---
%[output:4494c655]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["type","message","code","timestamp"]]}}
%---
%[output:526ef7ec]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["type","sensor","value","timestamp"]]}}
%---
%[output:6d925854]
%   data: {"dataType":"text","outputData":{"text":"reading: temperature = 96.5\nreading: humidity = 45.2\n","truncated":false}}
%---
%[output:15d37069]
%   data: {"dataType":"text","outputData":{"text":"start: System started\nerror: Connection timeout\n","truncated":false}}
%---
%[output:075af7e2]
%   data: {"dataType":"text","outputData":{"text":"reading: temperature = 97.3\n","truncated":false}}
%---
%[output:536621db]
%   data: {"dataType":"matrix","outputData":{"columns":2,"name":"ans","rows":1,"type":"double","value":[["96.4975","97.2961"]]}}
%---

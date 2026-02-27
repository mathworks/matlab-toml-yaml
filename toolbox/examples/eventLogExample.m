%[text] # Event Log Processing: Heterogeneous Schema Handling
%[text] Processing event streams is a natural fit for `configdata` arrays. Events from a real system rarely share the same fields — a `"start"` event carries a session ID, a `"measurement"` event carries sensor data, and an `"error"` event carries an error code and message. Struct arrays require every element to have every field, which means either padding with empty placeholders or giving up vectorized access. `configdata` arrays have no such constraint.
%[text] 
%[text] **ConfigurationData features used:**
%[text] - **Heterogeneous schema per element** — Each event type has only the fields it needs
%[text] - **Dot access on arrays** — Extract typed MATLAB arrays from filtered subsets
%[text] - **iskey() filtering** — Select elements by field presence without try-catch
%[text] - **keys() union** — Inspect all field names across the entire array \
%%
%[text] ## Build the Event Log
%[text] Construct a synthetic stream of events. Each event is a `configdata` object. `"start"`, `"measurement"`, and `"error"` events each share a `timestamp` and `type` field, plus their own type-specific fields.
rng(0)

% Start event
e = configdata(); 
e.timestamp = 0; 
e.type = "start"; 
e.session_id = "abc123";

events = e;

% Simulate several temperature measurement events
for i = 1:5
    e = configdata();
    e.timestamp = i * 10;
    e.type = "measurement";
    e.sensor = "temperature";
    e.value = 20 + randn();
    e.unit = "celsius";

    % Add to events array
    events = [events, e];
end

% Add an error event
e = configdata(); 
e.timestamp = 37; 
e.type = "error";
e.code = 404; 
e.message = "Sensor timeout";

events = [events, e];

% Add some pressure measurement events
for i = 6:8
    e = configdata();
    e.timestamp = i * 10;
    e.type = "measurement";
    e.sensor = "pressure";
    e.value = 1013 + 2*randn();
    e.unit = "hPa";
    events = [events, e];
end
%%
%[text] ## Inspect the Array
%[text] Calling `keys` on a `configdata` array returns the **union** of all key names across every element. A second output gives the per-element key set, making it easy to see which events have which fields.
keys(events) %[output:949af8d6]
%%
[allKeys, perEvent] = keys(events);
isequal(perEvent{:}) %[output:254f1fa8]
%%
%[text] ## Filter by Event Type
%[text] Dot access on a `configdata` array gathers a field from every element. Because every event has `type`, this returns a string array you can compare directly. Logical indexing then selects the matching subset.
measurements = events(events.type == "measurement") %[output:998a13a1]
%%
errors = events(events.type == "error") %[output:30398496]
%%
%[text] ## Extract Typed Arrays from the Filtered Subset
%[text] Once you have a homogeneous subset, vectorized dot access returns typed MATLAB arrays — no loops, no cell gymnastics.
timestamps = measurements.timestamp %[output:52c463c0]
%%
values = measurements.value %[output:8936eed0]
%%
sensors = measurements.sensor %[output:53b79aac]
%%
%[text] ## Filter by Key Presence
%[text] The measurement events in this log come from two different sensors and would not all share the same sub-fields in a richer schema. `iskey` is vectorized: it returns a logical array the same size as the input, one entry per element.
hasSensor = iskey(events, "sensor") %[output:01f414fd]
%%
%[text] Use the result as a logical index to only work with elements that have this key, then select only temperature readings, then compute the mean.
eventsWithSensor = events(hasSensor);
tempReadings = eventsWithSensor(eventsWithSensor.sensor == "temperature");
avgTemp = mean(tempReadings.value) %[output:8a865e65]
%%
%[text] ## Why Not a Struct Array?
%[text] A MATLAB struct array requires every element to have the same field names. You would have to pad the `"start"` event with empty `sensor`, `value`, `unit`, `code`, and `message` fields, and do the same for `"error"` events. That padding is pure noise: `mean([events.value])` would silently include the empty placeholders unless you remembered to filter first.
%[text] 
%[text] With `configdata`, the schema is per-element. Extracting `measurements.value` gives you only the values that exist. Filtering with `iskey` is explicit and composable. The result is direct vectorized access on heterogeneous data — without the boilerplate.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:949af8d6]
%   data: {"dataType":"matrix","outputData":{"columns":8,"header":"1×8 string array","name":"ans","rows":1,"type":"string","value":[["timestamp","type","session_id","sensor","value","unit","code","message"]]}}
%---
%[output:254f1fa8]
%   data: {"dataType":"textualVariable","outputData":{"header":"logical","name":"ans","value":"   0\n"}}
%---
%[output:998a13a1]
%   data: {"dataType":"textualVariable","outputData":{"name":"measurements","value":"  1x8 <a href=\"matlab:helpPopup matlab.io.config.ConfigurationData\">ConfigurationData<\/a> array with keys:\n\n    timestamp\n    type\n    sensor\n    value\n    unit\n\n    <a href=\"matlab:show(measurements)\">Show all values<\/a>\n"}}
%---
%[output:30398496]
%   data: {"dataType":"textualVariable","outputData":{"name":"errors","value":"  <a href=\"matlab:helpPopup('matlab.io.config.ConfigurationData')\" style=\"font-weight:bold\">ConfigurationData<\/a> with keys:\n\n    timestamp: 37\n    type: \"error\"\n    code: 404\n    message: \"Sensor timeout\"\n"}}
%---
%[output:52c463c0]
%   data: {"dataType":"matrix","outputData":{"columns":8,"name":"timestamps","rows":1,"type":"double","value":[["10","20","30","40","50","60","70","80"]]}}
%---
%[output:8936eed0]
%   data: {"dataType":"matrix","outputData":{"columns":8,"exponent":"3","name":"values","rows":1,"type":"double","value":[["0.0205","0.0218","0.0177","0.0209","0.0203","1.0104","1.0121","1.0137"]]}}
%---
%[output:53b79aac]
%   data: {"dataType":"matrix","outputData":{"columns":8,"header":"1×8 string array","name":"sensors","rows":1,"type":"string","value":[["temperature","temperature","temperature","temperature","temperature","pressure","pressure","pressure"]]}}
%---
%[output:01f414fd]
%   data: {"dataType":"matrix","outputData":{"columns":10,"header":"1×10 logical array","name":"hasSensor","rows":1,"type":"logical","value":[["0","1","1","1","1","1","0","1","1","1"]]}}
%---
%[output:8a865e65]
%   data: {"dataType":"textualVariable","outputData":{"name":"avgTemp","value":"20.2587"}}
%---

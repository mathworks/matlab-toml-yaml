% Test script for Issue #74: missing key behavior implementation

% Setup
addpath('../../toolbox');

%% Test 1: Basic missing behavior - double values
fprintf('Test 1: Basic missing behavior with double values\n');

% Create events as individual objects first
event1 = configdata();
event1.type = "reading";
event1.sensor = "temperature";
event1.value = 20.5;

event2 = configdata();
event2.type = "start";
event2.message = "System started";

event3 = configdata();
event3.type = "reading";
event3.sensor = "temperature";
event3.value = 21.3;

event4 = configdata();
event4.type = "error";
event4.message = "Connection failed";

event5 = configdata();
event5.type = "reading";
event5.sensor = "humidity";
event5.value = 65.0;

% Concatenate into array
events = [event1; event2; event3; event4; event5];

% Access sensor field - should return [string, missing, string, missing, string]
sensorValues = events.sensor;
fprintf('  events.sensor: ');
disp(sensorValues);
assert(numel(sensorValues) == 5, 'Should have 5 elements');
assert(ismissing(sensorValues(2)), 'Element 2 should be missing');
assert(ismissing(sensorValues(4)), 'Element 4 should be missing');
assert(sensorValues(1) == "temperature", 'Element 1 should be temperature');
fprintf('  PASS: Missing values returned correctly\n\n');

%% Test 2: Filtering with missing values
fprintf('Test 2: Filtering with missing == comparison\n');
tempMask = events.sensor == "temperature";
fprintf('  Mask: ');
disp(tempMask);
tempReadings = events(tempMask);
assert(numel(tempReadings) == 2, 'Should have 2 temperature readings');
fprintf('  PASS:Filtering works correctly\n\n');

%% Test 3: Keys aren't actually added (read-only)
fprintf('Test 3: Verify keys are not actually added\n');
% Access sensor on array (returns missing for elements 2 and 4)
allSensors = events.sensor;
% But the key should NOT be added to elements that didn't have it
hasKey2 = iskey(events(2), "sensor");
hasKey4 = iskey(events(4), "sensor");
assert(~hasKey2, 'Key should not be added to element 2 by read access');
assert(~hasKey4, 'Key should not be added to element 4 by read access');
keyList2 = keys(events(2));
assert(~any(keyList2 == "sensor"), 'sensor should not appear in keys() for element 2');
fprintf('  PASS:Keys remain unchanged (read-only behavior)\n\n');

%% Test 4: All missing case
fprintf('Test 4: All values missing\n');
allMissingSensors = events(2:2:4).sensor;  % Elements 2 and 4 lack sensor
fprintf('  Result: ');
disp(allMissingSensors);
assert(numel(allMissingSensors) == 2, 'Should have 2 elements');
assert(all(ismissing(allMissingSensors)), 'All should be missing');
fprintf('  PASS:All-missing case works\n\n');

%% Test 5: Numeric values with missing
fprintf('Test 5: Numeric (double) values with missing\n');
valueArray = events.value;  % Elements 2 and 4 lack "value"
fprintf('  events.value: ');
disp(valueArray);
assert(numel(valueArray) == 5, 'Should have 5 elements');
assert(isnan(valueArray(2)), 'Missing should coerce to NaN for double');
assert(isnan(valueArray(4)), 'Missing should coerce to NaN for double');
fprintf('  PASS:Missing coerces to NaN for double\n\n');

%% Test 6: Assignment still adds the key
fprintf('Test 6: Assignment adds the key (asymmetric behavior)\n');
events(2).sensor = missing;
hasKeyNow = iskey(events(2), "sensor");
assert(hasKeyNow, 'Assignment should add the key');
fprintf('  PASS:Assignment adds key as expected\n\n');

fprintf('All tests passed!\n');

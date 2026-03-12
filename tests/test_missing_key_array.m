% Test script to verify missing key behavior on arrays
% Issue: When querying an array, should error if key doesn't exist on ANY element

%% Test 1: Scalar with missing key should error
t = tomldata;
t.newkey = "my key";
try
    val = t.notakey;
    error('Expected error for missing key on scalar');
catch ME
    if contains(ME.identifier, 'InvalidKey')
        fprintf('PASS: Scalar with missing key errors correctly\n');
    else
        fprintf('FAIL: Wrong error type: %s\n', ME.identifier);
    end
end

%% Test 2: Array element with missing key should error
t = tomldata;
t.newkey = "my key";
t(2) = tomldata;
try
    val = t(2).notakey;
    error('Expected error for missing key on array element');
catch ME
    if contains(ME.identifier, 'InvalidKey')
        fprintf('PASS: Array element with missing key errors correctly\n');
    else
        fprintf('FAIL: Wrong error type: %s\n', ME.identifier);
    end
end

%% Test 3: Array with key missing on ALL elements should error
t = tomldata;
t.newkey = "my key";
t(2) = tomldata;
try
    val = t.notakey;
    error('Expected error for key missing on all array elements');
catch ME
    if contains(ME.identifier, 'InvalidKey')
        fprintf('PASS: Array with key missing on all elements errors correctly\n');
    else
        fprintf('FAIL: Wrong error type: %s\n', ME.identifier);
    end
end

%% Test 4: Array with key on SOME elements should return mixed values
t = tomldata;
t.sensor = "temperature";
t(2) = tomldata;
t(2).location = "lab";  % Different key on second element

try
    val = t.sensor;
    if numel(val) == 2 && val(1) == "temperature" && ismissing(val(2))
        fprintf('PASS: Array with partial key coverage returns mixed values\n');
    else
        fprintf('FAIL: Unexpected result: %s\n', string(val));
    end
catch ME
    fprintf('FAIL: Should not error for partial key coverage: %s\n', ME.message);
end

%% Test 5: Array with key on ALL elements should return all values
t = tomldata;
t.sensor = "temperature";
t(2) = tomldata;
t(2).sensor = "pressure";

try
    val = t.sensor;
    if numel(val) == 2 && val(1) == "temperature" && val(2) == "pressure"
        fprintf('PASS: Array with full key coverage returns all values\n');
    else
        fprintf('FAIL: Unexpected result: %s\n', string(val));
    end
catch ME
    fprintf('FAIL: Should not error for full key coverage: %s\n', ME.message);
end

%[text] # Experiment Tracking with configdata() and merge()
%[text] When running a parameter sweep, you need to track both the configuration that produced each result and the result itself. This example shows how `configdata()` and `merge()` make that natural — parameters and results live in the same object, variant creation is concise, and array operations make analysis straightforward.
%[text] **ConfigurationData features used:**
%[text] - **Arrays of ConfigurationData** — Store parameters and results together in each element
%[text] - **merge()** — Create parameter variants by specifying only what changes
%[text] - **Dot access on arrays** — Extract fields from all elements without loops
%[text] - **Heterogeneous schema with iskey()** — Add fields to only the elements that need them \
%%
%[text] ## Define Base Parameters
%[text] Start with a shared base configuration that every run inherits.
baseParams = configdata();
baseParams.model = "linear";
baseParams.epochs = 50;
baseParams.optimizer = "sgd";
%%
%[text] ## Create Per-Run Parameter Sets with merge()
%[text] Initialize an array of runs, to store results for each different learning rate. `merge()` combines two objects, with the second taking precedence for any overlapping keys. Here it means each run specifies only what changes — the shared parameters come through automatically. No copying boilerplate.
runs = [];
learningRates = [0.001, 0.01, 0.1, 0.5];
for i = 1:numel(learningRates)
    learningRateConfig=configdata(struct('learning_rate', learningRates(i)));
    params = merge(baseParams, learningRateConfig);
    runs = [runs, params];
end
runs %[output:050ec1b5]
%%
%[text] ## Simulate Results
%[text] In a real workflow you would train a model here and record what came back. For illustration, a synthetic accuracy function peaks near `learning_rate = 0.01`. The results are written directly onto the same object that holds the parameters — no parallel arrays to keep in sync.
rng(42)
for i = 1:numel(runs)
    lr = runs(i).learning_rate;
    % Synthetic accuracy: best around lr=0.01
    runs(i).accuracy = 0.95 * exp(-50*(log(lr/0.01))^2) + 0.02*randn();
    runs(i).epochs_to_converge = round(20 + 80/(1 + lr*100));
end
%%
%[text] ## Analyze the Array
%[text] Dot access on a ConfigurationData array collects that field from every element and returns it as a plain MATLAB array — no loop required. Use this to find the best run and retrieve its complete record.
runs.learning_rate %[output:6ecdfe95]
runs.accuracy %[output:6ba46361]
%%
[bestAccuracy, idx] = max(runs.accuracy);
bestRun = runs(idx) %[output:6aacc693]
%%
%[text] ## Heterogeneous Fields with iskey()
%[text] Not every run needs the same keys. Runs that converged quickly triggered early stopping — a field that simply does not exist on the others. `iskey()` is vectorized across arrays, so you can filter by field presence without guarding every access.
for i = 1:numel(runs)
    if runs(i).epochs_to_converge < 30
        runs(i).early_stopped = true;
        runs(i).stopped_at_epoch = runs(i).epochs_to_converge;
    end
end
earlyStopped = runs(iskey(runs, "early_stopped")) %[output:5b695d4f]
%%
%[text] Note: We use `iskey()` here rather than direct filtering (`runs.early_stopped == true`) because the goal is to find runs where the field was explicitly set. While direct filtering would work (since `missing == true` is `false`), using `iskey()` makes the intent clearer: "get runs that have this field."
%%
%[text] Each entry in `earlyStopped` carries its full parameter set alongside the early-stopping metadata — everything in one place, with no schema enforcement forcing uniformity where the data naturally varies.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:050ec1b5]
%   data: {"dataType":"textualVariable","outputData":{"name":"runs","value":"  1x4 <a href=\"matlab:helpPopup matlab.io.config.ConfigurationData\">ConfigurationData<\/a> array with keys:\n\n    model\n    epochs\n    optimizer\n    learning_rate\n\n    <a href=\"matlab:show(runs)\">Show all values<\/a>\n"}}
%---
%[output:6ecdfe95]
%   data: {"dataType":"matrix","outputData":{"columns":4,"name":"ans","rows":1,"type":"double","value":[["0.0010","0.0100","0.1000","0.5000"]]}}
%---
%[output:6ba46361]
%   data: {"dataType":"matrix","outputData":{"columns":4,"name":"ans","rows":1,"type":"double","value":[["-0.0108","0.9673","0.0195","0.0067"]]}}
%---
%[output:6aacc693]
%   data: {"dataType":"textualVariable","outputData":{"name":"bestRun","value":"  <a href=\"matlab:helpPopup('matlab.io.config.ConfigurationData')\" style=\"font-weight:bold\">ConfigurationData<\/a> with keys:\n\n    model: \"linear\"\n    epochs: 50\n    optimizer: \"sgd\"\n    learning_rate: 0.01\n    accuracy: 0.967345\n    epochs_to_converge: 60\n"}}
%---
%[output:5b695d4f]
%   data: {"dataType":"textualVariable","outputData":{"name":"earlyStopped","value":"  1x2 <a href=\"matlab:helpPopup matlab.io.config.ConfigurationData\">ConfigurationData<\/a> array with keys:\n\n    model\n    epochs\n    optimizer\n    learning_rate\n    accuracy\n    epochs_to_converge\n    early_stopped\n    stopped_at_epoch\n\n    <a href=\"matlab:show(earlyStopped)\">Show all values<\/a>\n"}}
%---

# #76: Can/should we get tab completion to work when there are heterogeneous keys?

**State:** open  
**Created:** 2026-02-23  

## Description

Tab completion doesn't offer keys when you dot index into an array .
Example: toolbox/examples/experimentTrackingExample.m

```matlab 
baseParams = configdata();
baseParams.model = "linear";
baseParams.epochs = 50;
baseParams.optimizer = "sgd";

runs = [];
learningRates = [0.001, 0.01, 0.1, 0.5];
for i = 1:numel(learningRates)
    params = merge(baseParams, configdata(struct('learning_rate', learningRates(i))));
    runs = [runs, params];
end
runs
```

`runs(1).<TAB>` Includes a list of keys
`runs.<TAB>` Does not include a list of keys

Can we do better? With current design, need to figure out what to do about keys that aren't on every element since they'll error. If we accept the proposal in issue #74, it will just work.



# #75: show isn't useful on ConfigurationData

**State:** open  
**Created:** 2026-02-23  

## Description

Since ConfigurationData isn't specialized to a file format, show doesn't seem to know what to do. It just does the same as describe, and doesn't show any values. Example:

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
show(runs)


  1x4 array

    model:              string
    epochs:             double
    optimizer:          string
    learning_rate:      double
```

We should probably show a generic tree structure, likely just simple indenting, but optionally with some ascii art to better show alignment.

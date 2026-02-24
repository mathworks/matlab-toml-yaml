# #73: describe could give more useful information when keys aren't the same across all elements of an array

**State:** open  
**Created:** 2026-02-23  
**Labels:** enhancement  

## Description

I came across this while running toolbox/examples/eventLogExample.m, using configdata. I assume this applies to specializations like tomldata, too.

describe lists all keys and their types:
```matlab
>> describe(events)
1x10 array

    timestamp:          double
    type:               string
    session_id:         string
    sensor:             string
    value:              double
    unit:               string
    code:               double
    message:            string
```

It could be helpful to tell you more, e.g.
```matlab
    timestamp:          double    (all elements)
    type:               string    (all elements)
    session_id:         string (element 1)
    sensor:             string (elements 2,3,4,5,6,8 and 10)
...
```
I don't think this is quite the right design, but maybe there's something we could do here.

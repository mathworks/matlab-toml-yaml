# #41: Update TOML/YAML/INIData compact display to hide namespace

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-02  

## Description

We've got a nice compact/contained display for TOMLData and friends, but it got uglier when I moved TOMLData into a namespace:

```
config = tomldata();
        config.database.host = 'localhost';
        config.database.port = 5432;

>> config

config = 

  [TOMLData] with keys:

    database: [1x1 matlab.io.config.TOMLData with 2 keys]

    [Show all values](matlab:show(config))
```

Let's update so it doesn't show the namespace:

```
>> config

config = 

  [TOMLData] with keys:

    database: [1x1 TOMLData with 2 keys]

    [Show all values](matlab:show(config))
```



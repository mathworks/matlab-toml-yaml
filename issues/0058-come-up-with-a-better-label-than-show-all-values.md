# #58: Come up with a better label than "Show all values"

**State:** open  
**Created:** 2026-02-03  

## Description

When displaying any of our objects, the footer has a link that says "Show all values". This link is patterned after the display of objects such as graphics objects with truncated displays. But it's not a good description of what it does, and the output is quite jarring. The output is actually a pretty print display of the object. It does show all keys and values (navigating down through hierarchy), but it also formats it to look like the native file format - JSON, TOML, YAML. I think it's the right behavior - it's super convenient to click on the link to see the formatted display. But we need a better label for the hyperlink.

```
special = 

  YAMLData with keys:

    pull-request: [1x1 YAMLData with 2 keys]
    push_event: [1x1 YAMLData with 1 key]

    Show all values
```

Click show all values:
```yaml
pull-request:
  target-branch: main
  auto-merge: true
push_event:
  enabled: false
```

## Comments

### Comment by michellehirsch on 2026-02-05

Idea:
"display all values with show" (make show) a link.

This isn't quite right, but gets us closer

### Comment by michellehirsch on 2026-02-09

Consider if the footer should also include a link to run `describe`. Adding this footer may get us to change the name of this function - maybe `summarize`? 

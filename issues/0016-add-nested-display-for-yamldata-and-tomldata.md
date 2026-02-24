# #16: Add nested display for YAMLData and TOMLData

**State:** open  
**Created:** 2026-01-16  

## Description

Its not uncommon to have deeply nested YAML and TOML data. I prototyped a nested incremental display with expandable hyperlinks for JSONTree that might be useful for the `ConfigurationData` subclasses too:

<img width="356" height="343" alt="Image" src="https://github.com/user-attachments/assets/2676efcf-dc86-4b1e-8fc1-045e43e7b1d4" />

## Comments

### Comment by michellehirsch on 2026-01-16

My first pass at this is the show() method, which is also accessible via a link in the footer. I've found it to work well for me - you can show the entire object, or pass in a sub-object to just see part.

The behavior is the same as the corresponding write* function, just without support for any options (because I didn't want it to evolve into being an in-memory toml/yaml encoder).

Does that address the issue, or do you think we can do better?

### Comment by aylindmello on 2026-01-16

The `show` method is pretty good - I've used the footer link a couple of times already. I do think we can make the sub-tree display nicer though.

I think I found an elegant way to do this in jsonTree - I can try the same kind of display here.

### Comment by michellehirsch on 2026-02-02

I've played with jsonTree a bit, and I'm not sure the display is better. I'm finding it too hard to take in a json tree with a display that looks like json. I end up relying on tab completion as the only way to get a handle on what keys are in the data. I find the approach I took with these classes more convenient - the display defaults to struct-like, with a `show` method when you want to see pretty-print.

Perhaps there are options in the show method to collapse some really long displays and give links to expand, but so far for the files I look at, the ability to just call show at any level of the tree seems to work quite well).

# #23: Build as a package and MLTBX

**State:** open  
**Created:** 2026-01-16  
**Labels:** design  

## Description

Jeremy wonders if we should use packages instead of projects.

Here's my take:
These are two different things. Projects are very useful for development-time. Right now the project is really lightweight - it just adds folders to the path, and clearly labels tests.

As we get closer to release, we can add support for automatically generating MLTBX and a package. I'll bring in a buildplan at that point.

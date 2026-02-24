# #46: Fix json support for arbitrary keys

**State:** closed  
**Created:** 2026-02-02  
**Closed:** 2026-02-03  

## Description

Since our initial development of json support was based on jsondecode, it inherited jsondecode's name mangling. One of the key benefits of our JSONData type is that it handles arbitrary keys, e.g. with j.("0x-key") syntax. Fix this.

## Comments

### Comment by michellehirsch on 2026-02-03

Closed by pull request #51 

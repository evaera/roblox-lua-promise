---
title: Installation
---

# Installation

## Quick Install

To use promises quickly in your game can be achieved by using `HttpService` and `loadstring`. *(It's important you have both these enabled for it to properly work for this install method).*
```lua
-- // Put this code at the top of the file
local Http = game:GetService("HttpService")
local url = "https://raw.githubusercontent.com/evaera/roblox-lua-promise/master/lib/init.lua"
local Promise = loadstring(Http:GetAsync(url))()
```
## Copying Promise File \**recommended*

This method of installation will be copying the actual promise script and putting it into a module script in your game.

1. Go to the file on the github repo under [/roblox-lua-promise/lib/init.lua]("https://github.com/evaera/roblox-lua-promise/blob/master/lib/init.lua") and copy the contents of the file.

2. Go into roblox studio and create a `ModuleScript`, paste the contents you previously copied into this file.

3. Simply call the `require` function on the `ModuleScript` you created in a new `script`.

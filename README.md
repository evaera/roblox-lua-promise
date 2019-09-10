# Roblox Lua Promise
An implementation of `Promise` similar to Promise/A+.

## Motivation

The way Roblox models asynchronous operations by default is by yielding (stopping) the thread and then resuming it when the future value is available. This model is not ideal because:

- Functions you call can yield without warning, or only yield sometimes, leading to unpredictable and surprising results. Accidentally yielding the thread is the source of a large class of bugs and race conditions that Roblox developers run into.
- It is difficult to deal with running multiple asynchronous operations concurrently and then retrieve all of their values at the end without extraneous machinery.
- When an asynchronous operation fails or an error is encountered, Lua functions usually either raise an error or return a success value followed by the actual value. Both of these methods lead to repeating the same tired patterns many times over for checking if the operation was successful.
- Yielding lacks easy access to introspection and the ability to cancel an operation if the value is no longer needed.

### Goals

This Promise implementation attempts to satisfy these traits:

* An object that represents a unit of asynchronous work
* Composability
* Predictable timing

## Example
This Promise implementation finished synchronously. In order to wrap an existing async API, you should use `Promise.spawn` in order to prevent your calling thread from accidentally yielding.

```lua
local HttpService = game:GetService("HttpService")

-- A light wrapper around HttpService
-- Ideally, you do this once per project per async method that you use.
local function httpGet(url)
	return Promise.new(function(resolve, reject)
		Promise.spawn(function()
			local ok, result = pcall(HttpService.GetAsync, HttpService, url)

			if ok then
				resolve(result)
			else
				reject(result)
			end
		end)
	end)
end

-- Usage
httpGet("https://google.com")
	:andThen(function(body)
		print("Here's the Google homepage:", body)
	end)
	:catch(function(err)
		warn("We failed to get the Google homepage!", err)
	end)
```

# Roblox Lua Promise
An implementation of `Promise` similar to Promise/A+.

## Motivation
I've found that being able to yield anywhere causes lots of bugs. In [Rodux](https://github.com/Roblox/Rodux), I explicitly made it impossible to yield in a change handler because of the sheer number of bugs that occured when callbacks randomly yielded.

As such, I think that Roblox needs an object-based async primitive. It's not important to me whether these are Promises, Observables, Task objects, or Futures.

The important traits are:

* An object that represents a unit of asynchronous work
* Composability
* Predictable timing

This Promise implementation attempts to satisfy those traits.

## API

### Static Functions
* `Promise.new((resolve, reject) -> nil) -> Promise`
	* Construct a new Promise that will be resolved or rejected with the given callbacks.
* `Promise.resolve(value) -> Promise`
	* Creates an immediately resolved Promise with the given value.
* `Promise.reject(value) -> Promise`
	* Creates an immediately rejected Promise with the given value.
* `Promise.is(object) -> bool`
	* Returns whether the given object is a Promise.
* `Promise.all(array) -> array`
	* Accepts an array of promises and returns a new promise that:
		* is resolved after all input promises resolve.
		* is rejected if ANY input promises reject.
	* Note: Only the first return value from each promise will be present in the resulting array.

### Instance Methods
* `Promise:andThen(successHandler, [failureHandler]) -> Promise`
	* Chains onto an existing Promise and returns a new Promise.
	* Equivalent to the Promise/A+ `then` method.
* `Promise:catch(failureHandler) -> Promise`
	* Shorthand for `Promise:andThen(nil, failureHandler)`.
* `Promise:await() -> ok, value`
	* Yields the current thread until the given Promise completes. Returns `ok` as a bool, followed by the value that the promise returned.

## Example
This Promise implementation finished synchronously. In order to wrap an existing async API, you should use `spawn` or `delay` in order to prevent your calling thread from accidentally yielding.

```lua
local HttpService = game:GetService("HttpService")

-- A light wrapper around HttpService
-- Ideally, you do this once per project per async method that you use.
local function httpGet(url)
	return Promise.new(function(resolve, reject)
		-- Spawn to prevent yielding, since GetAsync yields.
		spawn(function()
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

## Future Additions
* `Promise.wrapAsync`
	* Intended to wrap an existing Roblox API that yields, exposing a new one that returns a Promise.

## License
This project is available under the CC0 license. See [LICENSE](LICENSE) for details.
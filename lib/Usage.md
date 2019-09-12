---
title: Usage Guide
---

# Usage Guide

## Creating a Promise

There are a few ways to create a Promise. If you need to call functions that yield, you should use <ApiLink to="Promise.async" />:

```lua
local myFunction()
	return Promise.async(function(resolve, reject, onCancel)
		wait(1)
		resolve("Hello world!")
	end)
end

myFunction():andThen(print)
```

If you don't need to yield, you can use regular <ApiLink to="Promise.new" />:

```lua
local myFunction()
	return Promise.new(function(resolve, reject, onCancel)
		local connection

		someEvent:Connect(function(...)
			connection:Disconnect()
			resolve(...)
		end)

		onCancel(function()
			connection:Disconnect()
		end)
	end)
end

myFunction():andThen(print)
```

If you just want to wrap a single value in a Promise, you can use <ApiLink to="Promise.resolve" />:

```lua
local myFunction()
	return Promise.resolve("Hello world!")
end

myFunction():andThen(print)
```

If you already have a function that yields, and you want it to return a Promise instead, you can use <ApiLink to="Promise.promisify" />:

```lua
local function myYieldingFunction(waitTime, text)
	wait(waitTime)
	return text
end

local myFunction = Promise.promisify(myYieldingFunction)
myFunction(1.2, "Hello world!"):andThen(print):catch(function()
	warn("Oh no... goodbye world.")
end)
```

## Rejection and errors

You must observe the result of a Promise, either with `catch` or `finally`, otherwise an unhandled Promise rejection warning will be printed to the console.

If an error occurs while executing the Promise body, the Promise will be rejected automatically with the error text.

## Chaining

One of the best parts about Promises is that they are chainable.

Every time you call `andThen`, `catch`, or `finally`, it returns a *new* Promise, which resolves with whatever value you return from the success or failure handlers, respectively.

```lua
somePromise:andThen(function(number)
  return number + 1
end):andThen(print)
```

You can also return a Promise from your handler, and it will be chained onto:

```lua
Promise.async(function(resolve)
	wait(1)
	resolve(1)
end):andThen(function(x)
	return Promise.async(function(resolve)
		wait(1)
		resolve(x + 1)
	end)
end):andThen(print) --> 2
```

You can also call `:andThen` multiple times on a single Promise to have multiple branches off of a single Promise.

Resolving a Promise with a Promise will be chained as well:
```lua
Promise.async(function(resolve)
	wait(1)
	resolve(Promise.async(function(resolve)
		wait(1)
		resolve(1)
	end))
end):andThen(print) --> 1
```

However, any value that is returned from the Promise executor (the function you pass into `Promise.async`) is discarded. Do not return values from the function executor.

## Yielding in Promise executor

If you need to yield in the Promise executor, you must wrap your yielding code in a new thread to prevent your calling thread from yielding. The easiest way to do this is to use the <ApiLink to="Promise.async" /> constructor instead of <ApiLink to="Promise.new" />:

```lua
Promise.async(function(resolve)
  wait(1)
  resolve()
end)
```

`Promise.async` uses `Promise.new` internally, except it wraps the Promise executor with <ApiLink to="Promise.spawn" />.

`Promise.async` is sugar for:

```lua
Promise.new(function(resolve, reject, onCancel)
  Promise.spawn(function()
    -- ...
  end)
end)
```

### Promise.spawn
`Promise.spawn` attaches a one-time listener to the next `RunService.Heartbeat` event to fire off the rest of your Promise executor, ensuring it always waits at least one step.

The reason `Promise.spawn` includes this wait time is to ensure that your Promises have consistent timing. Otherwise, your Promise would run synchronously up to the first yield, and asynchronously afterwards. This can often lead to undesirable results. Additionally, Promises that never yield can resolve completely synchronously, and this can lead to predictable, but often unexpected timing issues. Thus, we use `Promise.spawn` so there is always a guaranteed yield before execution.

::: danger Don't use regular spawn
`spawn` might seem like a tempting alternative to `Promise.spawn` here, but you should **never** use it!

`spawn` (and `wait`, for that matter) do not resume threads at a consistent interval. If Roblox has resumed too many threads in a single Lua step, it will begin throttling and your thread that was meant to be resumed on the next frame could actually be resumed several seconds later. The unexpected delay caused by this behavior will cause cascading timing issues in your game and could lead to some potentially ugly bugs.
:::

### When to use `Promise.new`
In some cases, it is desirable for a Promise to execute completely synchronously. If you don't need to yield in your Promise executor, and you are aware of the timing implications of a completely synchronous Promise, then it is acceptable to use `Promise.new`.

For example, an example of a situation where it might be appropriate to use Promise.new is when resolving after an event is fired.

However, in some situations, <ApiLink to="Promise.resolve" /> may be more appropriate.

## Cancellation
Promises are cancellable, but abort semantics are optional. This means that you can cancel any Promise and it will never resolve or reject, even if the function is still working in the background. But you can optionally add a cancellation hook which allows you to abort ongoing operations with the third `onCancel` parameter given to your Promise executor.

If a Promise is already cancelled at the time of calling its `onCancel` hook, the hook will be called immediately.

::: tip
It's good practice to add an `onCancel` hook to all of your asynchronous Promises unless it's impossible to abort an operation safely.

Even if you don't plan to directly cancel a particular Promise, chaining with other Promises can cause it to become automatically cancelled if no one cares about the value anymore.
:::

If you attach a `:andThen` or `:catch` handler to a Promise after it's been cancelled, the chained Promise will be instantly rejected with the error "Promise is cancelled". This also applies to Promises that you pass to `resolve`. However, `finally` does not have this constraint.

::: warning
If you cancel a Promise immediately after creating it without yielding in between, the fate of the Promise is dependent on if the Promise handler yields or not. If the Promise handler resolves without yielding, then the Promise will already be settled by the time you are able to cancel it, thus any consumers of the Promise will have already been called and cancellation is not possible.

If the Promise does yield, then cancelling it immediately *will* prevent its resolution. This is always the case when using `Promise.async`/`Promise.spawn`.
:::

Attempting to cancel an already-settled Promise is ignored.

### Cancellation propagation
When you cancel a Promise, the cancellation propagates up and down the Promise chain. Promises keep a list of other Promises that consume them (e.g. `andThen`).

When the upwards propagation encounters a Promise that no longer has any consumers, that Promise is cancelled as well. Note that it's impossible to cancel an already-settled Promise, so upwards propagation will stop when it reaches a settled Promise.

If a cancelled Promise has any consumers itself, those Promises are also cancelled.

Resolving a Promise with a Promise will cause the resolving Promise to become a consumer of the chained Promise, so if the chained Promise becomes cancelled then the resolving Promise will also become cancelled.

If you call `resolve` with a Promise within a Promise which is already cancelled, the passed Promise will be cancelled if it has no other consumers as an optimization.
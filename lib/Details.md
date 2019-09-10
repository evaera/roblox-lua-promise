---
title: Implementation Details
---

# Implementation Details

## Chaining

One of the best parts about Promises is that they are chainable.

Every time you call `andThen` or `catch`, it returns a *new* Promise, which resolves with whatever value you return from the success or failure handlers, respectively.

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

`Promise.spawn` uses a BindableEvent internally to launch your Promise body on a fresh thread after waiting for the next `RunService.Heartbeat` event.  The reason `Promise.spawn` includes this wait time is to ensure that your Promises have consistent timing. Otherwise, your Promise would run synchronously up to the first yield, and asynchronously afterwards. This can often lead to undesirable results. Additionally, Promises that never yield can resolve completely synchronously, and this can lead to unpredictable timing issues. Thus, we use `Promise.spawn` so there is always a guaranteed yield before execution.

::: danger Don't use regular spawn
`spawn` might seem like a tempting alternative to `Promise.spawn` here, but you should **never** use it!

`spawn` (and `wait`, for that matter) do not resume threads at a consistent interval. If Roblox has resumed too many threads in a single Lua step, it will begin throttling and your thread that was meant to be resumed on the next frame could actually be resumed several seconds later. The unexpected delay caused by this behavior will cause cascading timing issues in your game and could lead to some potentially ugly bugs.
:::

::: warning coroutine.wrap would work, but...
`coroutine.wrap` is another possible stand-in for creating a BindableEvent and firing it off, but in the case of an error, the stack trace is reset when the coroutine executes. This can make troubleshooting extremely difficult because you don't know where to look in your code base for the source of the error. Creating a BindableEvent is relatively cheap, so you shouldn't need to worry about this causing performance problems in your game.
:::

### When to use `Promise.new`
In some cases, it is desirable for a Promise to execute completely synchronously. If you don't need to yield in your Promise executor, and you are aware of the timing implications of a completely synchronous Promise, then it is acceptable to use `Promise.new`.

However, in these situations, <ApiLink to="Promise.resolve" /> may be more appropriate.

## Cancellation details
If a Promise is already cancelled at the time of calling its onCancel hook, the hook will be called immediately.

If you attach a `:andThen` or `:catch` handler to a Promise after it's been cancelled, the chained Promise will be instantly rejected with the error "Promise is cancelled".

If you cancel a Promise immediately after creating it in the same Lua cycle, the fate of the Promise is dependent on if the Promise handler yields or not. If the Promise handler resolves without yielding, then the Promise will already be settled by the time you are able to cancel it, thus any consumers of the Promise will have already been called.

If the Promise does yield, then cancelling it immediately *will* prevent its resolution. This is always the case when using `Promise.spawn`.

Attempting to cancel an already-settled Promise is ignored.

### Cancellation propagation
When you cancel a Promise, the cancellation propagates up the Promise chain. Promises keep track of the number of consumers that they have, and when the upwards propagation encounters a Promise that no longer has any consumers, that Promise is cancelled as well.

It's important to note that cancellation does **not** propagate downstream, so if you get a handle to a Promise earlier in the chain and cancel it directly, Promises that are consuming the cancelled Promise will remain in an unsettled state forever.
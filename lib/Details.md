---
title: Implementation Details
---

# Implementation Details

## Yielding in Promise executor

If you need to yield in the Promise executor, you must wrap your yielding code in a new thread to prevent your calling thread from yielding. The easiest way to do this is to wrap your code with the built-in `Promise.spawn`:

```lua
Promise.new(function(resolve)
  Promise.spawn(function()
    wait(1)
    resolve()
  end)
end)
```

`Promise.spawn` uses a BindableEvent internally to launch your Promise body on a fresh thread after waiting for the next `RunService.Heartbeat` event. 

The reason `Promise.spawn` includes this wait time is to ensure that your Promises have consistent timing. Otherwise, your Promise would run synchronously up to the first yield, and asynchronously afterwards. This can often lead to undesirable results. Additionally, Promises that never yield can resolve completely synchronously, and this can lead to unpredictable timing issues. Thus, we use `Promise.spawn` so there is always a guaranteed yield before execution.

::: danger Don't use regular spawn
`spawn` might seem like a tempting alternative to `Promise.spawn` here, but you should **never** use it!

`spawn` (and `wait`, for that matter) do not resume threads at a consistent interval. If Roblox has resumed too many threads in a single Lua step, it will begin throttling and your thread that was meant to be resumed on the next frame could actually be resumed several seconds later. The unexpected delay caused by this behavior will cause cascading timing issues in your game and could lead to some potentially ugly bugs.
:::

::: warning coroutine.wrap would work, but...
`coroutine.wrap` is another possible stand-in for creating a BindableEvent and firing it off, but in the case of an error, the stack trace is reset when the coroutine executes. This can make troubleshooting extremely difficult because you don't know where to look in your code base for the source of the error. Creating a BindableEvent is relatively cheap, so you shouldn't need to worry about this causing performance problems in your game.
:::

## Cancellation details
If a Promise is already cancelled at the time of calling its onCancel hook, the hook will be called immediately.

If you attach a `:andThen` or `:catch` handler to a Promise after it's been cancelled, the chained Promise will be instantly rejected with the error "Promise is cancelled".

If you cancel a Promise immediately after creating it in the same Lua cycle, the fate of the Promise is dependent on if the Promise handler yields or not. If the Promise handler resolves without yielding, then the Promise will already be settled by the time you are able to cancel it, thus any consumers of the Promise will have already been called.

If the Promise does yield, then cancelling it immediately *will* prevent its resolution. This is always the case when using `Promise.spawn`.

Attempting to cancel an already-settled Promise is ignored.

### Cancellation propagation
When you cancel a Promise, the cancellation propagates up the Promise chain. Promises keep track of the number of consumers that they have, and when the upwards propagation encounters a Promise that no longer has any consumers, that Promise is cancelled as well.

It's important to note that cancellation does **not** propagate downstream, so if you get a handle to a Promise earlier in the chain and cancel it directly, Promises that are consuming the cancelled Promise will remain in an unsettled state forever.
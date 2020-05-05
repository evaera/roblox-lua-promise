# Next
- Runtime errors are now represented by objects. You must call tostring on rejection values before assuming they are strings (this was always good practice, but is required now).
- Errors now have much better stack traces due to using xpcall internally instead of pcall.
- Stack traces now be more direct and not include as many internal calls within the Promise library.
- Chained promises from resolve() or returning from andThen now have improved rejection messages for debugging.
- Yielding is now allowed in Promise.new and andThen executors.
- Improve test coverage for asynchronous and time-driven functions

# 2.5.1

- Fix issue with rejecting with non-string not propagating correctly.

# 2.5.0

- Add Promise.tap
- Fix bug with C functions not working when passed to andThen
- Fix issue with Promise.race/all always cancelling instead of only cancelling if the Promise has no other consumers
- Make error checking more robust across many methods.
- Promise.Status members are now strings instead of symbols, and indexing a non-existent value will error.
- Improve stack traces
- Promise.promisify will now turn errors into rejections even if they occur after a yield.
- Add Promise.try
- Add `done`, `doneCall`, `doneReturn`
- Add `andThenReturn`, `finallyReturn`
- Add `Promise.delay`, `promise:timeout`
- Add `Promise.some`, `Promise.any`
- Add `Promise.allSettled`
- `Promise.all` and `Promise.race` are now cancellable.

# 2.4.0

- `Promise.is` now only checks if the object is "andThennable" (has an `andThen` method).

# 2.3.1

- Make unhandled rejection warning trigger on next Heartbeat

# 2.3.0

- Remove `Promise.spawn` from the public API.
- `Promise.async` still inherits the behavior from `Promise.spawn`.
- `Promise.async` now wraps the callback in `pcall` and rejects if an error occurred.
- `Promise.new` has now has an explicit error message when attempting to yield inside of it.

# 2.2.0 

- `Promise.promisify` now uses `coroutine.wrap` instead of `Promise.spawn`

# 2.1.0

- Add `finallyCall`, `andThenCall`
- Add `awaitValue`

# 2.0.0

- Add Promise.race
- Add Promise.async
- Add Promise.spawn
- Add Promise.promisify
- `finally` now silences the unhandled rejection warning
- `onCancel` now returns if the Promise was cancelled at call time.
- Cancellation now propagates downstream.
- Add `Promise:awaitStatus`
- Calling `resolve` with a Promise while the resolving Promise is cancelled instantly cancels the passed Promise as an optimization.
- `finally` now passes the Promise status as a parameter.
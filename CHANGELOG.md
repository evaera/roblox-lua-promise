# Next

- Add Promise.tap
- Fix bug with C functions not working when passed to andThen
- Fix issue with Promise.race/all always cancelling instead of only cancelling if the Promise has no other consumers
- Make error checking more robust across many methods.
- Promise.Status members are now strings instead of symbols, and indexing a non-existent value will error.

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
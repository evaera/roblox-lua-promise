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
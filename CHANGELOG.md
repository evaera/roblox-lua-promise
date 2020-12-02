# Changelog

## [3.1.0] - 2020-12-01

### Added
- Added `Promise.fold` (#47)

## [3.0.1] - 2020-08-24
### Fixed
- Make `Promise.is` work with promises from old versions of the library (#41)
- Make `Promise.delay` properly break out of the current loop (#40)
- Allow upvalues captured by queued callbacks to be garbage collected when the Promise resolves by deleting the queues when the Promise settles (#39)

## [3.0.0] - 2020-08-17
### Changed
- `Promise.delay` now uses `os.clock`
- Made `Promise.delay` behavior more consistent when creating new timers in the callback of a timer.

## [3.0.0-rc.3] - 2020-07-10
### Fixed
- Fixed a bug where queued `andThen` and `catch` callbacks did not begin on their own new threads.

## [3.0.0-rc.1] - 2020-06-02
### Changed
- Runtime errors are now represented by objects. You must call tostring on rejection values before assuming they are strings (this was always good practice, but is required now).
- Yielding is now allowed in `Promise.new`, `andThen`, and `Promise.try` executors.
- Errors now have much better stack traces due to using `xpcall` internally instead of `pcall`.
- Stack traces will now be more direct and not include as many internal calls within the Promise library.
- Chained promises from `resolve()` or returning from andThen now have improved rejection messages for debugging.
- `Promise.async` has been renamed to `Promise.defer` (`Promise.async` references same function for compatibility)
- Promises now have a `__tostring` metamethod, which returns `Promise(Resolved)` or whatever the current status is.
- `Promise:timeout()` now rejects with a `Promise.Error(Promise.Error.Kind.TimedOut)` object. (Formerly rejected with the string `"Timed out"`)
- Attaching a handler to a cancelled Promise now rejects with a `Promise.Error(Promise.Error.Kind.AlreadyCancelled)`. (Formerly rejected with the string `"Promise is cancelled"`)
- Let `Promise:expect()` throw rejection objects

### Added

- New Promise Error class is exposed at `Promise.Error`, which includes helpful static methods like `Promise.Error.is`.
- Added `Promise:now()` (#23)
- Added `Promise.each` (#21)
- Added `Promise.retry` (#16)
- Added `Promise.fromEvent` (#14)
- Improved test coverage for asynchronous and time-driven functions

### Fixed
- Changed `Promise.is` to be safe when dealing with tables that have an `__index` metamethod that creates an error.
- `Promise.delay` resolve value (time passed) is now more accurate (previously passed time based on when we started resuming threads instead of the current time. This is a very minor difference.)

## [2.5.1]

- Fix issue with rejecting with non-string not propagating correctly.

## [2.5.0]

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

## [2.4.0]

- `Promise.is` now only checks if the object is "andThennable" (has an `andThen` method).

## [2.3.1]

- Make unhandled rejection warning trigger on next Heartbeat

## [2.3.0]

- Remove `Promise.spawn` from the public API.
- `Promise.async` still inherits the behavior from `Promise.spawn`.
- `Promise.async` now wraps the callback in `pcall` and rejects if an error occurred.
- `Promise.new` has now has an explicit error message when attempting to yield inside of it.

## [2.2.0]

- `Promise.promisify` now uses `coroutine.wrap` instead of `Promise.spawn`

## [2.1.0]

- Add `finallyCall`, `andThenCall`
- Add `awaitValue`

## [2.0.0]

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

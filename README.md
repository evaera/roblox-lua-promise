<div align="center">
	<h1>Roblox Lua Promise</h1>
	<p>An implementation of <code>Promise</code> similar to Promise/A+.</p>
	<a href="https://eryn.io/roblox-lua-promise/"><strong>View docs</strong></a>
</div>
<!--moonwave-hide-before-this-line-->


## Why you should use Promises

The way Roblox models asynchronous operations by default is by yielding (stopping) the thread and then resuming it when the future value is available. This model is not ideal because:

- Functions you call can yield without warning, or only yield sometimes, leading to unpredictable and surprising results. Accidentally yielding the thread is the source of a large class of bugs and race conditions that Roblox developers run into.
- It is difficult to deal with running multiple asynchronous operations concurrently and then retrieve all of their values at the end without extraneous machinery.
- When an asynchronous operation fails or an error is encountered, Lua functions usually either raise an error or return a success value followed by the actual value. Both of these methods lead to repeating the same tired patterns many times over for checking if the operation was successful.
- Yielding lacks easy access to introspection and the ability to cancel an operation if the value is no longer needed.

This Promise implementation attempts to satisfy these traits:

* An object that represents a unit of asynchronous work
* Composability
* Predictable timing

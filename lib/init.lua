--[[
	An implementation of Promises similar to Promise/A+.
]]

local RunService = game:GetService("RunService")

--[[
	Packs a number of arguments into a table and returns its length.

	Used to cajole varargs without dropping sparse values.
]]
local function pack(...)
	local len = select("#", ...)

	return len, { ... }
end

--[[
	Returns first value (success), and packs all following values.
]]
local function packResult(...)
	local result = (...)

	return result, pack(select(2, ...))
end

--[[
	Calls a non-yielding function in a new coroutine.

	Handles errors if they happen.
]]
local function ppcall(callback, ...)
	local co = coroutine.create(callback)

	local ok, len, result = packResult(coroutine.resume(co, ...))

	if ok and coroutine.status(co) ~= "dead" then
		error("Yielding inside Promise.new is not allowed! Use Promise.async or create a new thread in the Promise executor!", 2)
	elseif not ok then
		result[1] = debug.traceback(result[1], 2)
	end

	return ok, len, result
end

--[[
	Creates a function that invokes a callback with correct error handling and
	resolution mechanisms.
]]
local function createAdvancer(callback, resolve, reject)
	return function(...)
		local ok, resultLength, result = ppcall(callback, ...)

		if ok then
			resolve(unpack(result, 1, resultLength))
		else
			reject(unpack(result, 1, resultLength))
		end
	end
end

local function isEmpty(t)
	return next(t) == nil
end

local function createSymbol(name)
	assert(type(name) == "string", "createSymbol requires `name` to be a string.")

	local symbol = newproxy(true)

	getmetatable(symbol).__tostring = function()
		return ("Symbol(%s)"):format(name)
	end

	return symbol
end

local Promise = {}
Promise.prototype = {}
Promise.__index = Promise.prototype

Promise.Status = {
	Started = createSymbol("Started"),
	Resolved = createSymbol("Resolved"),
	Rejected = createSymbol("Rejected"),
	Cancelled = createSymbol("Cancelled"),
}

--[[
	Constructs a new Promise with the given initializing callback.

	This is generally only called when directly wrapping a non-promise API into
	a promise-based version.

	The callback will receive 'resolve' and 'reject' methods, used to start
	invoking the promise chain.

	Second parameter, parent, is used internally for tracking the "parent" in a
	promise chain. External code shouldn't need to worry about this.
]]
function Promise.new(callback, parent)
	if parent ~= nil and not Promise.is(parent) then
		error("Argument #2 to Promise.new must be a promise or nil", 2)
	end

	local self = {
		-- Used to locate where a promise was created
		_source = debug.traceback(),

		_status = Promise.Status.Started,

		-- A table containing a list of all results, whether success or failure.
		-- Only valid if _status is set to something besides Started
		_values = nil,

		-- Lua doesn't like sparse arrays very much, so we explicitly store the
		-- length of _values to handle middle nils.
		_valuesLength = -1,

		-- Tracks if this Promise has no error observers..
		_unhandledRejection = true,

		-- Queues representing functions we should invoke when we update!
		_queuedResolve = {},
		_queuedReject = {},
		_queuedFinally = {},

		-- The function to run when/if this promise is cancelled.
		_cancellationHook = nil,

		-- The "parent" of this promise in a promise chain. Required for
		-- cancellation propagation.
		_parent = parent,

		_consumers = setmetatable({}, {
			__mode = "k";
		}),
	}

	if parent and parent._status == Promise.Status.Started then
		parent._consumers[self] = true
	end

	setmetatable(self, Promise)

	local function resolve(...)
		self:_resolve(...)
	end

	local function reject(...)
		self:_reject(...)
	end

	local function onCancel(cancellationHook)
		if cancellationHook then
			if self._status == Promise.Status.Cancelled then
				cancellationHook()
			else
				self._cancellationHook = cancellationHook
			end
		end

		return self._status == Promise.Status.Cancelled
	end

	local ok, _, result = ppcall(callback, resolve, reject, onCancel)
	local err = result[1]

	if not ok and self._status == Promise.Status.Started then
		reject(err)
	end

	return self
end

--[[
	Promise.new, except pcall on a new thread is automatic.
]]
function Promise.async(callback)
	local traceback = debug.traceback()
	return Promise.new(function(resolve, reject, onCancel)
		local connection
		connection = RunService.Heartbeat:Connect(function()
			connection:Disconnect()
			local ok, err = pcall(callback, resolve, reject, onCancel)

			if not ok then
				reject(err .. "\n" .. traceback)
			end
		end)
	end)
end

--[[
	Create a promise that represents the immediately resolved value.
]]
function Promise.resolve(value)
	return Promise.new(function(resolve)
		resolve(value)
	end)
end

--[[
	Create a promise that represents the immediately rejected value.
]]
function Promise.reject(value)
	return Promise.new(function(_, reject)
		reject(value)
	end)
end

--[[
	Returns a new promise that:
		* is resolved when all input promises resolve
		* is rejected if ANY input promises reject
]]
function Promise.all(promises)
	if type(promises) ~= "table" then
		error("Please pass a list of promises to Promise.all", 2)
	end

	-- We need to check that each value is a promise here so that we can produce
	-- a proper error rather than a rejected promise with our error.
	for i, promise in pairs(promises) do
		if not Promise.is(promise) then
			error(("Non-promise value passed into Promise.all at index %s"):format(tostring(i)), 2)
		end
	end

	-- If there are no values then return an already resolved promise.
	if #promises == 0 then
		return Promise.resolve({})
	end

	return Promise.new(function(resolve, reject)
		-- An array to contain our resolved values from the given promises.
		local resolvedValues = {}
		local newPromises = {}

		-- Keep a count of resolved promises because just checking the resolved
		-- values length wouldn't account for promises that resolve with nil.
		local resolvedCount = 0
		local finalized = false

		-- Called when a single value is resolved and resolves if all are done.
		local function resolveOne(i, ...)
			resolvedValues[i] = ...
			resolvedCount = resolvedCount + 1

			if resolvedCount == #promises then
				resolve(resolvedValues)
			end
		end

		-- We can assume the values inside `promises` are all promises since we
		-- checked above.
		for i = 1, #promises do
			if finalized then
				break
			end

			table.insert(
				newPromises,
				promises[i]:andThen(
					function(...)
						resolveOne(i, ...)
					end,
					function(...)
						for _, promise in ipairs(newPromises) do
							promise:cancel()
						end
						finalized = true

						reject(...)
					end
				)
			)
		end
	end)
end

--[[
	Races a set of Promises and returns the first one that resolves,
	cancelling the others.
]]
function Promise.race(promises)
	assert(type(promises) == "table", "Please pass a list of promises to Promise.race")

	for i, promise in pairs(promises) do
		assert(Promise.is(promise), ("Non-promise value passed into Promise.race at index %s"):format(tostring(i)))
	end

	return Promise.new(function(resolve, reject, onCancel)
		local newPromises = {}

		local function finalize(callback)
			return function (...)
				for _, promise in ipairs(newPromises) do
					promise:cancel()
				end

				return callback(...)
			end
		end

		if onCancel(finalize(reject)) then
			return
		end

		for _, promise in ipairs(promises) do
			table.insert(
				newPromises,
				promise:andThen(finalize(resolve), finalize(reject))
			)
		end
	end)
end

--[[
	Is the given object a Promise instance?
]]
function Promise.is(object)
	if type(object) ~= "table" then
		return false
	end

	return type(object.andThen) == "function"
end

--[[
	Converts a yielding function into a Promise-returning one.
]]
function Promise.promisify(callback)
	return function(...)
		local length, values = pack(...)
		return Promise.new(function(resolve)
			coroutine.wrap(function()
				resolve(callback(unpack(values, 1, length)))
			end)()
		end)
	end
end

function Promise.prototype:getStatus()
	return self._status
end

--[[
	Creates a new promise that receives the result of this promise.

	The given callbacks are invoked depending on that result.
]]
function Promise.prototype:andThen(successHandler, failureHandler)
	self._unhandledRejection = false

	-- Create a new promise to follow this part of the chain
	return Promise.new(function(resolve, reject)
		-- Our default callbacks just pass values onto the next promise.
		-- This lets success and failure cascade correctly!

		local successCallback = resolve
		if successHandler then
			successCallback = createAdvancer(successHandler, resolve, reject)
		end

		local failureCallback = reject
		if failureHandler then
			failureCallback = createAdvancer(failureHandler, resolve, reject)
		end

		if self._status == Promise.Status.Started then
			-- If we haven't resolved yet, put ourselves into the queue
			table.insert(self._queuedResolve, successCallback)
			table.insert(self._queuedReject, failureCallback)
		elseif self._status == Promise.Status.Resolved then
			-- This promise has already resolved! Trigger success immediately.
			successCallback(unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Rejected then
			-- This promise died a terrible death! Trigger failure immediately.
			failureCallback(unpack(self._values, 1, self._valuesLength))
		elseif self._status == Promise.Status.Cancelled then
			-- We don't want to call the success handler or the failure handler,
			-- we just reject this promise outright.
			reject("Promise is cancelled")
		end
	end, self)
end

--[[
	Used to catch any errors that may have occurred in the promise.
]]
function Promise.prototype:catch(failureCallback)
	return self:andThen(nil, failureCallback)
end

--[[
	Calls a callback on `andThen` with specific arguments.
]]
function Promise.prototype:andThenCall(callback, ...)
	local length, values = pack(...)
	return self:andThen(function()
		return callback(unpack(values, 1, length))
	end)
end

--[[
	Cancels the promise, disallowing it from rejecting or resolving, and calls
	the cancellation hook if provided.
]]
function Promise.prototype:cancel()
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Cancelled

	if self._cancellationHook then
		self._cancellationHook()
	end

	if self._parent then
		self._parent:_consumerCancelled(self)
	end

	for child in pairs(self._consumers) do
		child:cancel()
	end

	self:_finalize()
end

--[[
	Used to decrease the number of consumers by 1, and if there are no more,
	cancel this promise.
]]
function Promise.prototype:_consumerCancelled(consumer)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._consumers[consumer] = nil

	if next(self._consumers) == nil then
		self:cancel()
	end
end

--[[
	Used to set a handler for when the promise resolves, rejects, or is
	cancelled. Returns a new promise chained from this promise.
]]
function Promise.prototype:finally(finallyHandler)
	self._unhandledRejection = false

	-- Return a promise chained off of this promise
	return Promise.new(function(resolve, reject)
		local finallyCallback = resolve
		if finallyHandler then
			finallyCallback = createAdvancer(finallyHandler, resolve, reject)
		end

		if self._status == Promise.Status.Started then
			-- The promise is not settled, so queue this.
			table.insert(self._queuedFinally, finallyCallback)
		else
			-- The promise already settled or was cancelled, run the callback now.
			finallyCallback(self._status)
		end
	end, self)
end

--[[
	Calls a callback on `finally` with specific arguments.
]]
function Promise.prototype:finallyCall(callback, ...)
	local length, values = pack(...)
	return self:finally(function()
		return callback(unpack(values, 1, length))
	end)
end

--[[
	Yield until the promise is completed.

	This matches the execution model of normal Roblox functions.
]]
function Promise.prototype:awaitStatus()
	self._unhandledRejection = false

	if self._status == Promise.Status.Started then
		local bindable = Instance.new("BindableEvent")

		self:finally(function()
			bindable:Fire()
		end)

		bindable.Event:Wait()
		bindable:Destroy()
	end

	if self._status == Promise.Status.Resolved then
		return self._status, unpack(self._values, 1, self._valuesLength)
	elseif self._status == Promise.Status.Rejected then
		return self._status, unpack(self._values, 1, self._valuesLength)
	end

	return self._status
end

--[[
	Calls awaitStatus internally, returns (isResolved, values...)
]]
function Promise.prototype:await(...)
	local length, result = pack(self:awaitStatus(...))
	local status = table.remove(result, 1)

	return status == Promise.Status.Resolved, unpack(result, 1, length - 1)
end

--[[
	Calls await and only returns if the Promise resolves.
	Throws if the Promise rejects or gets cancelled.
]]
function Promise.prototype:awaitValue(...)
	local length, result = pack(self:awaitStatus(...))
	local status = table.remove(result, 1)

	assert(
		status == Promise.Status.Resolved,
		tostring(result[1] == nil and "" or result[1])
	)

	return unpack(result, 1, length - 1)
end

--[[
	Intended for use in tests.

	Similar to await(), but instead of yielding if the promise is unresolved,
	_unwrap will throw. This indicates an assumption that a promise has
	resolved.
]]
function Promise.prototype:_unwrap()
	if self._status == Promise.Status.Started then
		error("Promise has not resolved or rejected.", 2)
	end

	local success = self._status == Promise.Status.Resolved

	return success, unpack(self._values, 1, self._valuesLength)
end

function Promise.prototype:_resolve(...)
	if self._status ~= Promise.Status.Started then
		if Promise.is((...)) then
			(...):_consumerCancelled(self)
		end
		return
	end

	-- If the resolved value was a Promise, we chain onto it!
	if Promise.is((...)) then
		-- Without this warning, arguments sometimes mysteriously disappear
		if select("#", ...) > 1 then
			local message = (
				"When returning a Promise from andThen, extra arguments are " ..
				"discarded! See:\n\n%s"
			):format(
				self._source
			)
			warn(message)
		end

		local promise = (...):andThen(
			function(...)
				self:_resolve(...)
			end,
			function(...)
				self:_reject(...)
			end
		)

		if promise._status == Promise.Status.Cancelled then
			self:cancel()
		elseif promise._status == Promise.Status.Started then
			-- Adopt ourselves into promise for cancellation propagation.
			self._parent = promise
			promise._consumers[self] = true
		end

		return
	end

	self._status = Promise.Status.Resolved
	self._valuesLength, self._values = pack(...)

	-- We assume that these callbacks will not throw errors.
	for _, callback in ipairs(self._queuedResolve) do
		callback(...)
	end

	self:_finalize()
end

function Promise.prototype:_reject(...)
	if self._status ~= Promise.Status.Started then
		return
	end

	self._status = Promise.Status.Rejected
	self._valuesLength, self._values = pack(...)

	-- If there are any rejection handlers, call those!
	if not isEmpty(self._queuedReject) then
		-- We assume that these callbacks will not throw errors.
		for _, callback in ipairs(self._queuedReject) do
			callback(...)
		end
	else
		-- At this point, no one was able to observe the error.
		-- An error handler might still be attached if the error occurred
		-- synchronously. We'll wait one tick, and if there are still no
		-- observers, then we should put a message in the console.

		local err = tostring((...))

		coroutine.wrap(function()
			RunService.Heartbeat:Wait()

			-- Someone observed the error, hooray!
			if not self._unhandledRejection then
				return
			end

			-- Build a reasonable message
			local message = ("Unhandled promise rejection:\n\n%s\n\n%s"):format(
				err,
				self._source
			)
			warn(message)
		end)()
	end

	self:_finalize()
end

--[[
	Calls any :finally handlers. We need this to be a separate method and
	queue because we must call all of the finally callbacks upon a success,
	failure, *and* cancellation.
]]
function Promise.prototype:_finalize()
	for _, callback in ipairs(self._queuedFinally) do
		-- Purposefully not passing values to callbacks here, as it could be the
		-- resolved values, or rejected errors. If the developer needs the values,
		-- they should use :andThen or :catch explicitly.
		callback(self._status)
	end

	-- Allow family to be buried
	if not Promise.TEST then
		self._parent = nil
		self._consumers = nil
	end
end

return Promise
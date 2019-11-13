return function()
	local Promise = require(script.Parent)
	Promise.TEST = true

	local function pack(...)
		local len = select("#", ...)

		return len, { ... }
	end

	describe("Promise.Status", function()
		it("should error if indexing nil value", function()
			expect(function()
				local _ = Promise.Status.wrong
			end).to.throw()
		end)
	end)

	describe("Promise.new", function()
		it("should instantiate with a callback", function()
			local promise = Promise.new(function() end)

			expect(promise).to.be.ok()
		end)

		it("should invoke the given callback with resolve and reject", function()
			local callCount = 0
			local resolveArg
			local rejectArg

			local promise = Promise.new(function(resolve, reject)
				callCount = callCount + 1
				resolveArg = resolve
				rejectArg = reject
			end)

			expect(promise).to.be.ok()

			expect(callCount).to.equal(1)
			expect(resolveArg).to.be.a("function")
			expect(rejectArg).to.be.a("function")
			expect(promise:getStatus()).to.equal(Promise.Status.Started)
		end)

		it("should resolve promises on resolve()", function()
			local callCount = 0

			local promise = Promise.new(function(resolve)
				callCount = callCount + 1
				resolve()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should reject promises on reject()", function()
			local callCount = 0

			local promise = Promise.new(function(resolve, reject)
				callCount = callCount + 1
				reject()
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
		end)

		it("should reject on error in callback", function()
			local callCount = 0

			local promise = Promise.new(function()
				callCount = callCount + 1
				error("hahah")
			end)

			expect(promise).to.be.ok()
			expect(callCount).to.equal(1)
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]:find("hahah")).to.be.ok()

			-- Loosely check for the pieces of the stack trace we expect
			expect(promise._values[1]:find("init.spec")).to.be.ok()
			expect(promise._values[1]:find("new")).to.be.ok()
		end)
	end)

	describe("Promise.resolve", function()
		it("should immediately resolve with a value", function()
			local promise = Promise.resolve(5, 6)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)
			expect(promise._values[2]).to.equal(6)
		end)

		it("should chain onto passed promises", function()
			local promise = Promise.resolve(Promise.new(function(_, reject)
				reject(7)
			end))

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(7)
		end)
	end)

	describe("Promise.reject", function()
		it("should immediately reject with a value", function()
			local promise = Promise.reject(6, 7)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(6)
			expect(promise._values[2]).to.equal(7)
		end)

		it("should pass a promise as-is as an error", function()
			local innerPromise = Promise.new(function(resolve)
				resolve(6)
			end)

			local promise = Promise.reject(innerPromise)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(innerPromise)
		end)
	end)

	describe("Promise:andThen", function()
		it("should chain onto resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.resolve(5)

			local chained = promise:andThen(
				function(...)
					argsLength, args = pack(...)
					callCount = callCount + 1
				end,
				function()
					badCallCount = badCallCount + 1
				end
			)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should chain onto rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local promise = Promise.reject(5)

			local chained = promise:andThen(
				function(...)
					badCallCount = badCallCount + 1
				end,
				function(...)
					argsLength, args = pack(...)
					callCount = callCount + 1
				end
			)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(5)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(5)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should chain onto asynchronously resolved promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(resolve)
				startResolution = resolve
			end)

			local chained = promise:andThen(
				function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end,
				function()
					badCallCount = badCallCount + 1
				end
			)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should chain onto asynchronously rejected promises", function()
			local args
			local argsLength
			local callCount = 0
			local badCallCount = 0

			local startResolution
			local promise = Promise.new(function(_, reject)
				startResolution = reject
			end)

			local chained = promise:andThen(
				function()
					badCallCount = badCallCount + 1
				end,
				function(...)
					args = {...}
					argsLength = select("#", ...)
					callCount = callCount + 1
				end
			)

			expect(callCount).to.equal(0)
			expect(badCallCount).to.equal(0)

			startResolution(6)

			expect(badCallCount).to.equal(0)

			expect(callCount).to.equal(1)
			expect(argsLength).to.equal(1)
			expect(args[1]).to.equal(6)

			expect(promise).to.be.ok()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]).to.equal(6)

			expect(chained).to.be.ok()
			expect(chained).never.to.equal(promise)
			expect(chained:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#chained._values).to.equal(0)
		end)

		it("should propagate errors through multiple levels", function()
			local x, y, z
			Promise.new(function(resolve, reject)
				reject(1, 2, 3)
			end)
			:andThen(function() end)
			:catch(function(a, b, c)
				x, y, z = a, b, c
			end)

			expect(x).to.equal(1)
			expect(y).to.equal(2)
			expect(z).to.equal(3)
		end)
	end)

	describe("Promise:cancel", function()
		it("should mark promises as cancelled and not resolve or reject them", function()
			local callCount = 0
			local finallyCallCount = 0
			local promise = Promise.new(function() end):andThen(function()
				callCount = callCount + 1
			end):finally(function()
				finallyCallCount = finallyCallCount + 1
			end)

			promise:cancel()
			promise:cancel() -- Twice to check call counts

			expect(callCount).to.equal(0)
			expect(finallyCallCount).to.equal(1)
			expect(promise:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should call the cancellation hook once", function()
			local callCount = 0

			local promise = Promise.new(function(resolve, reject, onCancel)
				onCancel(function()
					callCount = callCount + 1
				end)
			end)

			promise:cancel()
			promise:cancel() -- Twice to check call count

			expect(callCount).to.equal(1)
		end)

		it("should propagate cancellations", function()
			local promise = Promise.new(function() end)

			local consumer1 = promise:andThen()
			local consumer2 = promise:andThen()

			expect(promise:getStatus()).to.equal(Promise.Status.Started)
			expect(consumer1:getStatus()).to.equal(Promise.Status.Started)
			expect(consumer2:getStatus()).to.equal(Promise.Status.Started)

			consumer1:cancel()

			expect(promise:getStatus()).to.equal(Promise.Status.Started)
			expect(consumer1:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer2:getStatus()).to.equal(Promise.Status.Started)

			consumer2:cancel()

			expect(promise:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer1:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(consumer2:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should affect downstream promises", function()
			local promise = Promise.new(function() end)
			local consumer = promise:andThen()

			promise:cancel()

			expect(consumer:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should track consumers", function()
			local pending = Promise.new(function() end)
			local p0 = Promise.resolve()
			local p1 = p0:finally(function() return pending end)
			local p2 = Promise.new(function(resolve)
				resolve(p1)
			end)
			local p3 = p2:andThen(function() end)

			expect(p1._parent).to.never.equal(p0)
			expect(p2._parent).to.never.equal(p1)
			expect(p2._consumers[p3]).to.be.ok()
			expect(p3._parent).to.equal(p2)
		end)

		it("should cancel resolved pending promises", function()
			local p1 = Promise.new(function() end)

			local p2 = Promise.new(function(resolve)
				resolve(p1)
			end):finally(function() end)

			p2:cancel()

			expect(p1._status).to.equal(Promise.Status.Cancelled)
			expect(p2._status).to.equal(Promise.Status.Cancelled)
		end)
	end)

	describe("Promise:finally", function()
		it("should be called upon resolve, reject, or cancel", function()
			local callCount = 0

			local function finally()
				callCount = callCount + 1
			end

			-- Resolved promise
			Promise.new(function(resolve, reject)
				resolve()
			end):finally(finally)

			-- Chained promise
			Promise.resolve():andThen(function()

			end):finally(finally):finally(finally)

			-- Rejected promise
			Promise.reject():finally(finally)

			local cancelledPromise = Promise.new(function() end):finally(finally)
			cancelledPromise:cancel()

			expect(callCount).to.equal(5)
		end)

		it("should be a child of the parent Promise", function()
			local p1 = Promise.new(function() end)
			local p2 = p1:finally(function() end)

			expect(p2._parent).to.equal(p1)
			expect(p1._consumers[p2]).to.equal(true)
		end)

		it("should forward return values", function()
			local value

			Promise.resolve():finally(function()
				return 1
			end):andThen(function(v)
				value = v
			end)

			expect(value).to.equal(1)
		end)
	end)

	describe("Promise.all", function()
		it("should error if given something other than a table", function()
			expect(function()
				Promise.all(1)
			end).to.throw()
		end)

		it("should resolve instantly with an empty table if given no promises", function()
			local promise = Promise.all({})
			local success, value = promise:_unwrap()

			expect(success).to.equal(true)
			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(value).to.be.a("table")
			expect(next(value)).to.equal(nil)
		end)

		it("should error if given non-promise values", function()
			expect(function()
				Promise.all({{}, {}, {}})
			end).to.throw()
		end)

		it("should wait for all promises to be resolved and return their values", function()
			local resolveFunctions = {}

			local testValuesLength, testValues = pack(1, "A string", nil, false)

			local promises = {}

			for i = 1, testValuesLength do
				promises[i] = Promise.new(function(resolve)
					resolveFunctions[i] = {resolve, testValues[i]}
				end)
			end

			local combinedPromise = Promise.all(promises)

			for _, resolve in ipairs(resolveFunctions) do
				expect(combinedPromise:getStatus()).to.equal(Promise.Status.Started)
				resolve[1](resolve[2])
			end

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, resolved = unpack(result, 1, resultLength)

			expect(resultLength).to.equal(2)
			expect(success).to.equal(true)
			expect(resolved).to.be.a("table")
			expect(#resolved).to.equal(#promises)

			for i = 1, testValuesLength do
				expect(resolved[i]).to.equal(testValues[i])
			end
		end)

		it("should reject if any individual promise rejected", function()
			local rejectA
			local resolveB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(resolve)
				resolveB = resolve
			end)

			local combinedPromise = Promise.all({a, b})

			expect(combinedPromise:getStatus()).to.equal(Promise.Status.Started)

			rejectA("baz", "qux")
			resolveB("foo", "bar")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("baz")
			expect(second).to.equal("qux")
			expect(b:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should not resolve if resolved after rejecting", function()
			local rejectA
			local resolveB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(resolve)
				resolveB = resolve
			end)

			local combinedPromise = Promise.all({a, b})

			expect(combinedPromise:getStatus()).to.equal(Promise.Status.Started)

			rejectA("baz", "qux")
			resolveB("foo", "bar")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("baz")
			expect(second).to.equal("qux")
		end)

		it("should only reject once", function()
			local rejectA
			local rejectB

			local a = Promise.new(function(_, reject)
				rejectA = reject
			end)

			local b = Promise.new(function(_, reject)
				rejectB = reject
			end)

			local combinedPromise = Promise.all({a, b})

			expect(combinedPromise:getStatus()).to.equal(Promise.Status.Started)

			rejectA("foo", "bar")

			expect(combinedPromise:getStatus()).to.equal(Promise.Status.Rejected)

			rejectB("baz", "qux")

			local resultLength, result = pack(combinedPromise:_unwrap())
			local success, first, second = unpack(result, 1, resultLength)

			expect(resultLength).to.equal(3)
			expect(success).to.equal(false)
			expect(first).to.equal("foo")
			expect(second).to.equal("bar")
		end)

		it("should error if a non-array table is passed in", function()
			local ok, err = pcall(function()
				Promise.all(Promise.new(function() end))
			end)

			expect(ok).to.be.ok()
			expect(err:find("Non%-promise")).to.be.ok()
		end)

		it("should cancel pending promises if one rejects", function()
			local p = Promise.new(function() end)
			expect(Promise.all({
				Promise.resolve(),
				Promise.reject(),
				p
			}):getStatus()).to.equal(Promise.Status.Rejected)
			expect(p:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:andThen(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.all(promises):cancel()

			expect(promises[1]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:getStatus()).to.equal(Promise.Status.Started)
		end)
	end)

	describe("Promise.race", function()
		it("should resolve with the first settled value", function()
			local promise = Promise.race({
				Promise.resolve(1),
				Promise.resolve(2)
			}):andThen(function(value)
				expect(value).to.equal(1)
			end)

			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should cancel other promises", function()
			local promise = Promise.new(function() end)
			promise:andThen(function() end)
			local promises = {
				promise,
				Promise.new(function() end),
				Promise.new(function(resolve)
					resolve(2)
				end)
			}

			local promise = Promise.race(promises)

			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(promise._values[1]).to.equal(2)
			expect(promises[1]:getStatus()).to.equal(Promise.Status.Started)
			expect(promises[2]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:getStatus()).to.equal(Promise.Status.Resolved)

			local p = Promise.new(function() end)
			expect(Promise.race({
				Promise.reject(),
				Promise.resolve(),
				p
			}):getStatus()).to.equal(Promise.Status.Rejected)
			expect(p:getStatus()).to.equal(Promise.Status.Cancelled)
		end)

		it("should error if a non-array table is passed in", function()
			local ok, err = pcall(function()
				Promise.race(Promise.new(function() end))
			end)

			expect(ok).to.be.ok()
			expect(err:find("Non%-promise")).to.be.ok()
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:andThen(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.race(promises):cancel()

			expect(promises[1]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:getStatus()).to.equal(Promise.Status.Started)
		end)
	end)

	describe("Promise.promisify", function()
		it("should wrap functions", function()
			local function test(n)
				return n + 1
			end

			local promisified = Promise.promisify(test)
			local status, result = promisified(1):awaitStatus()

			expect(status).to.equal(Promise.Status.Resolved)
			expect(result).to.equal(2)
		end)

		it("should catch errors after a yield", function()
			local bindable = Instance.new("BindableEvent")
			local test = Promise.promisify(function ()
				bindable.Event:Wait()
				error('errortext')
			end)

			local promise = test()

			expect(promise:getStatus()).to.equal(Promise.Status.Started)
			bindable:Fire()
			expect(promise:getStatus()).to.equal(Promise.Status.Rejected)
			expect(promise._values[1]:find("errortext")).to.be.ok()
		end)
	end)

	describe("Promise.tap", function()
		it("should thread through values", function()
			local first, second

			Promise.resolve(1)
				:andThen(function(v)
					return v + 1
				end)
				:tap(function(v)
					first = v
					return v + 1
				end)
				:andThen(function(v)
					second = v
				end)

			expect(first).to.equal(2)
			expect(second).to.equal(2)
		end)

		it("should chain onto promises", function()
			local resolveInner, finalValue

			local promise = Promise.resolve(1)
				:tap(function()
					return Promise.new(function(resolve)
						resolveInner = resolve
					end)
				end)
				:andThen(function(v)
					finalValue = v
				end)

			expect(promise:getStatus()).to.equal(Promise.Status.Started)
			expect(finalValue).to.never.be.ok()

			resolveInner(1)

			expect(promise:getStatus()).to.equal(Promise.Status.Resolved)
			expect(finalValue).to.equal(1)
		end)
	end)

	describe("Promise.try", function()
		it("should catch synchronous errors", function()
			local errorText
			Promise.try(function()
				error('errortext')
			end):catch(function(e)
				errorText = e
			end)

			expect(errorText:find("errortext")).to.be.ok()
		end)
	end)

	describe("Promise:andThenReturn", function()
		it("should return the given values", function()
			local value1, value2

			Promise.resolve():andThenReturn(1, 2):andThen(function(one, two)
				value1 = one
				value2 = two
			end)

			expect(value1).to.equal(1)
			expect(value2).to.equal(2)
		end)
	end)

	describe("Promise:doneReturn", function()
		it("should return the given values", function()
			local value1, value2

			Promise.resolve():doneReturn(1, 2):andThen(function(one, two)
				value1 = one
				value2 = two
			end)

			expect(value1).to.equal(1)
			expect(value2).to.equal(2)
		end)
	end)

	describe("Promise:andThenCall", function()
		it("should call the given function with arguments", function()
			local value1, value2
			Promise.resolve():andThenCall(function(a, b)
				value1 = a
				value2 = b
			end, 3, 4)

			expect(value1).to.equal(3)
			expect(value2).to.equal(4)
		end)
	end)

	describe("Promise:doneCall", function()
		it("should call the given function with arguments", function()
			local value1, value2
			Promise.resolve():doneCall(function(a, b)
				value1 = a
				value2 = b
			end, 3, 4)

			expect(value1).to.equal(3)
			expect(value2).to.equal(4)
		end)
	end)

	describe("Promise:done", function()
		it("should trigger on resolve or cancel", function()
			local promise = Promise.new(function() end)
			local value

			local p = promise:done(function()
				value = true
			end)

			expect(value).to.never.be.ok()
			promise:cancel()
			expect(p:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(value).to.equal(true)

			local never, always
			Promise.reject():done(function()
				never = true
			end):finally(function()
				always = true
			end)

			expect(never).to.never.be.ok()
			expect(always).to.be.ok()
		end)
	end)

	describe("Promise.some", function()
		it("should resolve once the goal is reached", function()
			local p = Promise.some({
				Promise.resolve(1),
				Promise.reject(),
				Promise.resolve(2)
			}, 2)
			expect(p:getStatus()).to.equal(Promise.Status.Resolved)
			expect(p._values[1][1]).to.equal(1)
			expect(p._values[1][2]).to.equal(2)
		end)

		it("should error if the goal can't be reached", function()
			expect(Promise.some({
				Promise.resolve(),
				Promise.reject()
			}, 2):getStatus()).to.equal(Promise.Status.Rejected)

			local reject
			local p = Promise.some({
				Promise.resolve(),
				Promise.new(function(_, r) reject = r end)
			}, 2)

			expect(p:getStatus()).to.equal(Promise.Status.Started)
			reject("foo")
			expect(p:getStatus()).to.equal(Promise.Status.Rejected)
			expect(p._values[1]).to.equal("foo")
		end)

		it("should cancel pending Promises once the goal is reached", function()
			local resolve
			local pending1 = Promise.new(function() end)
			local pending2 = Promise.new(function(r) resolve = r end)

			local some = Promise.some({
				pending1,
				pending2,
				Promise.resolve()
			}, 2)

			expect(some:getStatus()).to.equal(Promise.Status.Started)
			expect(pending1:getStatus()).to.equal(Promise.Status.Started)
			expect(pending2:getStatus()).to.equal(Promise.Status.Started)

			resolve()

			expect(some:getStatus()).to.equal(Promise.Status.Resolved)
			expect(pending1:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(pending2:getStatus()).to.equal(Promise.Status.Resolved)
		end)

		it("should error if passed a non-number", function()
			expect(function()
				Promise.some({}, "non-number")
			end).to.throw()
		end)

		it("should return an empty array if amount is 0", function()
			local p = Promise.some({
				Promise.resolve(2)
			}, 0)

			expect(p:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#p._values[1]).to.equal(0)
		end)

		it("should not return extra values", function()
			local p = Promise.some({
				Promise.resolve(1),
				Promise.resolve(2),
				Promise.resolve(3),
				Promise.resolve(4),
			}, 2)

			expect(p:getStatus()).to.equal(Promise.Status.Resolved)
			expect(#p._values[1]).to.equal(2)
			expect(p._values[1][1]).to.equal(1)
			expect(p._values[1][2]).to.equal(2)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:andThen(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.some(promises, 3):cancel()

			expect(promises[1]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:getStatus()).to.equal(Promise.Status.Started)
		end)

		describe("Promise.any", function()
			it("should return the value directly", function()
				local p = Promise.any({
					Promise.reject(),
					Promise.reject(),
					Promise.resolve(1)
				})

				expect(p:getStatus()).to.equal(Promise.Status.Resolved)
				expect(p._values[1]).to.equal(1)
			end)

			it("should error if all are rejected", function()
				expect(Promise.any({
					Promise.reject(),
					Promise.reject(),
					Promise.reject(),
				}):getStatus()).to.equal(Promise.Status.Rejected)
			end)
		end)
	end)

	describe("Promise.allSettled", function()
		it("should resolve with an array of PromiseStatuses", function()
			local reject
			local p = Promise.allSettled({
				Promise.resolve(),
				Promise.reject(),
				Promise.resolve(),
				Promise.new(function(_, r) reject = r end)
			})

			expect(p:getStatus()).to.equal(Promise.Status.Started)
			reject()
			expect(p:getStatus()).to.equal(Promise.Status.Resolved)
			expect(p._values[1][1]).to.equal(Promise.Status.Resolved)
			expect(p._values[1][2]).to.equal(Promise.Status.Rejected)
			expect(p._values[1][3]).to.equal(Promise.Status.Resolved)
			expect(p._values[1][4]).to.equal(Promise.Status.Rejected)
		end)

		it("should cancel promises if it is cancelled", function()
			local p = Promise.new(function() end)
			p:andThen(function() end)

			local promises = {
				Promise.new(function() end),
				Promise.new(function() end),
				p
			}

			Promise.allSettled(promises):cancel()

			expect(promises[1]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[2]:getStatus()).to.equal(Promise.Status.Cancelled)
			expect(promises[3]:getStatus()).to.equal(Promise.Status.Started)
		end)
	end)
end
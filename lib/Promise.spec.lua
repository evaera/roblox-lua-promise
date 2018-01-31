return function()
	local Promise = require(script.Parent.Promise)

	describe("new", function()
		it("should pass resolve and reject to the callback", function()
			local promiseResolve
			local promiseReject
			local callCount = 0

			local promise = Promise.new(function(resolve, reject)
				callCount = callCount + 1
				promiseResolve = resolve
				promiseReject = reject
			end)

			expect(promise).to.be.ok()
			expect(promiseResolve).to.be.a("function")
			expect(promiseReject).to.be.a("function")
			expect(callCount).to.equal(1)
		end)

		it("should resolve synchronously", function()
			local promiseResolve
			local callCount = 0

			local promise = Promise.new(function(resolve)
				callCount = callCount + 1
				promiseResolve = resolve
			end)

			expect(promise._status).to.equal(Promise.Status.Started)

			promiseResolve(6, 7)

			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value).to.be.a("table")
			expect(#promise._value).to.equal(2)
			expect(promise._value[1]).to.equal(6)
			expect(promise._value[2]).to.equal(7)
		end)

		it("should reject synchronously", function()
			local promiseReject
			local callCount = 0

			local promise = Promise.new(function(_, reject)
				callCount = callCount + 1
				promiseReject = reject
			end)

			expect(promise._status).to.equal(Promise.Status.Started)

			promiseReject(6, 7)

			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value).to.be.a("table")
			expect(#promise._value).to.equal(2)
			expect(promise._value[1]).to.equal(6)
			expect(promise._value[2]).to.equal(7)
		end)
	end)

	describe("resolve", function()
		it("should be a synchronously resolved promise", function()
			local promise = Promise.resolve(3)

			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value).to.be.a("table")
			expect(#promise._value).to.equal(1)
			expect(promise._value[1]).to.equal(3)
		end)
	end)

	describe("reject", function()
		it("should be a synchronously rejected promise", function()
			local promise = Promise.reject(3)

			expect(promise._status).to.equal(Promise.Status.Rejected)
			expect(promise._value).to.be.a("table")
			expect(#promise._value).to.equal(1)
			expect(promise._value[1]).to.equal(3)
		end)
	end)

	describe("andThen", function()
		it("should be chained with unresolved promises", function()
			local rootResolve
			local rootCallCount = 0
			local childCallCount = 0
			local childValues

			local root = Promise.new(function(resolve)
				rootCallCount = rootCallCount + 1
				rootResolve = resolve
			end)

			local child = root:andThen(function(...)
				childCallCount = childCallCount + 1
				childValues = {...}

				return "foo"
			end)

			expect(root).never.to.equal(child)
			expect(rootCallCount).to.equal(1)
			expect(childCallCount).to.equal(0)

			expect(root._status).to.equal(Promise.Status.Started)
			expect(child._status).to.equal(Promise.Status.Started)

			rootResolve(16, 13)

			expect(root._status).to.equal(Promise.Status.Resolved)
			expect(root._value).to.be.a("table")
			expect(#root._value).to.equal(2)
			expect(root._value[1]).to.equal(16)
			expect(root._value[2]).to.equal(13)

			expect(#childValues).to.equal(2)
			expect(childValues[1]).to.equal(16)
			expect(childValues[2]).to.equal(13)

			expect(child._status).to.equal(Promise.Status.Resolved)
			expect(child._value).to.be.a("table")
			expect(#child._value).to.equal(1)
			expect(child._value[1]).to.equal("foo")
		end)
	end)
end
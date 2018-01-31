return function()
	local Promise = require(script.Parent.Promise)

	describe("Promise.new", function()
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

			promiseResolve(6)

			expect(promise._status).to.equal(Promise.Status.Resolved)
			expect(promise._value).to.be.a("table")
			expect(#promise._value).to.equal(1)
			expect(promise._value[1]).to.equal(6)
		end)
	end)
end
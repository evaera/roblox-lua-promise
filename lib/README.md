---
title: Promise
docs:
  desc: A Promise is an object that represents a value that will exist in the future, but doesn't right now. Promises allow you to then attach callbacks that can run once the value becomes available (known as *resolving*), or if an error has occurred (known as *rejecting*).

  types:
    - name: PromiseStatus
      desc: An enum value used to represent the Promise's status.
      kind: enum
      type:
        Started:
          desc: The Promise is executing, and not settled yet.
        Resolved:
          desc: The Promise finished successfully.
        Rejected:
          desc: The Promise was rejected.
        Cancelled:
          desc: The Promise was cancelled before it finished.

  properties:
    - name: Status
      tags: [ 'read only', 'static', 'enums' ]
      type: PromiseStatus
      desc: A table containing all members of the `PromiseStatus` enum, e.g., `Promise.Status.Resolved`.
      

  functions:
    - name: new
      tags: [ 'constructor' ]
      desc: |
        Construct a new Promise that will be resolved or rejected with the given callbacks.

        ::: tip
          If your Promise executor needs to yield, it is recommended to use [[Promise.async]] instead. You cannot directly yield inside the `executor` function of [[Promise.new]].
        :::

        If you `resolve` with a Promise, it will be chained onto.
        
        You may register an optional cancellation hook by using the `onCancel` argument.
          * This should be used to abort any ongoing operations leading up to the promise being settled. 
          * Call the `onCancel` function with a function callback as its only argument to set a hook which will in turn be called when/if the promise is cancelled.
          * `onCancel` returns `true` if the Promise was already cancelled when you called `onCancel`.
          * Calling `onCancel` with no argument will not override a previously set cancellation hook, but it will still return `true` if the Promise is currently cancelled.
          * You can set the cancellation hook at any time before resolving.
          * When a promise is cancelled, calls to `resolve` or `reject` will be ignored, regardless of if you set a cancellation hook or not.
      static: true
      params:
        - name: executor
          type:
            kind: function
            params:
              - name: resolve
                type:
                  kind: function
                  params:
                    - name: "..."
                      type: ...any?
                  returns: void
              - name: reject
                type:
                  kind: function
                  params:
                    - name: "..."
                      type: ...any?
                  returns: void
              - name: onCancel
                type:
                  kind: function
                  params:
                    - name: abortHandler
                      kind: function
                  returns:
                    - type: boolean
                      desc: "Returns `true` if the Promise was already cancelled at the time of calling `onCancel`."
      returns: Promise
    - name: async
      tags: [ 'constructor' ]
      desc: |
        The same as [[Promise.new]], except it allows yielding. Use this if you want to yield inside your Promise body.
        
        If your Promise body does not need to yield, such as when attaching `resolve` to an event listener, you should use [[Promise.new]] instead.
        
        ::: tip
        Promises created with [[Promise.async]] don't begin executing until the next `RunService.Heartbeat` event, even if the executor function doesn't yield itself. This is to ensure that Promises produced from a function are either always synchronous or always asynchronous. <a href="/roblox-lua-promise/lib/Details.html#yielding-in-promise-executor">Learn more</a>
        :::
        
        ```lua
        local function waitForChild(instance, childName, timeout)
          return Promise.async(function(resolve, reject)
            local child = instance:WaitForChild(childName, timeout)

            ;(child and resolve or reject)(child)
          end)
        end
        ```
        
      static: true
      params:
        - name: asyncExecutor
          type:
            kind: function
            params:
              - name: resolve
                type:
                  kind: function
                  params:
                    - name: "..."
                      type: ...any?
                  returns: void
              - name: reject
                type:
                  kind: function
                  params:
                    - name: "..."
                      type: ...any?
                  returns: void
              - name: onCancel
                type:
                  kind: function
                  params:
                    - name: abortHandler
                      kind: function
                  returns:
                    - type: boolean
                      desc: "Returns `true` if the Promise was already cancelled at the time of calling `onCancel`."
      returns: Promise

    - name: promisify
      desc: |
        Wraps a function that yields into one that returns a Promise.

        Any errors that occur while executing the function will be turned into rejections.

        ```lua
        local sleep = Promise.promisify(wait)

        sleep(1):andThen(print)
        ```

        ```lua
        local isPlayerInGroup = Promise.promisify(function(player, groupId)
          return player:IsInGroup(groupId)
        end)
        ```        
      static: true
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
      returns:
        - desc: The function acts like the passed function but now returns a Promise of its return values.
          type:
            kind: function
            params:
              - name: "..."
                type: "...any?"
                desc: The same arguments the wrapped function usually takes.
            returns:
              - name: "*"
                desc: The return values from the wrapped function.
  
    - name: resolve
      desc: Creates an immediately resolved Promise with the given value.
      static: true
      params: "value: ...any"
      returns: Promise<...any>
    - name: reject
      desc: Creates an immediately rejected Promise with the given value.
      static: true
      params: "value: ...any"
      returns: Promise<...any>
    - name: try
      desc: |
        Begins a Promise chain, calling a synchronous function and returning a Promise resolving with its return value. If the function errors, the returned Promise will be rejected with the error.

        `Promise.try` is similar to [[Promise.promisify]], except the callback is invoked immediately instead of returning a new function, and unlike `promisify`, yielding is not allowed with `try`.

        ```lua
        Promise.try(function()
          return math.random(1, 2) == 1 and "ok" or error("Oh an error!")
        end)
          :andThen(function(text)
            print(text)
          end)
          :catch(function(err)
            warn("Something went wrong")
          end)
        ```
      static: true
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
            returns: "...any?"
        - name: "..."
          type: "...any?"
          desc: Arguments for the callback
      returns:
        - type: "Promise<...any?>"
          desc: The return value of the passed callback.
        
    - name: all
      desc: |
        Accepts an array of Promises and returns a new promise that:
          * is resolved after all input promises resolve.
          * is rejected if ANY input promises reject.
        Note: Only the first return value from each promise will be present in the resulting array.

        After any input Promise rejects, all other input Promises that are still pending will be cancelled if they have no other consumers.
      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<array<T>>

    - name: allSettled
      desc: |
        Accepts an array of Promises and returns a new Promise that resolves with an array of in-place PromiseStatuses when all input Promises have settled. This is equivalent to mapping `promise:finally` over the array of Promises.
      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<array<PromiseStatus>>

    - name: race
      desc: |
        Accepts an array of Promises and returns a new promise that is resolved or rejected as soon as any Promise in the array resolves or rejects.

        All other Promises that don't win the race will be cancelled if they have no other consumers.
      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<T>

    - name: some
      desc: |
        Accepts an array of Promises and returns a Promise that is resolved as soon as `count` Promises are resolved from the input array. The resolved array values are in the order that the Promises resolved in. When this Promise resolves, all other pending Promises are cancelled if they have no other consumers.

        `count` 0 results in an empty array. The resultant array will never have more than `count` elements.
      static: true
      params: "promises: array<Promise<T>>, count: number"
      returns: Promise<array<T>>
    
    - name: any
      desc: |
        Accepts an array of Promises and returns a Promise that is resolved as soon as *any* of the input Promises resolves. It will reject only if *all* input Promises reject. As soon as one Promises resolves, all other pending Promises are cancelled if they have no other consumers.

        Resolves directly with the value of the first resolved Promise. This is essentially [[Promise.some]] with `1` count, except the Promise resolves with the value directly instead of an array with one element.

      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<T>

    - name: delay
      desc: |
        Returns a Promise that resolves after `seconds` seconds have passed. The Promise resolves with the actual amount of time that was waited.

        This function is **not** a wrapper around `wait`. `Promise.delay` uses a custom scheduler which provides more accurate timing. As an optimization, cancelling this Promise instantly removes the task from the scheduler.

        ::: warning
          Passing `NaN`, infinity, or a number less than 1/60 is equivalent to passing 1/60.
        :::
      params: "seconds: number"
      returns: Promise<number>
      static: true
    - name: is
      desc: Returns whether the given object is a Promise. This only checks if the object is a table and has an `andThen` method.
      static: true
      params: "object: any"
      returns: 
        - type: boolean
          desc: "`true` if the given `object` is a Promise."

    # Instance methods
    - name: andThen
      desc: |
        Chains onto an existing Promise and returns a new Promise.

        Return a Promise from the success or failure handler and it will be chained onto.
      params:
        - name: successHandler
          type:
            kind: function
            params: "...: ...any?"
            returns: ...any?
        - name: failureHandler
          optional: true
          type:
            kind: function
            params: "...: ...any?"
            returns: ...any?
      returns: Promise<...any?>
      overloads:
        - params:
          - name: successHandler
            type:
              kind: function
              params: "...: ...any?"
              returns: Promise<T>
          - name: failureHandler
            optional: true
            type:
              kind: function
              params: "...: ...any?"
              returns: Promise<T>
          returns: Promise<T>
    
    - name: catch
      desc: Shorthand for `Promise:andThen(nil, failureHandler)`.
      params: 
        - name: failureHandler
          type:
            kind: function
            params: "...: ...any?"
            returns: ...any?
      returns: Promise<...any?>
      overloads:
        - params:
          - name: failureHandler
            type:
              kind: function
              params: "...: ...any?"
              returns: Promise<T>
          returns: Promise<T>

    - name: tap
      desc: |
        Similar to [[Promise.andThen]], except the return value is the same as the value passed to the handler. In other words, you can insert a `:tap` into a Promise chain without affecting the value that downstream Promises receive.

        ```lua
          getTheValue()
            :tap(print)
            :andThen(function(theValue)
              print("Got", theValue, "even though print returns nil!")
            end)
        ```

        If you return a Promise from the tap handler callback, its value will be discarded but `tap` will still wait until it resolves before passing the original value through.
      params: 
        - name: tapHandler
          type:
            kind: function
            params: "...: ...any?"
            returns: ...any?
      returns: Promise<...any?>
    
    - name: finally
      desc: |
        Set a handler that will be called regardless of the promise's fate. The handler is called when the promise is resolved, rejected, *or* cancelled.

        Returns a new promise chained from this promise.
      params:
        - name: finallyHandler
          type:
            kind: function
            params: "status: PromiseStatus"
            returns: ...any? 
      returns: Promise<...any?> 
      overloads:
        - params:
          - name: finallyHandler
            type:
              kind: function
              params: "status: PromiseStatus"
              returns: Promise<T>
          returns: Promise<T>

    - name: done
      desc: |
        Set a handler that will be called only if the Promise resolves or is cancelled. This method is similar to `finally`, except it doesn't catch rejections.

        ::: warning
        If this Promise is cancelled, any Promises chained off of it with `andThen` won't run. Only Promises chained with `done` and `finally` will run in the case of cancellation.
        :::

        Returns a new promise chained from this promise.
      params:
        - name: doneHandler
          type:
            kind: function
            params: "status: PromiseStatus"
            returns: ...any? 
      returns: Promise<...any?> 
      overloads:
        - params:
          - name: doneHandler
            type:
              kind: function
              params: "status: PromiseStatus"
              returns: Promise<T>
          returns: Promise<T>

    - name: andThenCall
      desc: |
        Attaches an `andThen` handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.

        ```lua
          promise:andThenCall(someFunction, "some", "arguments")
        ```

        This is sugar for

        ```lua
          promise:andThen(function()
            return someFunction("some", "arguments")
          end)
        ```
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
            returns: "any"
        - name: "..."
          type: "...any?"
          desc: Arguments which will be passed to the callback.
      returns: Promise

    - name: finallyCall
      desc: |
        Same as `andThenCall`, except for `finally`.

        Attaches a `finally` handler to this Promise that calls the given callback with the predefined arguments.
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
            returns: "any"
        - name: "..."
          type: "...any?"
          desc: Arguments which will be passed to the callback.
      returns: Promise

    - name: doneCall
      desc: |
        Same as `andThenCall`, except for `done`.

        Attaches a `done` handler to this Promise that calls the given callback with the predefined arguments.
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
            returns: "any"
        - name: "..."
          type: "...any?"
          desc: Arguments which will be passed to the callback.
      returns: Promise

    - name: andThenReturn
      desc: |
        Attaches an `andThen` handler to this Promise that discards the resolved value and returns the given value from it.

        ```lua
          promise:andThenReturn("some", "values")
        ```

        This is sugar for

        ```lua
          promise:andThen(function()
            return "some", "values"
          end)
        ```

        ::: warning
        Promises are eager, so if you pass a Promise to `andThenReturn`, it will begin executing before `andThenReturn` is reached in the chain. Likewise, if you pass a Promise created from [[Promise.reject]] into `andThenReturn`, it's possible that this will trigger the unhandled rejection warning. If you need to return a Promise, it's usually best practice to use [[Promise.andThen]].
        :::
      params:
        - name: "..."
          type: "...any?"
          desc: Values to return from the function.
      returns: Promise<...any?>

    - name: finallyReturn
      desc: |
        Attaches a `finally` handler to this Promise that discards the resolved value and returns the given value from it.

        ```lua
          promise:finallyReturn("some", "values")
        ```

        This is sugar for

        ```lua
          promise:finally(function()
            return "some", "values"
          end)
        ```
      params:
        - name: "..."
          type: "...any?"
          desc: Values to return from the function.
      returns: Promise<...any?>

    - name: doneReturn
      desc: |
        Attaches a `done` handler to this Promise that discards the resolved value and returns the given value from it.

        ```lua
          promise:doneReturn("some", "values")
        ```

        This is sugar for

        ```lua
          promise:done(function()
            return "some", "values"
          end)
        ```
    
      params:
        - name: "..."
          type: "...any?"
          desc: Values to return from the function.
      returns: Promise<...any?>

    - name: timeout
      params: "seconds: number, rejectionValue: any?"
      desc: |
        Returns a new Promise that resolves if the chained Promise resolves within `seconds` seconds, or rejects if execution time exceeds `seconds`. The chained Promise will be cancelled if the timeout is reached.

        Sugar for:

        ```lua
        Promise.race({
          Promise.delay(seconds):andThen(function()
            return Promise.reject(rejectionValue == nil and "Timed out" or rejectionValue)
          end),
          promise
        })
        ```

    - name: cancel
      desc: |
        Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

        Cancellations will propagate upwards and downwards through chained promises.

        Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `andThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

    - name: await
      desc: |
        Yields the current thread until the given Promise completes. Returns true if the Promise resolved, followed by the values that the promise resolved or rejected with.

        ::: warning
        If the Promise gets cancelled, this function will return `false`, which is indistinguishable from a rejection. If you need to differentiate, you should use [[Promise.awaitStatus]] instead.
        :::
      returns:
        - desc: "`true` if the Promise successfully resolved."
          type: boolean
        - desc: The values that the Promise resolved or rejected with.
          type: ...any?
    
    - name: awaitStatus
      desc: Yields the current thread until the given Promise completes. Returns the Promise's status, followed by the values that the promise resolved or rejected with.
      returns:
        - type: PromiseStatus
          desc: The Promise's status.
        - type: ...any?
          desc: The values that the Promise resolved or rejected with.
    - name: awaitValue
      desc: |
        Yields the current thread until the given Promise completes. Returns the the values that the promise resolved with.
        
        Errors if the Promise rejects or gets cancelled.
      returns:
        - type: ...any?
          desc: The values that the Promise resolved with.
    
    - name: getStatus
      desc: Returns the current Promise status.
      returns: PromiseStatus
---

<ApiDocs />
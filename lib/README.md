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
        The same as [[Promise.new]], except it implicitly uses [[Promise.spawn]] internally. Use this if you want to yield inside your Promise body.
        
        If your Promise body does not need to yield, such as when attaching `resolve` to an event listener, you should use [[Promise.new]] instead.
        
        ::: tip
        Promises created with [[Promise.async]] don't begin executing until the next `RunService.Heartbeat` event, even if the executor function doesn't yield itself. <a href="/roblox-lua-promise/lib/Details.html#yielding-in-promise-executor">Learn more</a>
        :::
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
  
    - name: resolve
      desc: Creates an immediately resolved Promise with the given value.
      static: true
      params: "value: T"
      returns: Promise<T>
    - name: reject
      desc: Creates an immediately rejected Promise with the given value.
      static: true
      params: "value: T"
      returns: Promise<T>
    - name: all
      desc: |
        Accepts an array of Promises and returns a new promise that:
          * is resolved after all input promises resolve.
          * is rejected if ANY input promises reject.
        Note: Only the first return value from each promise will be present in the resulting array.
      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<array<T>>
    - name: race
      desc: |
        Accepts an array of Promises and returns a new promise that is resolved or rejected as soon as any Promise in the array resolves or rejects.

        All other Promises that don't win the race will be cancelled.
      static: true
      params: "promises: array<Promise<T>>"
      returns: Promise<T>
    - name: is
      desc: Returns whether the given object is a Promise.
      static: true
      params: "object: any"
      returns: 
        - type: boolean
          desc: "`true` if the given `object` is a Promise."
    - name: spawn
      desc: Spawns a thread with predictable timing. The callback will be called on the next `RunService.Heartbeat` event.
      static: true
      params:
        - name: callback
          type:
            kind: function
            params: "...: ...any?"
        - name: "..."
          type: "...any?"
    - name: promisify
      desc: |
        Wraps a function that yields into one that returns a Promise.

        ```lua
        local sleep = Promise.promisify(wait)

        sleep(1):andThen(print)
        ```
      static: true
      params:
        - name: function
          type:
            kind: function
            params: "...: ...any?"
        - name: selfValue
          type: any?
          desc: This value will be prepended to the arguments list given to the curried function. This can be used to lock a method to a single instance. Otherwise, you can pass the self value before the argument list.
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

    - name: andThenCall
      desc: |
        Attaches an `andThen` handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.

        ```lua
          promise:andThenCall(someFunction, "some", "arguments")
        ```

        This is sugar for

        ```lua
          promise:andThen(function()
            return callback(...args)
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

    - name: cancel
      desc: |
        Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

        Cancellations will propagate upwards through chained promises.

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
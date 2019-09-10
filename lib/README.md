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
          Generally, it is recommended to use [[Promise.async]] instead. You cannot directly yield inside the `executor` function of [[Promise.new]].
        :::

        If you `resolve` with a Promise, it will be chained onto.
        
        You may register an optional cancellation hook by using the `onCancel` argument.
          * This should be used to abort any ongoing operations leading up to the promise being settled. 
          * Call the `onCancel` function with a function callback as its only argument to set a hook which will in turn be called when/if the promise is cancelled.
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
                  returns: void
      returns: Promise
    - name: async
      tags: [ 'constructor' ]
      desc: |
        The same as [[Promise.new]], except it implicitly uses `Promise.spawn` internally. Use this if you want to yield inside your Promise body.

        ::: tip
        Promises created with [[Promise.async]] are guaranteed to yield for at least one frame, even if the executor function doesn't yield itself. <a href="/roblox-lua-promise/lib/Details.html#yielding-in-promise-executor">Learn more</a>
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
                  returns: void
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
            returns: ...any? 
      returns: Promise<...any?> 
      overloads:
        - params:
          - name: finallyHandler
            type:
              kind: function
              returns: Promise<T>
          returns: Promise<T>



    - name: cancel
      desc: |
        Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

        Cancellations will propagate upwards through chained promises.

        Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `andThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

    - name: await
      desc: Yields the current thread until the given Promise completes. Returns `ok` as a bool, followed by the value that the promise returned.
      returns:
        - desc: Fate of the Promise. `true` if resolved, `false` if rejected, `nil` if cancelled.
          type: boolean | nil
        - desc: The values that the Promise resolved or rejected with.
          type: ...any?
    
    - name: getStatus
      desc: Returns the current Promise status.
      returns: PromiseStatus
---

<ApiDocs />
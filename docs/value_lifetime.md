# Values Lifetime

Heap-valued `JSValue`s are local handles and must be created inside an engine scope. The
scope must remain open until an escaping result has passed through `retain`; closing it
then releases all intermediate handles while the retained `JSHeapObject` global remains
valid.

### Scope ownership

The scope policy must therefore cover every operation that enters `ark_interop`. There are two coherent
ownership models.

#### Runtime-managed scopes

The runtime can make `run` both the thread-dispatch and handle-scope boundary. The scope
is opened only after execution reaches the JS thread, and it encloses `operation()` in
both paths:

```cangjie
private static func run<R>(operation: () -> R): R {
    if (context.isInBindThread()) {
        return context.newScope {
            operation()
        }
    }

    let result = Box(None<ArkTSResult<R>>)
    let mutex = Mutex()
    let done: Condition
    synchronized(mutex) {
        done = mutex.condition()
    }

    context.postJSTask {
        let completed: ArkTSResult<R> =
            try {
                ArkTSResult.Ok(
                    context.newScope {
                        operation()
                    }
                )
            } catch (e: Exception) {
                ArkTSResult.Err(e)
            }
        synchronized(mutex) {
            result.value = Some(completed)
            done.notify()
        }
    }

    synchronized(mutex) {
        done.waitUntil({ => result.value.isSome() })
        match (result.value.getOrThrow()) {
            case Ok(value) => value
            case Err(error) => throw error
        }
    }
}
```

Every public operation already goes through `run`, so this covers evaluation, conversion,
and helpers without relying on callers. `retain` executes inside `operation()` and creates
a global before the scope closes. Thus `run` may return a retained `Extern`, a global, an
immediate, or a Cangjie value, but it must never return an unretained heap `JSValue`.

This model opens one scope for every call to `run`, including calls that happen to use
only immediate values. Under the wood, the `newScope` is implemented by wrapping the 
execution of the lambda argument inside open/close `@FastNative` FFI function calls.

#### Caller-managed scopes

Alternatively, `run` can remain a dispatch-only primitive and the library can expose a
scope helper:

```cangjie
public static func withScope<R>(operation: () -> R): R {
    run {
        context.newScope(operation)
    }
}
```

The user can then group several operations under one dispatch and one scope:

```cangjie
let blob = ArkTS.withScope {
    let api = ArkTS.requireArkModule("test.ets")
    let result = api.createRectangle()
    result.width = 3.0
    let area: Float64 = (Float64)result.area()
    result
}
```

Calls made inside the block see that they are already on the bind thread, so their nested
calls to the dispatch-only `run` execute inline. Temporary local handles from all four
operations are released when `withScope` returns. The returned `blob` remains valid
because any heap value escaping in an `Extern` has been promoted to a global.

This approach amortizes both dispatch and scope creation across the block, but it makes
correctness depend on user discipline. An operation made outside `withScope` may have no
scope at all, and the compiler cannot force application code to use the helper. A scope
must also not span an asynchronous suspension or be closed on a different thread. For
those reasons, caller-managed scopes are better treated as an optimization than as the
only lifetime mechanism.

#### Automatic safety with optional batching

The two models can be combined by tracking scopes opened through `ArkTS<T>`. A normal
operation reuses the current ArkTS-managed scope; if none exists, it runs in a temporary
scope. The public `newScope` helper always opens a fresh scope, even when called inside
another one.

```cangjie
private static var scopeLevel = 0

public static func newScope<R>(operation: () -> R): R {
    run(operation, newScope:true)
}

private static func runInScope<R>(operation: () -> R, newScope!: Bool = false): R {
    // Only called on the JS bind thread.
    if (scopeLevel > 0 && !newScope) {
        return operation()
    } else {
        scopeLevel++
        try {
            context.newScope {
                operation()
            }
        } finally {
            scopeLevel--
        }
    }
}

private static func run<R>(operation: () -> R, newScope!: Bool = false): R {
    if (context.isInBindThread()) {
        return runInScope(operation, newScope)          // <--- creates new scope if no scope exists
    }
    ...
    context.postJSTask {
        let completed: ArkTSResult<R> =
            try {
                ArkTSResult.Ok(
                    runInScope(operation, newScope)   // <--- creates new scope if no scope exists
                )
            } catch (e: Exception) {
                ArkTSResult.Err(e)
            }
        ...
    }
    ...
}
```

`scopeLevel` is accessed only after `run` reaches the bind thread, so no synchronization
is needed. The `finally` restores it if opening the scope or executing the operation
throws. `newScope: true` forces `runInScope` to push a new engine scope; ordinary nested
operations see `scopeLevel > 0` and reuse the current one.

A standalone operation is therefore safe without any user-managed scope. Before its
temporary scope closes, `retain` promotes an escaping heap value to a global:

```cangjie
let e: Extern<ArkTS> = ArkTS.object()             // temporary scope; e owns a global
```

Several operations can instead share one ArkTS-managed scope, and explicit scopes can be
nested:

```cangjie
let blob = ArkTS.newScope {                       // scope A
    let api = ArkTS.requireArkModule("test.ets")
    let result = api.createRectangle()

    ArkTS.newScope {                              // scope B
        result.width = 3.0
        let area: Float64 = (Float64)result.area()
    }                                             // close B

    result.height = 4.0                           // scope A again
    result
}                                                 // close A
```

Local handles created inside scope B are registered in B and released when B closes;
scope A then becomes the top scope again. The returned `blob` remains valid because its
heap value escaped through an `Extern` and was promoted to a global before the scope
closed. Closing either scope does not release globals already owned by `Extern`s.

This gives standalone calls automatic safety, lets a batch share one dispatch and one
ArkTS-managed scope, and supports real nested cleanup boundaries. A scope callback must
remain synchronous on the JS thread, and a raw local heap `JSValue` must not escape it.

The counter deliberately tracks only scopes opened through this ArkTS runtime. It does
not attempt to infer whether external code has opened a scope because the public
`ark_interop` API does not expose that state.

Values produced while reducing a tree remain local and only its final result is retained.
Consequently, a chain such as `a.b.c.d` does not create a global handle for each member
access.

An evaluated `ExternPayload(Imm(...))` needs no disposal. `ExternPayload(Ref(...))` owns an
engine global whose `JSHeapObject` finalizer queues disposal on the context's bind thread.
Unevaluated operation nodes own no additional engine resources, although they may refer to
payloads elsewhere in the tree.

| Kind | Storage | Dispose |
| --- | --- | --- |
| Intermediate `JSValue` | current engine scope | when that scope closes |
| `Imm` | engine immediate | none |
| `Ref` | `JSHeapObject` global | `JSHeapObject` finalizer |

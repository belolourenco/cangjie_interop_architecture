# Proposal: `ForeignRuntime.eval` + `ExternExpTree`

Collapse the dynamic `ForeignRuntime` operations into one entry point that receives the
whole expression as a tree. Cangjie code in [here](../examples/runtime_with_eval_and_ExternExpTree.cj).

## Interface

```cangjie
public enum ExternExpTree<T> where T <: ForeignRuntime<T> {
    | Value(Extern<T>)
    | MemberAccess(ExternExpTree<T>, String)
    | IndexedAccess(ExternExpTree<T>, Any)
    | MemberUpdate(ExternExpTree<T>, String, Any)
    | IndexedUpdate(ExternExpTree<T>, Any, Any)
    | FuncCall(ExternExpTree<T>, Array<Any>)
}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func eval(t: ExternExpTree<T>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}
```

`MemberUpdate` / `IndexedUpdate` perform the write and return a runtime-defined result
(e.g. `undefined`). Leaves and call/index operands that are ordinary Cangjie values stay
`Any` (same as today’s `functionCall` / `indexedAccess` args) and are converted inside
`eval` via `toExtern` when needed.

## Desugaring

```cangjie
e.f
// → T.eval(MemberAccess(Value(e), "f"))

e[i]
// → T.eval(IndexedAccess(Value(e), i))

e.f = v
// → T.eval(MemberUpdate(Value(e), "f", v))

e[i] = v
// → T.eval(IndexedUpdate(Value(e), i, v))

e(a, b)
// → T.eval(FuncCall(Value(e), [a, b]))

a.b.c.d
// → T.eval(
//       MemberAccess(MemberAccess(MemberAccess(Value(a), "b"), "c"), "d"))

a.m(10)
// → T.eval(FuncCall(MemberAccess(Value(a), "m"), [10]))

let x = a.m
x(20)
// → let x = T.eval(MemberAccess(Value(a), "m"))
//   T.eval(FuncCall(Value(x), [20]))
```

## Why this helps

- **Lifetime:** one `eval` can open a single scope for intermediates and promote only what
  escapes (e.g. the final `Extern`).
- **Method `this`:** `FuncCall(MemberAccess(a, "m"), ...)` keeps the receiver in the tree; a bare
  `FuncCall(Value(x), ...)` does not — matching JS call-site rules.
- **Batching:** a `MemberAccess` chain can be lowered to one path-capable FFI call instead of N
  `ARKTS_GetProperty`s.

## Alternative: `Extern` is the tree

Drop `ExternExpTree`. Make `Extern` itself the recursive enum; the leaf is `Payload(Any)`
instead of `Value(Extern<T>)`. Cangjie code in [here](../examples/runtime_with_eval_and_ExternAsATree.cj).

```cangjie
public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func eval(t: Extern<T>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}
```

Desugaring builds nested `Extern` nodes directly; `eval` reduces a tree to a concrete
`Payload` (or an evaluated result).

```cangjie
e.f
// → T.eval(MemberAccess(e, "f"))

e[i]
// → T.eval(IndexedAccess(e, i))

e.f = v
// → T.eval(MemberUpdate(e, "f", v))

e[i] = v
// → T.eval(IndexedUpdate(e, i, v))

e(a, b)
// → T.eval(FuncCall(e, [a, b]))

a.b.c.d
// → T.eval(
//       MemberAccess(MemberAccess(MemberAccess(a, "b"), "c"), "d"))

a.m(10)
// → T.eval(FuncCall(MemberAccess(a, "m"), [10]))

let x = a.m
x(20)
// → let x = T.eval(MemberAccess(a, "m"))
//   T.eval(FuncCall(x, [20]))
```

Same benefits as above; no parallel tree type and no `Value(...)` wrapper around existing
handles.

## Optional 1: Keep current operations

The proposal that introduces a `ExternExpTree` is compatible as an extension to the current operations `memberAccess`, `indexedAccess`, `toExtern`, etc. We can define the function `eval` resorting to the other static functions. The foreign runtime implementer can opt to simply implement `memberAccess`, `indexedAccess`, `memberUpdate`, `indexedUpdate`, `functionCall`, `fromExtern`, `toExtern` and leave the `eval` function as defined below.

Cangjie code in [here](../examples/runtime_with_eval_and_ExternExpTree_extended.cj).

```cangjie
public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func memberAccess(e: Extern<T>, field: String): Extern<T>
    static func indexedAccess(e: Extern<T>, arg: Any): Extern<T>

    static func memberUpdate(e: Extern<T>, field: String, value: Any) : Unit
    static func indexedUpdate(e: Extern<T>, field: Any, value: Any): Unit

    static func functionCall(e: Extern<T>, args: Array<Any>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>

    static func eval(externExpTree: ExternExpTree<T>): Extern<T> {
        match (externExpTree) {
            case Value(e) => return e
            case MemberAccess(t, field) =>
                let e = eval(t)
                return memberAccess(e, field)
            case IndexedAccess(t, idx) =>
                let e = eval(t)
                return indexedAccess(e, idx)
            case MemberUpdate(t, field, value) =>
                let e = eval(t)
                return toExtern(memberUpdate(e, field, value))
            case IndexedUpdate(t, idx, value) =>
                let e = eval(t)
                toExtern(indexedUpdate(e, idx, value))
            case FuncCall(t, args) =>
                let e = eval(t)
                return functionCall(e, args)
        }
    }
}
```

The same idea is also possible when the `Extern` is itself the tree, however that already breaks compatibility due to the changes to `Extern` itself.

Cangjie code in [here](../examples/runtime_with_eval_and_ExternAsATree_extended.cj).

```cangjie
public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func memberAccess(e: Extern<T>, field: String): Extern<T>
    static func indexedAccess(e: Extern<T>, arg: Any): Extern<T>

    static func memberUpdate(e: Extern<T>, field: String, value: Any) : Unit
    static func indexedUpdate(e: Extern<T>, field: Any, value: Any): Unit

    static func functionCall(e: Extern<T>, args: Array<Any>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>

    static func eval(t: Extern<T>): Extern<T> {
        match (t) {
            case Payload(e) => return t
            case MemberAccess(t, field) =>
                let e = eval(t)
                return memberAccess(e, field)
            case IndexedAccess(t, idx) =>
                let e = eval(t)
                return indexedAccess(e, idx)
            case MemberUpdate(t, field, value) =>
                let e = eval(t)
                return toExtern(memberUpdate(e, field, value))
            case IndexedUpdate(t, idx, value) =>
                let e = eval(t)
                toExtern(indexedUpdate(e, idx, value))
            case FuncCall(t, args) =>
                let e = eval(t)
                return functionCall(e, args)
        }
    }
}
```

## Optional 2: Define enum Extern as non-exhaustive

In this section we focus on the case in which `Extern` is defined as a tree, but the same idea applies to `ExternExpTree`.

The operations in the enum below are the primitive operations and any foreign runtime must implement them.

```cangjie
public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
}
```

However we can keep `Extern` as non-exhaustive such that it can be extended later without breaking backward compatibility.

```cangjie
public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
    ...
}
```

Additionally we might introduce an new operation `eval_unsupported` that can later be expanded to deal with newly added operations if they are not handled by the concrete runtime. Basically we define `ForeignRuntime<T>` as below. Note that we also add a new exception `ExternUnsupportedOperation` to report operations that are currently not supported.

```cangjie
private class ExternUnsupportedOperation <: Exception {}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(t: Extern<T>): Extern<T> {
        eval_unsupported(t)
    }

    static func eval_unsupported(t: Extern<T>): Extern<T> {
        throw ExternUnsupportedOperation()
    }
}
```

Any runtime implementer must call the `eval_unsupported` in the default case of the eval function.

```cangjie
public class ArkTS <: ForeignRuntime<ArkTS> {
  
  static func fromExtern<R>(h: Extern<T>): R { ... }
  static func toExtern<R>(v: R): Extern<T> { ... }

  static func eval(t: Extern<ArkTS>): Extern<ArkTS> {
      match (t) {
          case Payload(e) => ...
          case MemberAccess(t, field) => ...
          case IndexedAccess(t, idx) => ...
          case MemberUpdate(t, field, value) => ...
          case IndexedUpdate(t, idx, value) => ...
          case FuncCall(t, args) => ...
          case _ => eval_unsupported(t)
      }
  }
}
```

This way, if the `Extern` enum is extended to support new optimizations in the compiler we won't necessarily break backward compatibility in the implemented runtimes. For instance, assume we decide to implement a new optimization to sequencing of operations, e.g.

```cangjie
// assume e1: Extern<T>
// assume e2: Extern<T>
let e1.a = e2.foo() // desugared as T.eval(MemberUpdate(e1, "a", FuncCall(MemberAccess(e2, "foo"), [])))
e1.a                // desugared as T.eval(MemberAccess(e1, "a"))
```

We can introduce a new constructor `Seq`

```cangjie
public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
    | Seq(Extern<T>, Extern<T>)                        // <==== new Constructor
    | ...
}
```

And implement the desugaring of this particular constructor in terms of the primitive operations

```cangjie
private class ExternUnsupportedOperation <: Exception {}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(t: Extern<T>): Extern<T> {
        eval_unsupported(t)
    }

    static func eval_unsupported(t: Extern<T>): Extern<T> {
        match(t) {
            case Seq(e1, e2) =>
                let _ = eval(e1)
                return eval(e2)
            case _ => throw ExternUnsupportedOperation()
        }
    }
}
```

This way, even if the compiler starts desugaring code to the new `Seq` constructor, previously implemented foreign runtimes that followed the policy of calling `eval_unsupported` in the `eval` default case will continue working as expected.

```cangjie
// assume e1: Extern<T>
// assume e2: Extern<T>
let e1.a = e2.foo()
e1.a
// desugared as T.eval(Seq(T.eval(MemberUpdate(e1, "a", FuncCall(MemberAccess(e2, "foo"), []))), T.eval(MemberAccess(e1, "a"))))
```


The runtime implementation can later be refined to support the new operation

```cangjie
public class ArkTS <: ForeignRuntime<ArkTS> {
  
  static func fromExtern<R>(h: Extern<T>): R { ... }
  static func toExtern<R>(v: R): Extern<T> { ... }

  static func eval(t: Extern<ArkTS>): Extern<ArkTS> {
      match (t) {
          case Payload(e) => ...
          case MemberAccess(t, field) => ...
          case IndexedAccess(t, idx) => ...
          case MemberUpdate(t, field, value) => ...
          case IndexedUpdate(t, idx, value) => ...
          case FuncCall(t, args) => ...
          case Seq(e1, e2) => ...
          case _ => eval_unsupported(t)
      }
  }
}
```
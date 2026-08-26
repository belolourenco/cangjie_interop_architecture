# Proposal: `ForeignRuntime.eval` + `ExternExpTree`

Collapse the dynamic `ForeignRuntime` operations into one entry point that receives the
whole expression as a tree.

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
instead of `Value(Extern<T>)`.

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

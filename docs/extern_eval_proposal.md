# Proposal: `ForeignRuntime.eval` + `ExternExpTree`

Represent dynamic `ForeignRuntime` operations through a single entry point that receives
the complete expression tree. See the complete Cangjie code [here](../examples/runtime_with_eval_and_ExternExpTree.cj).

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

Ordinary Cangjie values used as call arguments, indexes, or assigned
values remain `Any`, as they are in the current API; `eval` is responsible to convert
them when necessary.

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

- **Lifetime management:** one `eval` call can use a single scope for intermediate values
  and promote only the final `Extern` that escapes. See [issue](https://github.com/belolourenco/cangjie_interop_architecture/blob/main/docs/issue_with_current_extern_interface.md#problem-1-two-lifetime-modes-in-ohosark_interop).
- **Method receivers:** `FuncCall(MemberAccess(a, "m"), ...)` preserves the receiver in the
  tree, while `FuncCall(Value(x), ...)` does not. This allows us to capture the JavaScript call-site rules. See [issue](https://github.com/belolourenco/cangjie_interop_architecture/blob/main/docs/issue_with_current_extern_interface.md#problem-2-hard-to-capture-js-semantics-on-method-call).
- **Batching:** a `MemberAccess` chain can become one path-based FFI call instead of several
  `ARKTS_GetProperty` calls. See [issue](https://github.com/belolourenco/cangjie_interop_architecture/blob/main/docs/issue_with_current_extern_interface.md#problem-2-hard-to-capture-js-semantics-on-method-call).

## Alternative: `Extern` is the tree

Eliminate `ExternExpTree` and make `Extern` the recursive enum. Its leaf becomes
`Payload(Any)` rather than `Value(Extern<T>)`. See the
[Cangjie code](../examples/runtime_with_eval_and_ExternAsATree.cj).

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

Desugaring builds nested `Extern` nodes directly. `eval` then reduces the tree to a
concrete `Payload`, or to another runtime-defined evaluated result.

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

This design has the same benefits as the primary proposal, without a parallel tree type or
a `Value(...)` wrapper around existing handles. Its main cost is that it changes the
representation of `Extern`.

## Option: keep the current operations

`ExternExpTree` can be added without removing the current operations. A default `eval`
implementation can recursively interpret the tree by calling those operations, allowing
existing runtime implementations to adopt the API without implementing an optimized
evaluator immediately.

See the complete Cangjie code [here](../examples/runtime_with_eval_and_ExternExpTree_extended.cj).

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
                return toExtern(indexedUpdate(e, idx, value))
            case FuncCall(t, args) =>
                let e = eval(t)
                return functionCall(e, args)
        }
    }
}
```

The same fallback is possible when `Extern` is the tree: replace `Value(e)` with
`Payload(e)` and have that case return its input. Changing the representation of `Extern`
still breaks compatibility. See the
complete Cangjie code [here](../examples/runtime_with_eval_and_ExternAsATree_extended.cj).

## Evolution option: make `Extern` non-exhaustive

This section uses the alternative design in which `Extern` is the tree, but the same
approach applies to `ExternExpTree`. Declaring the enum non-exhaustive leaves room for
future operations without making every extension a compatibility-breaking change:

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

The interface can also provide a default `eval_unsupported` fallback. Runtime
implementations can delegate unrecognized tree nodes to it. Initially, the fallback reports
an unsupported operation; it can later interpret new nodes in terms of older primitives.

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

Runtime implementations should delegate the default case of `eval` to
`eval_unsupported`:

```cangjie
public class ArkTS <: ForeignRuntime<ArkTS> {

    static func fromExtern<R>(h: Extern<ArkTS>): R { ... }
    static func toExtern<R>(v: R): Extern<ArkTS> { ... }

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

When followed, this convention lets the compiler add optimizable operations without
necessarily breaking existing runtimes. For example, consider two expressions evaluated
in sequence:

```cangjie
// e1: Extern<T>, e2: Extern<T>
e1.a = e2.foo()
e1.a
```

A later API version could add a `Seq` node:

```cangjie
public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
    | Seq(Extern<T>, Extern<T>)
    | ...
}
```

The default fallback can interpret `Seq` in terms of existing operations:

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

Runtimes that follow this convention inherit the new fallback behavior when the compiler
starts emitting `Seq`:

```cangjie
// e1: Extern<T>, e2: Extern<T>
e1.a = e2.foo()
e1.a
// → T.eval(Seq(
//       MemberUpdate(e1, "a", FuncCall(MemberAccess(e2, "foo"), [])),
//       MemberAccess(e1, "a")))
```

A runtime can later optimize the operation by handling `Seq` directly:

```cangjie
public class ArkTS <: ForeignRuntime<ArkTS> {

    static func fromExtern<R>(h: Extern<ArkTS>): R { ... }
    static func toExtern<R>(v: R): Extern<ArkTS> { ... }

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

## Extension: direct typed evaluation

An immediately converted expression currently crosses the runtime twice:

```cangjie
let name = T.fromExtern<String>(
    T.eval(MemberAccess(Value(blob), "name")))
```

Add a typed entry point so the runtime can evaluate and convert in one operation:

```cangjie
public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    ...

    static func evalAs<R>(t: ExternExpTree<T>): R {
        fromExtern<R>(eval(t)) // compatibility fallback
    }
}
```

An optimized runtime overrides the fallback:

```cangjie
public static func evalAs<R>(tree: ExternExpTree<ArkTS>): R {
    run { fromJSValue<R>(evalTree(tree)) }
}

// (String)blob.name
// → ArkTS.evalAs<String>(MemberAccess(Value(blob), "name"))
```

This uses one dispatch and one scope, and avoids retaining a foreign result that is
immediately converted to a Cangjie value. The same extension applies when `Extern<T>` is
the tree by changing the parameter type of `evalAs` to `Extern<T>`.

# Architecture Document for the Cangjie Extern Type

This document describes the interoperability architecture for the proposal linked [here](https://github.com/danghica/interop/blob/main/The%20Cangjie%20Extern%20type.md).

## Overall Architecture

### What We Provide

The following types can be defined in a library/package or provided as a compiler built-in.

#### `Runtime` interface

`Runtime`, defined below, specifies the interface that language-specific interoperability providers must implement.

```cangjie
public interface Runtime<T> where T <: Runtime<T> {
    static func evalMemberAccess(e: Extern<T>, field: String)            : Extern<T>
    static func evalFunctionCall(e: Extern<T>, args: Array<Any>)         : Extern<T>
    static func evalIndexAccess (e: Extern<T>, arg: Any)                 : Extern<T>
    static func evalAssignment  (e: Extern<T>, field: String, value: Any): Unit

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}
```

#### `Extern` type

The `Extern` used above to represent interoperability language specific values can be defined in different ways.

##### Option 1: struct with Handle of type `Int64`

This is probably the most compact way.

```cangjie
public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let content : Int64) { }
}
```

##### Option 2: struct with Handle of type `Any`

This is more versatile than `Option 1` but still fixes the representation.

```cangjie
public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let content : Any) { }
}
```

A concrete example can be found [here](https://github.com/belolourenco/cangjie_interop_architecture/blob/main/examples/prototype_deveco_1/CangjieInterop/entry/src/main/cangjie/Extern/extern.cj).

##### Option 3: interface

This is the most versatile way, it's totally up to the runtime implementer how to represent `Extern` values.

```cangjie
public interface Extern<T> where T <: Runtime<T> {}
```

A concrete example can be found [here](https://github.com/belolourenco/cangjie_interop_architecture/blob/extern_interface/examples/prototype_deveco_1/CangjieInterop/entry/src/main/cangjie/Extern/extern.cj).

### What a Language-Specific Interoperability Provider Writes

To provide interoperability support for a new programming language, the implementer should provide a class that implements `Runtime<T>`. Below is a minimal example for a hypothetical Python Runtime.

```cangjie
public class PythonRT <: Runtime<PythonRT> {
    public static func evalMemberAccess(e: Extern<PythonRT>, field: String): Extern<PythonRT> { ... }
    public static func evalFunctionCall(e: Extern<PythonRT>, args: Array<Any>): Extern<PythonRT> { ... }
    public static func evalIndexAccess (e: Extern<PythonRT>, arg: Any): Extern<PythonRT> { ... }
    public static func evalAssignment  (e: Extern<PythonRT>, field: String, value: Any): Unit { ... }

    public static func fromExtern<R>(h: Extern<PythonRT>): R { ... }
    public static func toExtern<R>(v: R): Extern<PythonRT> { ... }
}
```

The interoperability provider is free to implement this in any way it chooses, as long as it implements `Runtime<Python>`.

If we define `Extern` as in Option 3 above, we also need to define a type that implements `Extern<Runtime<T>>`. E.e. 

```cangjie
private struct PythonExtern <: Extern<PythonRT> {
    ...
    public PythonExtern(...) { ... }
}
```

A concrete example can be found [here](https://github.com/belolourenco/cangjie_interop_architecture/blob/extern_interface/examples/prototype_deveco_1/CangjieInterop/entry/src/main/cangjie/ArkTSRuntime/arkTSRuntime.cj).

### What the User Writes

Once `ExternalVM`s are defined, users can rely on them to interoperate with other languages. Below are some examples, with comments explaining how each line should be interpreted.

```cangjie
let x: Extern<PythonRT> = 42
// => let x: Extern<PythonRT> = PythonRT.toExtern(42)

func foo(e1: Extern<PythonRT>) {
    let s: String = e1
    // => let s: String = PythonRT.fromExtern<String>(x)

    let e2: Extern<PythonRT> = e1
    // normal Cangjie semantics

    var e3: Extern<PythonRT>
    e3 = e2
    // normal Cangjie semantics
}

func bar(e1: Extern<PythonRT>, e2: Extern<PythonRT>) {
    let x: Int64 = e1.a.b.c
    // =>
    // let x: Int64 =
    // PythonRT.evalMemberAccess(PythonRT.evalMemberAccess(
    //      PythonRT.evalMemberAccess(e1, "a"), "b"), "c")

    e1.a.b.c  = 101
    // =>
    // PythonRT.evalAssignment(PythonRt.evalMemberAccess(PythonRT.evalMemberAccess(e1, "a"), "b"), "c", 101)

    e1.a = e2
    // =>
    // PythonRT.evalAssignment(e1, "a", e2)

    e1.a.d[42]
    // =>
    // PythonRT.evalIndexAccess(PythonRT.evalMemberAccess(PythonRT.evalMemberAccess(e1, "a"), "d"), 42)

    let e2 = e1.x.y()
    // =>
    // let tmp = PythonRT.evalMemberAccess(PythonRT.evalMemberAccess(e1, "x"), "y")
    // let e2: Extern<PythonRT> = PythonRT.evalFunctionCall(tmp, [])

    let e3 = e1.z(x, e2)
    // =>
    // let tmp2 = PythonRT.evalMemberAccess(e1, "z")
    // let e3: Extern<PythonRT> = PytonRT.evalFunctionCall(tmp2, [x, e2])
}
```

## Tasks

1. Provide a library or add compiler built-in support for `Extern`, and `Runtime`.
    - This might require compiler support is Extern is built-in.
2. Program transformations (e.g. `let s: String = x` => `let s: String = PythonRT.fromExtern<String>(x)`)
    - This may be possible to implement with compiler/CHIR plugins.
4. Prototypes Runtimes implementations for specific programming languages:
    - ArkTS (https://github.com/belolourenco/cangjie_interop_architecture/tree/main/examples/prototype_deveco_1/CangjieInterop)
    - Lua
    - Python


## WIP: Type Checking and Program transformations

Let `e1, e2: Extern<T>`.

The following expressions type-check and are transformed as indicated in the comments:

```cangjie
let s: String = e1
// => let s: String = T.fromExtern<String>(e1)

var t: String = e1
// => var t: String = T.fromExtern<String>(e1)

var e3 = e1
e3 = e2
// Type check ok, no transformations!

e3 = "Hello"
// => e3 = T.toExtern("Hello)

let x = e1.f1.f2.f3
// => let x = T.evalMemberAccess(T.evalMemberAccess(T.evalMemberAccess(e1, "r1"), "f2"), "f3")

e1("hello world")
// => T.evalFunctionCall(e1, ["hello world"])

e1.f1.f2 = "boo"
// => T.evalAssignment(T.evalMemberAccess(e1, "f1"), "f2", "boo")

let y = e1.foo("goo")
// => let y: Extern<T> = T.evalFunctionCall(T.evalMemberAccess(e1, "foo"), ["goo"])

e1.goo = 42
// => T.evalAssignment(e1, "goo", 42)

e1.goo[42]
// => T.evalIndexAccess(T.evalMemberAccess(e1, "goo"), 42)

```

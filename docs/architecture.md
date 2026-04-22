# Architecture Document for the Cangjie Extern Type

This document describes the interoperability architecture for the proposal linked [here](https://github.com/danghica/interop/blob/main/cangjie.md).

## Overall Architecture

### What We Provide

The following type can be defined in a library/package or provided as a compiler built-in. Note that `UInt64` is not fixed and needs to be decided later.

```swift
type Handle = UInt64
```

`ExternalVM`, defined below, specifies the interface that language-specific interoperability providers must implement.

```swift
interface ExternalVM {
    func convert<T>(h: Handle) : T
    func update<T>(h: Handle, value: T) : Unit
    func create<T>(value: T) : Handle

    func getGlobal(name: String) : Handle
    func callFunction(handle: Handle, args: Array<Any>) : Handle
    func callMethod(h: Handle, name: String, args: Array<Any>) : Handle
    func setField<T>(h: Handle, name: String, value: T) : Unit
    func getField(h: Handle, name: String) : Handle
}
```

The `Extern` type shown below can be exposed in a library/package or provided as a compiler built-in type.

```swift
struct Extern {
    let ctx : ExternalVM
    let handle : Handle
}
```

Summary:
- `Handle` is exposed to the user or provided as a built-in
- `ExternalVM` is exposed to the user
- `Extern` is exposed to the user or provided as a built-in

### What a Language-Specific Interoperability Provider Writes

To provide interoperability support for a new programming language, the implementer should provide a class that implements `ExternalVM`. Below is a minimal example for a hypothetical Python VM.

```swift
class PythonVM <: ExternalVM {
    public init () { ... }
    public func convert<T>(h: Handle) : T { ... }
    public func update<T>(h: Handle, value: T) : Unit { ... }
    public func create<T>(value: T) : Handle { ... }

    public func getGlobal(name: String) : Handle : Handle { ... }
    public func callFunction(handle: Handle, args: Array<Any>) : Handle { ... }

    public func callMethod(h: Handle, name: String, args: Array<Any>) : Handle { ... }
    public func setField<T>(h: Handle, name: String, value: T) : Unit { ... }
    public func getField(h: Handle, name: String) : Handle { ... }
}
```

The interoperability provider is free to implement this in any way it chooses, as long as it satisfies `ExternalVM`.

### What the User Writes

Once `ExternalVM`s are defined, users can rely on them to interoperate with other languages. Below are some examples, with comments explaining how each line should be interpreted.

```swift
let vm = PythonVM()

func foo(x: Extern) {

    let s: String = x
    // => let s: String = x.ctx.convert<String>(x.handle)

    x = "Hello"
    // => x.ctx.update(x.handle, "Hello")
}

foo("world" @ vm)                 // example syntax
// => foo(vm.create("world"))
```

## Tasks

1. Provide a library or add compiler built-in support for `Handle`, `Extern`, `ExternalVM`.
    - This might require compiler support.
2. Parsing (optional, if we want to support new syntax such as `"world" @ vm`) and type checking (e.g. `let s: String = x` should be accepted when `x: Extern`).
    - This requires compiler support.
3. Program transformations (e.g. `let s: String = x` => `let s: String = x.ctx.convert<String>(x.handle)`)
    - This may be possible to implement with compiler/CHIR plugins.

Additionally, we might want to provide a proof-of-concept implementation of `ExternalVM` for a specific programming language (e.g. ArkTS):

4. Provide a proof-of-concept interoperability implementation for a specific programming language.


## Type Checking and Program transformations

Let `e1, e2: Extern`, `PythonVM <: ExternalVM`. The following expressions type-check and are transformed as indicated in the comments:

```swift
let s: String = e1
// => let s: String = e1.ctx.convert<String>(e1.handle)

e1 = "Hello"
// => e1.ctx.update(e1.handle, "Hello")

e1 = e2
// => if (refEq(e1.ctx, e2.ctx)) {
//      e1.ctx.update(e1.handle, e2.handle) )
//    } else {
//      throw InvalidAssignmentException
//    }

let vm = PythonVM()
let f : External = vm.getGlobal("f")
f("hello world")
// => f.ctx.callFunction(f.handle, "hello world")

let x = e1.f1.f2.f3
// => let x = e1.ctx.getField(e1.ctx.getField(e1.ctx.getField(e1.handle, "f1"), "f2"), "f3")

e1.f1.f2 = "boo"
// => e1.ctx.update(e1.ctx.getField(e1.ctx.getField(e1.handle, "f1"), "f2"), "boo")
// or,
// => e1.ctx.setField(e1.ctx.getField(e1.handle, "f1"), "f2", "boo")

let y = e1.foo("goo")
// => e1.ctx.callMethod(e1.handle, "foo", ["goo"])
```


To be discussed: is `let x: Extern = ...` the same as `var x: Extern = ...`?
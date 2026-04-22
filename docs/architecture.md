# Architecture document for Cangjie Extern type

This document exposes the interoperability implementation architecture for the proposal in [here](https://github.com/danghica/interop/blob/main/cangjie.md).

## Overall Architecture

### We provide

The following type can be defined (e.g. library/package) or compiler built-in.

```swift
type Handle = UInt64
```

`ExternalVM` below, defined the interface that language specific interp-providers must implement.

```swift
interface ExternalVM {
    func convert<T>(h: Handle) : T
    func update<T>(h: Handle, value: T) : Unit
    func create<T>(value: T) : Handle

    func callMethod(h: Handle, name: String, args: Array<Any>) : Handle
    func setField<T>(h: Handle, name: String, value: T): Unit
    func getField(h: Handle, name: String)
}
```

`Extern` type below can be exposed as shown below (e.g. in a library/package) or else be a compiler built-in type.

```swift
struct Extern {
    let ctx : ExternalVM
    let handle : Handle
}
```

Summary:
- `Handle` exposed to the user or built-in
- `ExternalVM` exposed to the user
- `Extern` exposed to the user or built-in

### The specific language interoperability-provider writes

To provide interoperability support for a new programming language, the implementor should provide a class that implements `ExternalVM`. E.g. below we provide a minimal example for a hypothetical Python VM.

```swift
class PythonVM <: ExternalVM {
    public init () { ... }
    public func convert<T>(h: Handle) : T { ... }
    public func update<T>(h: Handle, value: T) : Unit { ... }
    public func create<T>(value: T) : Handle { ... }

    public func callMethod(h: Handle, name: String, args: Array<Any>) : Handle { ... }
    public func setField<T>(h: Handle, name: String, value: T): Unit { ... }
    public func getField(h: Handle, name: String) { ... }
}
```

The interoperability-provider is free to do anything as long as it implements `ExternalVM`.

### The user writes

Once `ExternalVM`s are defined, the user can resort to them to interoperate with other languages. Below we show some examples with comments how each line should be interpreted.

```swift
let vm = PythonVM()

func foo(x: Extern) {

    let s: String = x
    // => let s: String = x.convert<String>(x.handle)

    x = "Hello"
    // => x.update(x.handle, "Hello")
}

foo("world" @ vm)                 // syntax example
// => foo(vm.create("world"))
```

## Tasks

1. Provide a library or add compiler built-in support for `Handle`, `Extern`, `ExternalVM`.
    - might need compiler support
2. Parsing (optional, if we want to support new syntax like `"world" @ vm`) + type checking (e.g. `let s: String = x` should be accepted when `x: Extern`).
    - need compiler support
3. Program transformations (e.g. `let s: String = x` => `let s: String = x.convert<String>(x.handle)`)
    - possible to implement with the compiler/CHIR plugins

Additionally we might need to provide a proof-of-concept implementation of `ExternalVM` (e.g. ArkTS)
4. Proof-of-concept interoperability implementation for a specific programming language
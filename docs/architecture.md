# Architecture Document for the Cangjie Extern Type

This document describes the interoperability architecture for the proposal linked [here](https://github.com/danghica/interop/blob/main/The%20Cangjie%20Extern%20type.md).

## Overall Architecture

### Changes to `std.core`

The following types are to be defined in a new file `extern_runtime.cj` to be part of the `std.core` library.

#### `Runtime` interface

`Runtime`, defined below, specifies the interface that language-specific interoperability providers must implement.

```cangjie
public interface Runtime<T> where T <: Runtime<T> {
    static func memberAccess(e: Extern<T>, field: String)              : Extern<T>
    static func functionCall(e: Extern<T>, args: Array<Any>)           : Extern<T>
    static func indexAccess (e: Extern<T>, index: Any)                 : Extern<T>

    static func memberUpdate(e: Extern<T>, field: String, value: Any)  : Unit
    static func indexAccessUpdate(e: Extern<T>, index: Any, value: Any): Unit

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}
```

#### `Extern` type

`Extern<T>`, defined below, is a wrapper around the value the Runtime<T> implementer wants to use as a handle for the foreign runtime.

```cangjie
public struct Extern<T> where T <: Runtime<T> {
    private let payload : Any
    public Extern(payload: Any) {
        this.payload = payload
    }
}

@Intrinsic
public func getPayload<T>(e: Extern<T>): Any where T<: Runtime<T>
```

The intrinsic function `getPayload` returns the payload of the `Extern` value. It's implementation is defined within the compiler and can be seen as `return e.payload`. It is used to disambiguate the dynamic field access of the form `e.payload`, for some `e: Extern<T>`.

#### Predefined Exceptions

```cangjie
// MemberAccessException thrown if an attempt is made to access or update a non-existing member
public class MemberAccessException <: Exception {
    public ExternDynamicException(message: String) {
        super(message)
    }
}

// FunctionAccessException thrown if an attempt is made to access a non-existing function
public class FunctionAccessException <: Exception {
    public FunctionAccessException(message: String) {
        super(message)
    }
}

// FunctionCallException thrown if an attempt is made to call a function with the wrong arguments
public class FunctionCallException <: Exception {
    public FunctionCallException(message: String) {
        super(message)
    }
}

// IndexAccessException thrown if an attempt is made to access or update with the wrong index, including out-of-bounds errors
public class IndexAccessException <: Exception {
    public IndexAccessException(message: String) {
        super(message)
    }
}

// ExternDynamicException thrown if a function in the foreign runtime throws a runtime exception
public class ExternDynamicException <: Exception {
    public ExternDynamicException(message: String) {
        super(message)
    }
}

// ExternConversionException thrown if data cannot be converted to or from an Extern type as required.
public class ExternConversionException <: Exception {
    public ExternConversionException(message: String) {
        super(message)
    }
}
```

### Changes to the compiler

The compiler needs to be modified to support the new forced cast, the intrinsic function `getPayload`, the type checking of `Extern` expressions and the program transformations.

#### Forced cast

The forced cast `(U)e` is a new feature that allows the user to convert an `Extern<T>` value to a specific type `U`. It is desugared to `T.fromExtern<U>(e)`. Parsing support for the forced cast should be added to the compiler taking into account the parsing disambiguation discussed in [here](https://titanium.cs.berkeley.edu/doc/java-langspec-1.0/19.doc.html#44559). 

The compiler should also perform type checking and desugaring on the forced cast. We defer the details to the type checking and program transformations sections below.

#### New intrinsic function `getPayload`

The intrinsic function `getPayload` is a new feature that allows the user to get the payload of an `Extern<T>` value. 

It is implemented internally in the compiler as:

```cangjie
public func getPayload<T>(e: Extern<T>): Any where T<: Runtime<T> {
    return e.payload
}
```

#### Type checking

##### Type checking of `(U)e`

The type checking of `(U)e` should be performed as follows:

1. If type of `e` is `Extern<T>` for some `T`, then succeed!
3. If type if `e` is not `Extern<T>` for some `T`, then fail!

##### Type checking when `Extern<T>` is expected

The type checking of `e` when `Extern<T>` is expected should always succeed no matter the type of `e`.

> *Intuition*: if `e` is of type `U` with `U != T`, then `e` should be desugared to `Extern<T>` using `T.toExtern<U>(e)`.

##### Type checking of `e.f`, `e[i]`, `e(e1, ..., en)`

The type of `e.f`, `e[i]`, `e(e1, ..., en)` when `e` is of type `Extern<T>` is `Extern<T>`.

No check needs to be performed on the type of `f`, `i`, `e1`, ..., `en`.

##### Type checking of `e.f = e1`, `e[i] = e2`

The type of `e.f = e1`, `e[i] = e2` when `e` is of type `Extern<T>` is `Unit`.

No check needs to be performed on the type of `f`, `i`, `e1`, `e2`.

#### Program transformations

##### Desugaring of `(U)e`

If `(U)e` has type `Extern<T>` for some `T`, then desugar to `T.fromExtern<U>(e)`.

##### Desugaring of `e` when `Extern<T>` is expected

If `e` is of type `U` with `U != T`, then desugar to `T.toExtern<U>(e)`.

##### Desugaring of `e.f`, `e[i]`, `e(e1, ..., en)`

If `e` is of type `Extern<T>`, then

- `e.f` should be desugared to `T.memberAccess(e, f)`,
- `e[i]` should be desugared to `T.indexAccess(e, i)`,
- `e(e1, ..., en)` should be desugared to `T.functionCall(e, [e1, ..., en])`.

##### Desugaring of `e.f = e1`, `e[i] = e2`

If `e` is of type `Extern<T>`, then
- `e.f = e1` should be desugared to `T.memberUpdate(e, f, e1)`,
- `e[i] = e2` should be desugared to `T.indexAccessUpdate(e, i, e2)`.

### Foreign Runtime Implementer

The implementer of a foreign runtime should provide a class that implements `Runtime<T>`. Below is a minimal example for a hypothetical Python foreign runtime.

```cangjie
public class PythonRT <: Runtime<PythonRT> {
    static func memberAccess(e: Extern<PythonRT>, field: String): Extern<PythonRT> { ... }
    static func functionCall(e: Extern<PythonRT>, args: Array<Any>): Extern<PythonRT> { ... }
    static func indexAccess (e: Extern<PythonRT>, index: Any): Extern<PythonRT> { ... }

    static func memberUpdate(e: Extern<PythonRT>, field: String, value: Any): Unit { ... }
    static func indexAccessUpdate(e: Extern<PythonRT>, index: Any, value: Any): Unit { ... }

    static func fromExtern<R>(h: Extern<PythonRT>): R { ... }
    static func toExtern<R>(v: R): Extern<PythonRT> { ... }
}
```

The implementer is free to implement this in any way they choose, as long as it implements `Runtime<PythonRT>`.

In particular, the implementer needs to choose a payload type for the `Extern<PythonRT>` value. This can be as simple as a pointer to a foreign runtime object (e.g. represented by a `Int64`), or as complex as a full-fledged object with fields and methods. The implementer also needs to manage the lifetime of the foreign runtime object, possibly using finalizers.

#### Having multiple foreign runtimes of the same language

It's possible to have multiple versions of the same foreign runtime. One way of achieving is as follows:

```cangjie
public open class PythonRT<T> <: Runtime<T> where T <: PythonRT<T> {
    ...
    // implement the methods of Runtime<PythonRT>
    ...
}

public class PythonRT1 <: PythonRT<PythonRT1> {}
public class PythonRT2 <: PythonRT<PythonRT2> {}
```

### What the User Writes

Once foreign runtimes are defined, users can rely on them to interoperate with other languages. Below are some examples, with comments explaining how each line is dessugared.

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
    // PythonRT.memberAccess(PythonRT.memberAccess(
    //      PythonRT.memberAccess(e1, "a"), "b"), "c")

    e1.a.b.c  = 101
    // =>
    // PythonRT.memberUpdate(PythonRt.memberAccess(PythonRT.memberAccess(e1, "a"), "b"), "c", 101)

    e1.a = e2
    // =>
    // PythonRT.memberUpdate(e1, "a", e2)

    e1.a.d[42]
    // =>
    // PythonRT.indexAccess(PythonRT.memberAccess(PythonRT.memberAccess(e1, "a"), "d"), 42)

    let e2 = e1.x.y()
    // =>
    // let tmp = PythonRT.memberAccess(PythonRT.memberAccess(e1, "x"), "y")
    // let e2: Extern<PythonRT> = PythonRT.functionCall(tmp, [])

    let e3 = e1.z(x, e2)
    // =>
    // let tmp2 = PythonRT.memberAccess(e1, "z")
    // let e3: Extern<PythonRT> = PytonRT.functionCall(tmp2, [x, e2])
}
```

## Implementation

The implementation of the extern runtime support is in [https://github.com/CJPLUK/cangjie_sdk/tree/feature_extern](https://github.com/CJPLUK/cangjie_sdk/tree/feature_extern).

To build the SDK make sure you install the dependencies as in [here](https://gitcode.com/Cangjie/cangjie_build/blob/dev/doc_en/macos.md), and then if you are in macOS run:

```bash
$ export ARCH=aarch64
$ export CELLAR_PATH=/opt/homebrew/Cellar                  # adjust this to your system
$ export PATH=$CELLAR_PATH/llvm@16/16.0.6_1/bin/:$PATH     # adjust this to your system
$ export OPENSSL_PATH=$CELLAR_PATH/openssl@3/3.6.2/lib     # adjust this to your system
$ export LD_LIBRARY_PATH=$OPENSSL_PATH:$LD_LIBRARY_PATH
$ export DYLD_LIBRARY_PATH=$OPENSSL_PATH

$ git clone https://github.com/CJPLUK/cangjie_sdk.git -b feature_extern
$ cd cangjie_sdk
$ git submodule update --init
$ bash ./build_scripts/macos/all.sh --bundle-with-links
$ source software/cangjie/envsetup.sh
```

After the commands above, the following command should work and output the `cjc` and `cjpm` versions:

```bash
$ cjc --version
$ cjpm --version
```

If you modify the compiler you need to run `bash ./build_scripts/macos/compiler.sh`.

If you modify the standard library you need to run `bash ./build_scripts/macos/stdlib.sh`.


The tests for the project are in `cangjie_test/testsuites/LLT/Runtime/CJNative/extern/`. To run the tests, run:

```bash
$ python3 cangjie_test_framework/main.py --test_cfg=cangjie_test/testsuites/LLT/configs/cjnative/cjnative_test.cfg -pFAIL -j20 --test_list=cangjie_test/testsuites/LLT/extern_testlist cangjie_test/testsuites/LLT/
```

------------------------------------------------------------------------------------------------

# WIP: old stuff!

Let `e1, e2: Extern<T>`.

The following expressions type-check and are transformed as indicated in the comments:

```cangjie
let s: String = (String)e1
// => let s: String = T.fromExtern<String>(e1)

var t: String = (String)e1
// => var t: String = T.fromExtern<String>(e1)

var e3 = e1
e3 = e2
// Type check ok, no transformations!

e3 = "Hello"
// => e3 = T.toExtern("Hello)

let x = e1.f1.f2.f3
// => let x = T.memberAccess(T.memberAccess(T.memberAccess(e1, "r1"), "f2"), "f3")

e1("hello world")
// => T.functionCall(e1, ["hello world"])

e1.f1.f2 = "boo"
// => T.memberUpdate(T.memberAccess(e1, "f1"), "f2", "boo")

let y = e1.foo("goo")
// => let y: Extern<T> = T.functionCall(T.memberAccess(e1, "foo"), ["goo"])

e1.goo = 42
// => T.memberUpdate(e1, "goo", 42)

e1.goo[42]
// => T.indexAccess(T.memberAccess(e1, "goo"), 42)

e1.goo[10] = 42
// => T.indexAccessUpdate(T.memberAccess(e1, "goo"), 10, 42)
```

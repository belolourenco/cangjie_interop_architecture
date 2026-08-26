# ArkTS foreign runtime

This document specifies a generic `ArkTS<T>` foreign-runtime abstraction for accessing
ArkTS/JS values from Cangjie.

**Background.** `Extern<T>` represents either an evaluated value in a *foreign memory
space* or a deferred operation on such a value. It is a recursive enum whose leaf is
`Payload(Any)` and whose other variants describe member access, indexed access, updates,
and calls. The compiler builds these trees from dynamic syntax and passes them to
`T.eval`. The type parameter `T` implements `ForeignRuntime<T>`; `ArkTS<T>` supplies the
ArkTS implementation for concrete, self-typed runtime classes.

Version 1 uses `ohos.ark_interop` as its backend. A later version will replace that backend
with direct Cangjie FFI bindings to OpenHarmony’s native `ARKTS_*` interface.

A prototype of this design is available
[TODO]().

---

## 1. Layering

User-facing dynamic syntax on `Extern<T>` never calls the VM directly. The compiler builds
an `Extern<T>` expression tree and passes it to `T.eval`. `ArkTS<T>` evaluates the complete
tree through the thread-safe `run` wrapper and stores evaluated values as an internal
`ArkTSHandle` inside `Payload`. This version goes through `ohos.ark_interop`; later versions
may call the `ARKTS_*` FFI directly.

```cangjie
public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func eval(tree: Extern<T>): Extern<T>
    static func fromExtern<R>(value: Extern<T>): R
    static func toExtern<R>(value: R): Extern<T>
}
```

```mermaid
flowchart TB
    UC["User: e.f / e(...) / e[i]"] --> DS["cjc builds Extern tree"]
    DS --> EVAL["T.eval(tree)"]
    EVAL --> ARK["ArkTS&lt;T&gt; <: ForeignRuntime&lt;T&gt;"]
    ARK --> PAY["Payload(ArkTSHandle: Imm | Ref)"]
    ARK --> RUN["run: JS-thread dispatch"]
    ARK -->|"v1"| CTX["ohos.ark_interop"] --> FFI["ARKTS_*"] --> VM["ArkTS VM"]
    ARK -.->|"v2"| FFI
```

```cangjie
ArkTS.bind(context)                  // bind this runtime instance at entry

// ...

let api: Extern<ArkTS> = ArkTS.requireArkModule("test.ets")
let blob = api.createRectangle()
blob.width = 3.0
let a: Float64 = (Float64)blob.area()
```

The compiler lowers the dynamic operations as follows:

```cangjie
let blob = ArkTS.eval(
    FuncCall(MemberAccess(api, "createRectangle"), []))

ArkTS.eval(MemberUpdate(blob, "width", 3.0))

let a: Float64 = ArkTS.fromExtern<Float64>(
    ArkTS.eval(FuncCall(MemberAccess(blob, "area"), [])))
```

The assigned `3.0` remains an `Any` operand in the tree and is converted by the ArkTS
evaluator when it performs the update.

---

## 2. Context

`ArkTS<T>` is an abstract generic base class whose type parameter identifies a concrete
ArkTS runtime.

`JSContext` is the `ark_interop` handle to one ArkTS/JS engine instance. Each concrete
specialization can be bound to its own context. This permits multiple ArkTS foreign
runtimes, such as `ArkTS1 <: ArkTS<ArkTS1>` and `ArkTS2 <: ArkTS<ArkTS2>`, without mixing
their values: `Extern<ArkTS1>` and `Extern<ArkTS2>` are different types. `bind` installs
the context for that specialization. The evaluator and helpers read it through the private
`context` property, which throws if the runtime was never bound.

```cangjie
abstract open public class ArkTS<T> <: ForeignRuntime<T> where T <: ArkTS<T> {
    private static var context_: ?JSContext = None

    public static func bind(context: JSContext): Unit {
        context_ = context
    }

    private static prop context: JSContext {
        get() {
            match (context_) {
                case Some(context) => context
                case None => throw Exception("ArkTS is not associated with a host JSContext")
            }
        }
    }
}
```

Concrete runtime specializations subclass `ArkTS<T>`:

```cangjie
internal class ArkTS1 <: ArkTS<ArkTS1> {}
internal class ArkTS2 <: ArkTS<ArkTS2> {}
```

Each specialization can then be bound to its own context:

```cangjie
ArkTS1.bind(context1)
ArkTS2.bind(context2)
```

---

## 3. Thread dispatch

ArkTS FFI is *bind-thread-affine*: engine calls are valid only on the thread that bound the
context (the JS thread). Each `eval` call and public helper therefore runs its engine work
inside `run`, which looks synchronous to the caller regardless of which Cangjie thread
called it. Recursive evaluation stays inside that single `run` invocation.

If `run` is called on the bind thread, it executes the operation directly, as in `(a)`
below. Otherwise, it posts the operation to the JS thread and blocks the caller until the
result is available, as in `(b)`.

```cangjie
private static func run<R>(operation: () -> R): R {
    if (context.isInBindThread()) {
        return operation()                       // (a) already on JS thread: run inline
    }

    // (b) other thread: hand the work to the JS thread and block for its result
    let result = Box(None<ArkTSResult<R>>)
    let mutex = Mutex()
    let done: Condition
    synchronized(mutex) {
        done = mutex.condition()
    }

    context.postJSTask {
        let completed: ArkTSResult<R> =
            try {
                ArkTSResult.Ok(operation())
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
            case Ok(value) => value              // return the JS-thread value, or...
            case Err(error) => throw error       // ...rethrow the JS-thread exception here
        }
    }
}
```

Two cases:

- **(a) On the bind thread** — call `operation()` directly.
- **(b) Off the bind thread** — post `operation` with `postJSTask`, wait on a
  `Mutex`/`Condition`, then return its value or rethrow its exception. `ArkTSResult<R>` is
  the internal `Ok(R) | Err(Exception)` carrier used to move the outcome across threads.

---

## 4. Handle model

`Extern<T>` is the expression tree defined by the standard library:

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

For `T <: ArkTS<T>`, an evaluated `Extern<T>` is a `Payload` containing an
`ArkTSHandle`:

```cangjie
private enum ArkTSHandle {
    | Imm(JSValue)      // undefined / null / boolean / number
    | Ref(JSHeapObject) // string / bigint / symbol / object / array / function / ...
}
```

| Variant | Holds | Why |
| --- | --- | --- |
| `Imm` | a `JSValue` | Immediates have no heap identity, so the value is stored as-is. |
| `Ref` | a `JSHeapObject` | Heap values are pinned as a process-global so they survive across calls. |

`JSValue` is `ark_interop`'s tagged engine value: either an immediate or a pointer into the
heap. Three helpers move between an evaluated `Extern`, its handle, and a `JSValue`:

```cangjie
// Evaluated Extern<T> -> ArkTSHandle.
private static func getHandle(e: Extern<T>): ArkTSHandle {
    match (e) {
        case Payload(payload) => (payload as ArkTSHandle).getOrThrow()
        case _ => throw Exception("Expected an evaluated ArkTS value")
    }
}

// ArkTSHandle -> evaluated Extern<T>.
private static func extern(handle: ArkTSHandle): Extern<T> {
    Payload(handle)
}

// ArkTSHandle -> JSValue.
private static func jsValue(handle: ArkTSHandle): JSValue {
    match (handle) {
        case Imm(value) => value
        case Ref(owner) => owner.toJSValue()
    }
}
```

### Wrapping a JSValue as an Extern

`retain` is the single entry that turns a `JSValue` produced by the engine into an
evaluated `Extern`. It inspects the runtime type, promotes heap values to global handles,
and wraps the resulting `ArkTSHandle` in `Payload`.

```cangjie
private static func retain(value: JSValue): Extern<T> {
    if (value.isFunction()) { return extern(Ref(value.asFunction())) }
    if (value.isArray())   { return extern(Ref(value.asArray()))  }
    if (value.isSymbol())  { return extern(Ref(value.asSymbol())) }
    if (value.isString())  { return extern(Ref(value.asString())) }
    if (value.isBigInt())  { return extern(Ref(value.asBigInt())) }
    if (value.isObject())  { return extern(Ref(value.asObject())) }
    extern(Imm(value))     // undefined / null / boolean / number: engine immediates
}
```

Heap values are made global only when `retain` produces the final result of an evaluation
or helper call. Intermediate values remain local to the evaluation. This lets users keep
evaluated `Extern` values without manually retaining them through operations such as
`value.asObject()`.

---

## 5. Dynamic operations

The compiler represents dynamic syntax as nested `Extern<T>` nodes and calls `T.eval` once
for the complete expression:

```cangjie
e.f       → T.eval(MemberAccess(e, "f"))
e[i]      → T.eval(IndexedAccess(e, i))
e.f = v   → T.eval(MemberUpdate(e, "f", v))
e[i] = v  → T.eval(IndexedUpdate(e, i, v))
e(a, b)   → T.eval(FuncCall(e, [a, b]))

a.b.c     → T.eval(MemberAccess(MemberAccess(a, "b"), "c"))
a.m(10)   → T.eval(FuncCall(MemberAccess(a, "m"), [10]))
```

Constructing the tree performs no engine work. `eval` enters `run` once, recursively
reduces the tree to a local `JSValue`, and retains only the result. An existing `Payload`
is already evaluated and can be returned unchanged.

```cangjie
public static func eval(tree: Extern<T>): Extern<T> {
    match (tree) {
        case Payload(_) => tree
        case _ => run { retain(evalTree(tree)) }
    }
}

private static func evalTree(tree: Extern<T>): JSValue {
    match (tree) {
        case Payload(_) => jsValue(getHandle(tree))
        case MemberAccess(target, field) =>
            evalTree(target).getProperty(field)
        case IndexedAccess(target, index) =>
            readIndex(evalTree(target), index)
        case MemberUpdate(target, field, value) =>
            evalTree(target).setProperty(field, toJSValue(value))
            context.undefined().toJSValue()
        case IndexedUpdate(target, index, value) =>
            writeIndex(evalTree(target), index, toJSValue(value))
            context.undefined().toJSValue()
        case FuncCall(callee, arguments) =>
            call(callee, arguments)
    }
}
```

### Indexed access

Index operations accept an integer position, a `String` property name, or an `Extern<T>`
from the same runtime. The `Extern<T>` case is evaluated within the current tree rather
than retained as a separate intermediate result.

```cangjie
private static func readIndex(target: JSValue, index: Any): JSValue {
    match (index) {
        case position: Int64 => target.getElement(position)
        case position: Int32 => target.getElement(Int64(position))
        case propertyName: String => target.getProperty(propertyName)
        case externalIndex: Extern<T> =>
            // Access using evalTree(externalIndex).
        case _ => throw Exception("Unsupported ArkTS index type")
    }
}

private static func writeIndex(target: JSValue, index: Any, value: JSValue): Unit {
    match (index) {
        case position: Int64 => target.setElement(position, value)
        case position: Int32 => target.setElement(Int64(position), value)
        case propertyName: String => target.setProperty(propertyName, value)
        case externalIndex: Extern<T> =>
            // Update using evalTree(externalIndex).
        case _ => throw Exception("Unsupported ArkTS index type")
    }
}
```

### Calls and receivers

The call tree retains the distinction between a member call and a call through an already
evaluated function. `call` uses the target of a `MemberAccess` or `IndexedAccess` as
`this`; every other callee receives `undefined`. The target is evaluated exactly once.

```cangjie
a.m(10)           // FuncCall(MemberAccess(a, "m"), [10]): this = a
let x = a.m
x(20)             // FuncCall(x, [20]): this = undefined
```

```cangjie
private static func call(callee: Extern<T>, arguments: Array<Any>): JSValue {
    match (callee) {
        case MemberAccess(receiver, field) =>
            let target = evalTree(receiver)
            let function = target.getProperty(field).asFunction()
            let converted = Array<JSValue>(arguments.size) { index =>
                toJSValue(arguments[index])
            }
            function.call(converted, thisArg: target)
        case IndexedAccess(receiver, index) =>
            let target = evalTree(receiver)
            let function = readIndex(target, index).asFunction()
            let converted = Array<JSValue>(arguments.size) { i =>
                toJSValue(arguments[i])
            }
            function.call(converted, thisArg: target)
        case _ =>
            let function = evalTree(callee).asFunction()
            let converted = Array<JSValue>(arguments.size) { index =>
                toJSValue(arguments[index])
            }
            function.call(converted, thisArg: context.undefined().toJSValue())
    }
}
```

Example flow for `obj.m(10)`:

```mermaid
sequenceDiagram
    participant U as User
    participant A as ArkTS<T>
    participant O as ark_interop
    U->>A: eval(FuncCall(MemberAccess(obj,"m"),[10]))
    A->>O: evaluate obj once
    A->>O: obj.getProperty("m")
    A->>O: m.call([10], thisArg:obj)
    A-->>U: retain(result)
```

---

## 6. Conversions

Language rules from the `Extern` design remain unchanged: a Cangjie value used where
`Extern<T>` is expected becomes `T.toExtern`, while a forced cast `(U)e` becomes
`T.fromExtern<U>(e)`. This section covers those hooks and the internal `toJSValue` helper.

### `toJSValue`: Cangjie value → `JSValue`

This bind-thread helper converts assigned values, call arguments, indexes, and values passed
to `toExtern`. If the input is an `Extern<T>`, it may be either a `Payload` or another
expression tree, so `toJSValue` evaluates it within the current scope. Other values are
converted according to their runtime type. The `Imm`/`Ref` decision is deferred to
`retain`.

```cangjie
private static func toJSValue(value: Any): JSValue {
    if (value is Extern<T>) {
        return evalTree((value as Extern<T>).getOrThrow())
    }
    if (value is (Extern<T>) -> Extern<T>) {
        let callback = (value as ((Extern<T>) -> Extern<T>)).getOrThrow()
        return context.function({ _, info =>
            let arguments = Array<JSValue>(info.count) { index => info[index] }
            let externalArguments = retain(context.array(arguments).toJSValue())
            let result = callback(externalArguments)
            evalTree(result)
        }).toJSValue()
    }
    if (value is Bool)    { return context.boolean((value as Bool).getOrThrow()).toJSValue() }
    if (value is Int32)   { return context.number((value as Int32).getOrThrow()).toJSValue() }
    if (value is Int64)   { return context.number(Float64((value as Int64).getOrThrow())).toJSValue() }
    if (value is Float64) { return context.number((value as Float64).getOrThrow()).toJSValue() }
    if (value is String)  { return context.string((value as String).getOrThrow()).toJSValue() }
    if (value is BigInt)  { return context.bigint((value as BigInt).getOrThrow()).toJSValue() }
    if (value is Array<Nothing>)       { return arrayJSValue(Array<Nothing>()) }
    if (value is Array<Int64>)         { return arrayJSValue((value as Array<Int64>).getOrThrow()) }
    if (value is Array<Float64>)       { return arrayJSValue((value as Array<Float64>).getOrThrow()) }
    if (value is Array<Bool>)          { return arrayJSValue((value as Array<Bool>).getOrThrow()) }
    if (value is Array<String>)        { return arrayJSValue((value as Array<String>).getOrThrow()) }
    if (value is Array<Extern<T>>)     { return arrayJSValue((value as Array<Extern<T>>).getOrThrow()) }
    throw Exception("Unsupported conversion to ArkTS")
}
```

Notes:

- An `Extern<T>` from the same concrete runtime is evaluated without retaining an
  intermediate result. An `Extern` belonging to another ArkTS specialization does not
  match this branch.
- A Cangjie callback of type `(Extern<T>) -> Extern<T>` becomes a JS function. On
  invocation, all JS arguments are collected into one array and passed to the callback as
  an evaluated `Extern<T>`. The callback result may itself be a tree and is evaluated
  before being returned to JS. The JS `this` argument is currently ignored.
- `Int64` is widened to `Float64` because JS numbers are doubles.
- Supported arrays are empty `Array<Nothing>` and arrays of `Int64`, `Float64`, `Bool`,
  `String`, or same-runtime `Extern<T>`. `arrayJSValue<E>` maps each element through
  `toJSValue`; other array types are rejected.

### `toExtern`: Cangjie value → `Extern<T>`

The implicit-conversion hook returns an existing `Extern<T>` unchanged, whether it is a
tree or a `Payload`. Other values are converted and retained as evaluated payloads.

```cangjie
public static func toExtern<R>(value: R): Extern<T> {
    if (value is Extern<T>) {
        return (value as Extern<T>).getOrThrow()
    }
    run { retain(toJSValue(value)) }
}
```

### `fromExtern`: `Extern<T>` → Cangjie type `R`

The forced-cast hook `(R)e` receives the evaluated result of the dynamic expression. It
projects the payload to a `JSValue`, then uses the `ark_interop` reader for target type `R`.

```cangjie
public static func fromExtern<R>(e: Extern<T>): R {
    run {
        let value = jsValue(getHandle(e))
        match (None<R>) {    // dummy `None<R>` to match the type parameter
            case _: Option<Bool>    => (value.toBoolean() as R).getOrThrow()
            case _: Option<Int32>   => (Int32(value.toNumber()) as R).getOrThrow()   // read JS number, narrow to Int32
            case _: Option<Int64>   => (Int64(value.toNumber()) as R).getOrThrow()   // read JS number, narrow to Int64
            case _: Option<Float64> => (value.toNumber() as R).getOrThrow()
            case _: Option<String>  => (value.toString() as R).getOrThrow()
            case _: Option<BigInt>  => (value.toBigInt() as R).getOrThrow()
            case _: Option<Unit> => (() as R).getOrThrow()
            case _: Option<Array<String>> =>
                let array = value.asArray()
                let converted = Array<String>(array.size) { index =>
                    array[index].toString()
                }
                (converted as R).getOrThrow()
            case _: Option<Extern<T>> => (e as R).getOrThrow()                       // identity: no conversion
            case _ => throw Exception("Unsupported conversion from ArkTS")
        }
    }
}
```

For `Bool`, `String`, `BigInt`, and `Float64`, the matching reader is called directly.
`Int32` and `Int64` read a JS number and narrow it. Converting to `Unit` discards the value;
converting to `Array<String>` converts each element; and conversion to the same `Extern<T>`
is the identity case. Other target types are rejected.

### Putting it together

```cangjie
let n: Extern<ArkTS1> = 3.0         // toExtern → Payload(Imm(...))
blob.width = n                      // eval(MemberUpdate(...))
let s: String = (String)blob.name   // eval(MemberAccess(...)) → fromExtern<String>
```

---

## 7. Helpers

These ArkTS APIs are not part of the compiler-desugared `ForeignRuntime` surface. They
still use `run` for bind-thread safety and `retain` when returning a foreign value. Helpers
that consume an `Extern<T>` use `evalTree`, so callers may pass either a payload or a tree.

```cangjie
public static func undefined(): Extern<T> { run { retain(context.undefined().toJSValue()) } }
public static func null(): Extern<T>      { run { retain(context.null().toJSValue()) } }
public static func object(): Extern<T>    { run { retain(context.object().toJSValue()) } }
public static func global(): Extern<T>    { run { retain(context.global.toJSValue()) } }
public static func symbol(description!: String = ""): Extern<T> {
    run { retain(context.symbol(description: description).toJSValue()) }
}

public static func strictEqual(lhs: Extern<T>, rhs: Extern<T>): Bool {
    run { evalTree(lhs).strictEqual(evalTree(rhs)) }
}
public static func isNull(value: Extern<T>): Bool      { run { evalTree(value).isNull() } }
public static func isUndefined(value: Extern<T>): Bool { run { evalTree(value).isUndefined() } }

public static func requireSystemNativeModule(moduleName: String): Extern<T> {
    requireSystemNativeModule(moduleName, None)
}

public static func requireSystemNativeModule(
    moduleName: String,
    prefix: ?String
): Extern<T> {
    run { retain(context.requireSystemNativeModule(moduleName, prefix: prefix)) }
}
```

| API | Role |
| --- | --- |
| `undefined()` / `null()` / `object()` / `symbol(...)` | Construct a JS value, then `retain` it. |
| `global()` | Return the context's global object through `retain`. |
| `strictEqual(a, b)` | Evaluate both operands and apply JS `===`. |
| `isNull` / `isUndefined` | Evaluate the operand and test the resulting `JSValue`. |
| `objectHasProperty` / `objectKeys` / `objectDefineOwnProperty` | Object metadata; `defineOwnProperty` converts its value with `toJSValue`. |
| `requireArkModule` | Load an Ark module, then `retain` the result. |
| `requireSystemNativeModule(moduleName)` | Load a system native module without a prefix; delegates to the two-argument overload with `None`. |
| `requireSystemNativeModule(moduleName, prefix)` | Load a system native module with an explicit optional prefix, then `retain` the result. |

---

## 8. Lifetime

One `eval` call uses one engine scope. Values produced while reducing the tree remain local
to that scope; only the final result is passed to `retain`. Consequently, a chain such as
`a.b.c.d` does not create a global handle for each member access.

An evaluated `Payload(Imm(...))` needs no disposal. `Payload(Ref(...))` owns an engine
global and releases it when the payload is finalized. Unevaluated operation nodes own no
additional engine resources, although they may refer to payloads elsewhere in the tree.

| Kind | Storage | Dispose |
| --- | --- | --- |
| Intermediate `JSValue` | evaluation scope | end of `eval` |
| `Imm` | engine immediate | none |
| `Ref` | `JSHeapObject` global | finalizer → `ARKTS_DisposeGlobal` |

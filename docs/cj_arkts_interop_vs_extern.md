# ohos.ark_interop Main Type Relationships

This file summarizes only the main public types shown in the high-level relationship diagram for `ohos.ark_interop`.

## Big Picture

```cangjie
JSRuntime (owns an JS engine)
  -> exposes
     JSContext (creates and checks values for that runtime)
          -> produces
               JSValue (short-lived handle to any ArkTS value)
                    -> can be wrapped as
                         JSUndefined,
                         JSNull,
                         JSBoolean,
                         JSNumber
                    -> can be retained as safe references
                         JSString,
                         JSBigInt,
                         JSSymbol
                         JSObject
                         JSArray,
                         JSArrayBuffer
                         JSFunction,
                         JSClass
                         JSPromise
```

In other words, `JSRuntime` is the runtime owner, `JSContext` is the entry point for interacting with that runtime, and `JSValue` is the generic value crossing the boundary. The named wrapper types make particular ArkTS values easier or safer to use from Cangjie.

## Core Chain

| Type | Source | Relationship |
| --- | --- | --- |
| `JSRuntime` | `js_runtime.cj` | Owns an ArkTS engine and exposes its `mainContext`. |
| `JSContext` | `jscontext.cj` | Belongs to a runtime and creates ArkTS values and references. It also enforces context lifetime and thread affinity. |
| `JSValue` | `js_raw.cj` | The unified ArkTS value wrapper used at call boundaries, property access, and conversions. It is short-lived and tied to a `JSContext`. |

## Primitive Wrappers

These types wrap immediate ArkTS values through an underlying `JSValue`.

| Type | Source | Represents | Created by |
| --- | --- | --- | --- |
| `JSUndefined` | `js_raw.cj` | ArkTS `undefined` | `JSContext.undefined()` |
| `JSNull` | `js_raw.cj` | ArkTS `null` | `JSContext.null()` |
| `JSBoolean` | `js_raw.cj` | ArkTS `boolean` | `JSContext.boolean(Bool)` |
| `JSNumber` | `js_raw.cj` | ArkTS `number` | `JSContext.number(...)` |

Each can be converted back to `JSValue` with `toJSValue()`.

## Safe References

These types are public safe references to ArkTS heap objects. They keep the underlying ArkTS object alive while Cangjie holds the wrapper.

| Type | Source | Relationship |
| --- | --- | --- |
| `JSString` | `jsstring.cj` | Safe reference to an ArkTS string. |
| `JSBigInt` | `js_bigint.cj` | Safe reference to an ArkTS `bigint`. |
| `JSSymbol` | `js_symbol.cj` | Safe reference to an ArkTS `symbol`. |
| `JSObject` | `jsobject.cj` | Safe reference to a plain ArkTS object. |
| `JSArray` | `jsarray.cj` | Safe reference to an ArkTS array. |
| `JSArrayBuffer` | `js_array_buffer.cj` | Safe reference to an ArkTS `ArrayBuffer`. |
| `JSFunction` | `js_func.cj` | Safe reference to an ArkTS functions. |
| `JSClass` | `js_class.cj` | Safe reference to an ArkTS class constructor. |
| `JSPromise` | `js_promise.cj` | Safe reference to an ArkTS `Promise`. |

These references can be converted back to `JSValue` with `toJSValue()`.

## Lifetime Summary

`JSValue` is the short-lived boundary type. When an ArkTS value must be retained beyond the current interop scope, convert it to the appropriate public safe reference, such as `JSObject`, `JSArray`, `JSString`, `JSFunction`, or `JSPromise`.

## Current Interop vs Extern schema

In the Extern schema, Cangjie code uses `Extern<ArkTS>` as the general handle type, and the `ArkTS` runtime implementation provides operations such as member access, function call, index access, conversion, update, and release.

| Current `ohos.ark_interop` type | Extern concept | Comparison |
| --- | --- | --- |
| [`JSRuntime`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsruntime) | `ArkTS` | `JSRuntime` is the concrete owner of an ArkTS engine. In the `Extern` model, `ArkTS <: Runtime<ArkTS>` identifies the foreign runtime and supplies static operations like `toExtern`, `fromExtern`, `functionCall`, `memberAccess`, etc. |
| [`JSContext`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jscontext) | `ArkTS` | Current interop exposes `JSContext` explicitly because value creation and many operations need the ArkTS environment. The `Extern` schema has no public equivalent; the `ArkTS` runtime implementation would likely keep this state internally. |
| [`JSValue`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsvalue) | `Extern<ArkTS>` | `JSValue` is the current general ArkTS value wrapper, but it is short-lived and scope-bound. `Extern<ArkTS>` serves as the language-level general foreign handle, with dynamic member, call, index, and conversion behavior. |
| [`JSUndefined`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsundefined) | `ArkTS.undefined()` | Current interop uses a dedicated wrapper produced by `JSContext.undefined()`. With `Extern<ArkTS>`, the runtime would likely represent ArkTS `undefined` as an ordinary static function `ArkTS.undefined()`. |
| [`JSNull`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsnull) | `ArkTS.null()` | Current interop uses a dedicated wrapper produced by `JSContext.null()`. With `Extern<ArkTS>`, the runtime would likely represent ArkTS `undefined` as an ordinary static function `ArkTS.null()`. |
| [`JSBoolean`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsboolean) | implicit cast from `Bool` to `Extern<ArkTS>` | Current interop requires explicit calls `context.boolean(true)` or `context.boolean(false)`. The `Extern` model uses implicit casts from Cangjie Bool to `Extern<ArkTS>` that are desugared to `ArkTS.toExtern(b)`. |
| [`JSNumber`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsnumber) | implicit conversion from numeric values to `Extern<ArkTS>` | Current interop uses `context.number(n)`. The `Extern` model relies on implicit casts from Cangjie numeric values to `Extern<ArkTS>` that are desugared to `ArkTS.toExtern(n)`. |
| [`JSString`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsstring) | implicit conversion from `String` to `Extern<ArkTS>` | Current interop uses `context.string(s)`. The `Extern` model relies on implicit casts from Cangjie String to `Extern<ArkTS>` that are desugared to `ArkTS.toExtern(s)`. |
| [`JSBigInt`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsbigint) | implicit conversion from `BigInt` to `Extern<ArkTS>` | Current interop uses `context.bigint(n)`. The `Extern` model relies on implicit casts from Cangjie BigInt to `Extern<ArkTS>` that are desugared to `ArkTS.toExtern(n)`. |
| [`JSSymbol`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jssymbol) | `Extern<ArkTS>` | Current interop exposes `JSSymbol` as a safe reference and object key type. The `Extern` model has no special symbol wrapper in the type itself; the ArkTS runtime implementation would own symbol behavior. |
| [`JSObject`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsobject) | `Extern<ArkTS>` | Current interop represents plain ArkTS objects with a dedicated safe reference. In the `Extern` model, this would usually be just an `Extern<ArkTS>` value with dynamic member and index access. |
| [`JSArray`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsarray) | `Extern<ArkTS>` | Current interop uses `JSArray` for length and indexed element operations. The `Extern` proposal describes index access as `e[i]`, with the runtime deciding how to handle the foreign collection. |
| [`JSArrayBuffer`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsarraybuffer) | `Extern<ArkTS>` | The runtime can represent ArkTS binary storage or a typed-array view as an ordinary foreign value. Optimized handling belongs to the ArkTS runtime implementation, not to a separate user-visible Extern type. |
| [`JSFunction`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsfunction) | `Extern<ArkTS>` | Current interop uses `JSFunction.call(...)` and wraps Cangjie callbacks as functions. The `Extern` proposal makes a foreign function handle callable with normal call syntax, desugared to `Runtime.functionCall`. |
| [`JSClass`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jsclass) | `Extern<ArkTS>` | Current interop models ArkTS classes as constructor references with `new(...)` and prototype support. In the `Extern` proposal, constructor calls could be dynamic calls on an external runtime object or class handle. |
| [`JSPromise`](https://github.com/cangjielanguage/cangjiecorpus/blob/1.0.0/ohos/zh-cn/application-dev/reference/arkinterop/cj-apis-ark_interop.md#class-jspromise) | `Extern<ArkTS>` | Current interop provides a dedicated safe reference with `then` and `catchError`. The `Extern` model treats a promise as a foreign value unless the ArkTS runtime layer exposes promise-specific helpers. |

In short, current interop exposes `JSValue` plus public safe-reference wrappers as an explicit hierarchy. The `Extern<ArkTS>` proposal collapses much of that surface into one language-level foreign handle, and runtime-provided dynamic operations and conversions replace many explicit `asX`, `toX`, `getProperty`, `setProperty`, and `call` calls.

# 1. Runtime optimizations

These optimizations can be implemented directly in the runtime and possibly also in ohos.ark_interop

## 1.1. Name resolution caching

typical example: a.x

Description:
The non-optimized approach has to resolve then name 'x' on the object 'a' each time.
This can be cached by the runtime, so that resolution only happens the first time.
This works even for the compound case a.x.y first resolves a.x, if cached, that allows progressing to cached.y.

Issues:
In theory these are javascript objects, and it is possible to dynamically re-bind their fields at runtime. This invalidates the cache. If this ever happens outside of the runtime itself, we'd have a cache inconsistency.

>> This doesn't seem to make much sense to me, other than caching immutable fields. The only thing we can possibly cache is the JSStrings "x" and "y".
>>
>> Note that the following is possible:
>>
>> ```cangjie
>> func testOptimization1(context: JSContext): Unit {
>>     context.newScope {
>>         let object: JSObject = context.object()
>>         let argument = context.number(42).toJSValue()
>> 
>>         object["foo"] = context.function({ ctx, callInfo =>
>>             ctx.number(callInfo[0].toNumber() + 1.0).toJSValue()
>>         }).toJSValue()
>>         let firstResult = object["foo"].asFunction().call(argument).toNumber()
>>         Hilog.info(0, "testOptimization1", "foo(42) after +1 assignment => ${firstResult}")
>> 
>>         object["foo"] = context.function({ ctx, callInfo =>
>>             ctx.number(callInfo[0].toNumber() + 2.0).toJSValue()
>>         }).toJSValue()
>>         let secondResult = object["foo"].asFunction().call(argument).toNumber()
>>         Hilog.info(0, "testOptimization1", "foo(42) after +2 assignment => ${secondResult}")
>>     }
>> }
>> ```

## 1.2. Caching immutable objects

typical example: an extern representing a string in ArkTs is converted in many different places

Description:
Strings are a common immutable type (there may be others, but string is unique for the fact of being both very common, immutable, but not trivial like an int). ArkTs strings and Cangjie strings have different representations, therefore straightforwardly converting between the two is expensive. However, because of immutability, we can cache strings, by storing in the runtime both an ArkTs-representation copy and a Cangjie-representation copy, and use the former to lookup instances of the other.
In principle this idea works for all immutable types that have different representations across the two languages.
Issue: Like all caching, it depends very much on the specifics of the program if this works out well or not.

Also possible to cache object fields if property is both not writable  and not configurable

```cangjie
func printOwnProperties(context: JSContext, object: JSObject) {
    let descriptor = context.global["Object"]
      .asObject()
      .callMethod("getOwnPropertyDescriptor", [
          object.toJSValue(),
          context.string("foo").toJSValue()
      ])
      .asObject()
    let isWritable = descriptor.getProperty("writable").toBoolean()
    Hilog.info(0, "testOptimization3", "descriptor.foo is writable => ${isWritable}")

    let isEnumerable = descriptor.getProperty("enumerable").toBoolean()
    Hilog.info(0, "testOptimization3", "descriptor.foo is enumerable => ${isEnumerable}")

    let isConfigurable = descriptor.getProperty("configurable").toBoolean()
    Hilog.info(0, "testOptimization3", "descriptor.foo is configurable => ${isConfigurable}")
}
```

# 2. Compiler optimizations

These optimizations need support from compiler

## 2.1. Cascaded name resolution

See discussion in [section 3 of the issues](docs/issue_with_current_extern_interface.md) and [the eval proposal](docs/extern_eval_proposal.md).

## 2.2. Scalar replacement for objects translations

typical example: "an extern is cast to a Cangjie object, but then only a field is used"

Description: Converting from Extern to actual Cangjie objects is expensive, because we have to materialize the full object. If the transformation is transparent, ie, the object is converted first but then only a field or two is accessed, the compiler can flip the order of access and translation.

So that let x: T = e; f(x.y) can be rewritten as let y: S = e.y; f(y).

Issue: This kind of scalar replacement can only be done if the objects are accessed in this simple, transparent way. As soon as a method is called, or a non-trivial init constructor is necessary, this optimization does not apply.

>> This same optimization can be applied with constant propagation + eval idea -> `T.eval(FunctionCall(f, [MemberAccess(x, "y")]))`

## 2.3. Loop-array coalescing and caching

### Loop-array coalescing (write)

typical example: filling an ArkTS array from a Cangjie loop, one element at a time

The non-optimized desugaring of `arr[i] = xs[i]` is `T.indexedUpdate(arr, i, xs[i])` on every iteration. If the compiler can see that the loop is just populating the array — contiguous indexes, no reads of `arr` in the body, no other ArkTS calls that could observe a partial write — it can build (or reuse) the Cangjie array and send it in a single `toExtern` / bulk FFI call.

So that

```cangjie
let arr: Extern<ArkTS> = ...
for (i in 0..xs.size) {
    arr[i] = xs[i]
}
```

can be rewritten as `arr` receiving `xs` in one conversion, rather than `xs.size` updates.

Issue: only applies when the loop is a transparent bulk write. Non-contiguous or data-dependent indexes also block it.

### Loop-array caching (read)

typical example: reading every element of an ArkTS array in a Cangjie loop

The dual of coalescing. `(T)arr[i]` is `T.fromExtern<T>(T.indexedAccess(arr, i))` per element. The compiler can hoist one `fromExtern<Array<T>>(arr)` (or equivalent bulk read), then iterate on the Cangjie-side copy and avoid a dynamic invocation per index.

So that

```cangjie
for (i in 0..n) {
    f((T)arr[i])
}
```

can be rewritten as

```cangjie
let xs: Array<T> = (Array<T>)arr
for (i in 0..n) {
    f(xs[i])
}
```

Issue: the Cangjie array is a snapshot. If the ArkTS array is mutated during the loop (from JS, or from Cangjie), the cached copy is stale. `fromExtern` needs to support the conversion of arrays.

# 3. More complex optimizations - need some thought

## 3.1. ArkTS JITing: construct complex expressions (e.g. loops with ArkTS calls) and JIT them to ArkTS (avoid calls and conversions)

## 3.2. ArkTS prefetching: associated fields or objects (from static analysis) can be prefetched (also concurrently)
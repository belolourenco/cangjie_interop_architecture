# Problem 1: Two lifetime modes in `ohos.ark_interop`

In `ark_interop`, a heap-backed ArkTS value can be held in Cangjie in two ways.

#### 1. Scope-local `JSValue`

Operations such as `requireArkModule`, `getProperty`, and `getElement` return a `JSValue`
even when the underlying ArkTS value is heap-allocated. That handle is tied to the current
interop scope (`ARKTS_OpenScope` / `handleValue`). Leaving the scope invalidates it; it is
**not** a global reference.

```cangjie
jsContext.newScope {
    let mod = jsContext.requireArkModule(specifier)        // JSValue, scope-local
    let info = mod.getProperty("info")                     // JSValue, scope-local
    let version = info.getProperty("version").toString()
    ...
} // mod and info underlying values are no longer usable even if they escape the scope
```

```cangjie
jsContext.newScope {
    let arr = ... // some JSArray / JSValue
    let e0 = arr.getElement(0)   // JSValue, scope-local (even if e0 is an object)
    let e1 = e0.getProperty("x") // still scope-local
} // e1 and e2 underlying values are no longer usable even if they escape the scope
```

#### 2. Global `JSHeapObject`

Constructors such as `ctx.string` / `ctx.object` / `ctx.bigint` create a heap value and
promote it to a **global** handle immediately (`ARKTS_CreateGlobal`). Separately, `asX`
APIs take an existing `JSValue` and promote it the same way. In both cases the global lives
until the Cangjie wrapper is collected; the `JSHeapObject` finalizer calls
`ARKTS_DisposeGlobal`.

```cangjie
let s = jsContext.string("abc")     // JSString  <: JSHeapObject → global
let o = jsContext.object()          // JSObject  <: JSHeapObject → global
let b = jsContext.bigint(n)         // JSBigInt <: JSHeapObject → global

let v: JSValue = ...                // may be scope-local
let f = v.asFunction()              // JSFunction → global
let obj = v.asObject()              // JSObject   → global
let c = v.asClass()                 // JSClass    → global
// s / o / b / f / obj / c JS underlying values are disposed when the Cangjie finalizer is executed (through an `ARKTS_DisposeGlobal` FFI call)
```

Immediates (`undefined` / `null` / `boolean` / `number`) are neither scope-tracked nor
globals; they remain usable after the scope closes.

## Why `ForeignRuntime` / `Extern` cannot express this

`ark_interop` splits lifetime by **type** (`JSValue` vs `JSHeapObject`). The Extern
interface has a single result type for every dynamic op:

```cangjie
// ark_interop: two types, two lifetimes
let v: JSValue = obj.getProperty("a")   // scope-local
let o: JSObject = v.asObject()          // global

// ForeignRuntime: one type for both
let e: Extern<ArkTS> = obj.a            // memberAccess → Extern<ArkTS>
```

There is no `asX` step in the desugaring, so the API cannot name a promotion from “local”
to “global.”

**So the only fit for a long-lived `Extern` is: promote every heap result to global.**
That collapses `ark_interop`’s cheap path into the expensive one:

```cangjie
let x = obj.a.b.c
// each of a, b, c (if heap-typed) → ARKTS_CreateGlobal

obj.method(args)
// memberAccess promotes the function to global, even if discarded after the call

let s: String = (String)(obj.name)
// Ref(JSString) global, then copy out — ark_interop could do
// getProperty("name").toString() with only a scope-local JSValue
```

Immediates stay free of globals; every heap-typed temporary pays `CreateGlobal` /
`DisposeGlobal`. The two lifetime modes above cannot be represented.

# Problem 2: Hard to capture JS semantics on method call

In ArkTS/JS, whether `this` is bound depends on **how** the method is invoked — not only
on looking it up:

```typescript
class A {
  count: number = 1
  m(i: number) {
    if (this == null) {                                            // A
    } else {                                                       // B
      this.count = i
    }
  }
}

let a = new A()
a.m(10)     // reaches B  — call site is a.m(...), so this === a

let x = a.m
x(20)       // reaches A  — call site is x(...); this is not a
```

Cangjie desugars both shapes the same way:

```cangjie
a.m(10)
// → functionCall(memberAccess(a, "m"), [10])

let x = a.m
x(20)
// → let x = memberAccess(a, "m")
//   functionCall(x, [20])
```

`memberAccess` and `functionCall` see the same sequence in both cases. The runtime can
choose to store the receiver on the value returned by `memberAccess` (then both reach B)
or not (then both reach A) — but not both. One of the JS behaviours is always lost.

# Problem 3: Hard to implement optimizations

A field chain on an `Extern` value is desugared into nested single-field calls:

```cangjie
a.b.c.d
// → T.memberAccess(
//       T.memberAccess(
//           T.memberAccess(a, "b"),
//           "c"),
//       "d")
```

A typical `memberAccess` does an FFI round-trip. So `a.b.c.d` pays **three** crossings
(and three intermediate handles), even though it is one logical path from `a`.

A batched form would be cheaper:

```cangjie
T.memberAccess(a, ["b", "c", "d"])   // one crossing / one lookup path
```

But each nested call only sees one field name. The runtime cannot reconstruct the full
chain from the separate calls, so this optimization needs the compiler to emit the batched
form. Today’s desugaring always produces the nested shape, which blocks that class of
optimization.

Even then, today’s FFI is one property at a time (`ARKTS_GetProperty`). A true batch needs
a foreign function that accepts the whole path in one call; otherwise Cangjie would still
invoke `ARKTS_GetProperty` once per field.

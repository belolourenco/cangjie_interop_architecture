# `ohos.ark_interop` versus `Extern<ArkTS>`

`ohos.ark_interop` is the existing Cangjie library for talking to the ArkTS/JS engine: applications hold a `JSContext`, wrap values as `JSValue` (and typed helpers), and call the VM through explicit APIs. The extern solution in [ArkTS Foreign Runtime](https://github.com/belolourenco/cangjie_interop_architecture/blob/main/docs/arkts_runtime_design.md) keeps that engine contract but hides it behind `Extern<ArkTS>`: the compiler desugars dynamic member access, calls, and casts onto `ArkTS <: ForeignRuntime<ArkTS>` static methods.

Examples below are taken from the [cj-dts2cj translation rules](https://gitcode.com/Cangjie/cangjie_docs/blob/main/docs/tools/source_en/cmd-tools/cj-dts2cj-translation-rules.md) and translated by hand. Even though the ArkTS runtime is not yet fully implemented, the Extern versions still compiles successfully using the definition of `ArkTS<T>` and `ArkTS1` listed below.

# The Mock ArkTS runtime

The examples below assume that ArkTS is defined as below

```cangjie
open public class ArkTS<T> <: ForeignRuntime<T> where T <: ArkTS<T> {
    public static func memberAccess(_: Extern<T>, _: String): Extern<T>     { throw ArkTSNotImplemented() }
    public static func indexedAccess(_: Extern<T>, _: Any): Extern<T>       { throw ArkTSNotImplemented() }
    public static func memberUpdate(_: Extern<T>, _: String, _: Any): Unit  { throw ArkTSNotImplemented() }
    public static func indexedUpdate(_: Extern<T>, _: Any, _: Any): Unit    { throw ArkTSNotImplemented()}
    public static func functionCall(_: Extern<T>, _: Array<Any>): Extern<T> { throw ArkTSNotImplemented() }
    public static func fromExtern<R>(_: Extern<T>): R                       { throw ArkTSNotImplemented() }
    // List<Runtime> requires from Extern to Array<String>
    public static func toExtern<R>(_: R): Extern<T>                         { throw ArkTSNotImplemented() }
    // needs to translate `(Extern<T>) -> Extern<T>` into `Extern<T>`
    // List<Runtime> requires conversion Array<String> to Extern
    public static func undefined(): Extern<T>                               { throw ArkTSNotImplemented() }
    public static func getModule(_: String, _: ?String): Extern<T>          { throw ArkTSNotImplemented() }
    public static func object(): Extern<T>                                  { throw ArkTSNotImplemented() }
    public static func isUndefined(_: Extern<T>): Bool                      { throw ArkTSNotImplemented() }
    public static func global(): Extern<T>                                  { throw ArkTSNotImplemented() }
}
```

Multiple instances of this foreign runtime can be created as follows:

```cangjie
public class ArkTS1 <: ArkTS<ArkTS1> {}
public class ArkTS2 <: ArkTS<ArkTS2> {}
public class ArkTS3 <: ArkTS<ArkTS3> {}
// ...
```

# Examples


## Basic Types

```cangjie
public class GreetingSettings {
    protected GreetingSettings(public var greeting: String,
    public var duration!: Option<Float64> = None,
    public var color!: Option<String> = None) {}

    public func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["greeting"] = greeting.toJSValue(context)
        if(let Some(v) <- duration) {
            obj["duration"] = v.toJSValue(context)
        }
        if(let Some(v) <- color) {
            obj["color"] = v.toJSValue(context)
        }
        obj.toJSValue()
    }

    public static func fromJSValue (context: JSContext, input: JSValue): GreetingSettings {
        let obj = input.asObject()
        GreetingSettings(
        String.fromJSValue(context, obj["greeting"]),
        duration: if(obj["duration"].isUndefined()) {
            None
        } else {
            Float64.fromJSValue(context, obj["duration"])
        },
        color: if(obj["color"].isUndefined()) {
            None
        } else {
            String.fromJSValue(context, obj["color"])
        }
        )
    }

}
```

> ```cangjie
> public class GreetingSettings<Runtime> where Runtime <: ArkTS<Runtime> {
>
>     protected GreetingSettings(
>         public var greeting: String,
>         public var duration!: Option<Float64> = None,
>         public var color!: Option<String> = None
>     ) {}
>
>     public func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.greeting = greeting
>         if(let Some(v) <- duration) {
>             obj.duration = v
>         }
>         if(let Some(v) <- color) {
>             obj.color = v
>         }
>         obj
>     }
>
>     public static func fromExtern(input: Extern<Runtime>): GreetingSettings<Runtime> {
>         GreetingSettings(
>             (String)input.greeting,
>             duration: if(Runtime.isUndefined(input.duration)) {
>                 None
>             } else {
>                 (Float64)input.duration
>             },
>             color: if(Runtime.isUndefined(input.color)) {
>                 None
>             } else {
>                 (String)input.color
>             }
>         )
>     }
>
> }
> ```

>> ```cangjie
>> public class GreetingSettings<Runtime> where Runtime <: ArkTS<Runtime> {
>>
>>     protected GreetingSettings(
>>         public var greeting: String,
>>         public var duration!: Option<Float64> = None,
>>         public var color!: Option<String> = None
>>     ) {}
>>
>>     public func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "greeting", greeting))
>>         if(let Some(v) <- duration) {
>>             Runtime.eval(MemberUpdate(obj, "duration", v))
>>         }
>>         if(let Some(v) <- color) {
>>             Runtime.eval(MemberUpdate(obj, "color", v))
>>         }
>>         obj
>>     }
>>
>>     public static func fromExtern(input: Extern<Runtime>): GreetingSettings<Runtime> {
>>         GreetingSettings(
>>             Runtime.fromExtern<String>(MemberAccess(input, "greeting")),
>>             duration: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "duration")))) {
>>                 None
>>             } else {
>>                 Runtime.fromExtern<Float64>(MemberAccess(input, "duration"))
>>             },
>>             color: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "color")))) {
>>                 None
>>             } else {
>>                 Runtime.fromExtern<String>(MemberAccess(input, "color"))
>>             }
>>         )
>>     }
>>
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 223 |  |
| sugared version | 190 | -33 |
| desugared: extern with eval | 254 | +31 |

## Optional Properties

```cangjie
public class Product {

    protected Product(public var price!: Option<Float64> = None) {}


    public func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        if(let Some(v) <- price) {
            obj["price"] = v.toJSValue(context)
        }
        obj.toJSValue()
    }

    public static func fromJSValue (context: JSContext, input: JSValue): Product {
        let obj = input.asObject()
        Product(
        price: if(obj["price"].isUndefined()) {
            None
        } else {
            Float64.fromJSValue(context, obj["price"])
        }
        )
    }

}
```

> ```cangjie
> public class Product<Runtime> where Runtime <: ArkTS<Runtime> {
>
>     protected Product(public var price!: Option<Float64> = None) {}
>
>     public func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         if(let Some(v) <- price) {
>             obj.price = v
>         }
>         obj
>     }
>
>     public static func fromExtern(input: Extern<Runtime>): Product<Runtime> {
>         Product(
>         price: if (Runtime.isUndefined(input.price)) {
>             None
>         } else {
>             (Float64)input.price
>         }
>         )
>     }
>
> }
> ```


>> ```cangjie
>> public class Product<Runtime> where Runtime <: ArkTS<Runtime> {
>>
>>     protected Product(public var price!: Option<Float64> = None) {}
>>
>>     public func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         if(let Some(v) <- price) {
>>             Runtime.eval(MemberUpdate(obj, "price", v))
>>         }
>>         obj
>>     }
>>
>>     public static func fromExtern(input: Extern<Runtime>): Product<Runtime> {
>>         Product(
>>         price: if (Runtime.isUndefined(Runtime.eval(MemberAccess(input, "price")))) {
>>             None
>>         } else {
>>             Runtime.fromExtern<Float64>(MemberAccess(input, "price"))
>>         }
>>         )
>>     }
>>
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 128 |  |
| sugared version | 117 | -11 |
| desugared: extern with eval | 141 | +13 |


## Readonly Properties

```cangjie
public class Point {
    protected Point(public let x: Float64,
    public let y: Float64) {}

    public func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["x"] = x.toJSValue(context)
        obj["y"] = y.toJSValue(context)
        obj.toJSValue()
    }

    public static func fromJSValue (context: JSContext, input: JSValue): Point {
        let obj = input.asObject()
        Point(
        Float64.fromJSValue(context, obj["x"]),
        Float64.fromJSValue(context, obj["y"])
        )
    }
}
```

> ```cangjie
> public class Point<Runtime> where Runtime <: ArkTS<Runtime> {
>     protected Point(public let x: Float64,
>     public let y: Float64) {}
>
>     public func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.x = x
>         obj.y = y
>         obj
>     }
>
>     public static func fromJSValue(input: Extern<Runtime>): Point<Runtime> {
>         Point(
>         (Float64)input.x,
>         (Float64)input.y
>         )
>     }
> }
> ```


>> ```cangjie
>> public class Point<Runtime> where Runtime <: ArkTS<Runtime> {
>>     protected Point(public let x: Float64,
>>     public let y: Float64) {}
>>
>>     public func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "x", x))
>>         Runtime.eval(MemberUpdate(obj, "y", y))
>>         obj
>>     }
>>
>>     public static func fromJSValue(input: Extern<Runtime>): Point<Runtime> {
>>         Point(
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "x")),
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "y"))
>>         )
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 120 |  |
| sugared version | 98 | -22 |
| desugared: extern with eval | 130 | +10 |


## Member Functions

```cangjie
public class Person {

    protected Person(let arkts_object: JSObject) {}


    public mut prop name: String {
        get() {
            checkThreadAndCall < String >(getMainContext()) {
                ctx: JSContext => String.fromJSValue(ctx, arkts_object["name"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => arkts_object["name"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief greet(): String
    */
    public func greet(): String {
        jsObjApiCall < String >( arkts_object, "greet", emptyArg)
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): Person {
        Person(input.asObject())
    }
}
```

> ```cangjie
> public class Person<Runtime> where Runtime <: ArkTS<Runtime> {
>     protected Person(let arkts_object: Extern<Runtime>) {}
>
>     public mut prop name: String {
>         get() {
>             (String)arkts_object.name
>         }
>         set(v) {
>             arkts_object.name = v
>         }
>
>     }
>
>     public func greet(): String {
>         (String)arkts_object.greet()
>     }
>
>     func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>
>     static func fromExtern (input: Extern<Runtime>): Person<Runtime> {
>         Person(input)
>     }
> }
> ```


>> ```cangjie
>> public class Person<Runtime> where Runtime <: ArkTS<Runtime> {
>>     protected Person(let arkts_object: Extern<Runtime>) {}
>>
>>     public mut prop name: String {
>>         get() {
>>             Runtime.fromExtern<String>(MemberAccess(arkts_object, "name"))
>>         }
>>         set(v) {
>>             Runtime.eval(MemberUpdate(arkts_object, "name", v))
>>         }
>>
>>     }
>>
>>     public func greet(): String {
>>         Runtime.fromExtern<String>(FuncCall(MemberAccess(arkts_object, "greet"), []))
>>     }
>>
>>     func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>
>>     static func fromExtern (input: Extern<Runtime>): Person<Runtime> {
>>         Person(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 146 |  |
| sugared version | 109 | -37 |
| desugared: extern with eval | 137 | -9 |


## Function Overloading

```cangjie
public class Calculator {

    protected Calculator(let arkts_object: JSObject) {}


    /**
    * @brief add(x: number,y: number): number
    */
    public func add(x: Float64, y: Float64): Float64 {
        jsObjApiCall < Float64 >( arkts_object, "add", { ctx =>[x.toJSValue(ctx), y.toJSValue(ctx)] })
    }
    /**
    * @brief add(x: string,y: string): String
    */
    public func add(x: String, y: String): String {
        jsObjApiCall < String >( arkts_object, "add", { ctx =>[x.toJSValue(ctx), y.toJSValue(ctx)] })
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): Calculator {
        Calculator(input.asObject())
    }
}
```

> ```cangjie
> public class Calculator<Runtime> where Runtime <: ArkTS<Runtime> {
>
>     protected Calculator(let arkts_object: Extern<Runtime>) {}
>
>
>     /**
>     * @brief add(x: number,y: number): number
>     */
>     public func add(x: Float64, y: Float64): Float64 {
>         (Float64)arkts_object.add(x, y)
>     }
>     /**
>     * @brief add(x: string,y: string): String
>     */
>     public func add(x: String, y: String): String {
>         (String)arkts_object.add(x, y)
>     }
>
>     func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>
>     static func fromJSValue (input: Extern<Runtime>): Calculator<Runtime> {
>         Calculator(input)
>     }
> }
> ```


>> ```cangjie
>> public class Calculator<Runtime> where Runtime <: ArkTS<Runtime> {
>>
>>     protected Calculator(let arkts_object: Extern<Runtime>) {}
>>
>>
>>     /**
>>     * @brief add(x: number,y: number): number
>>     */
>>     public func add(x: Float64, y: Float64): Float64 {
>>         Runtime.fromExtern<Float64>(FuncCall(MemberAccess(arkts_object, "add"), [x, y]))
>>     }
>>     /**
>>     * @brief add(x: string,y: string): String
>>     */
>>     public func add(x: String, y: String): String {
>>         Runtime.fromExtern<String>(FuncCall(MemberAccess(arkts_object, "add"), [x, y]))
>>     }
>>
>>     func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>
>>     static func fromJSValue (input: Extern<Runtime>): Calculator<Runtime> {
>>         Calculator(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 145 |  |
| sugared version | 116 | -29 |
| desugared: extern with eval | 140 | -5 |


## Array Types

```cangjie
public class List {

    protected List(let arkts_object: JSObject) {}


    public mut prop items: Array<String> {
        get() {
            checkThreadAndCall < Array<String> >(getMainContext()) {
                ctx: JSContext => Array<String>.fromJSValue(ctx, arkts_object["items"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => arkts_object["items"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief add(item: string): void
    */
    public func add(item: String): Unit {
        jsObjApiCall < Unit >( arkts_object, "add", { ctx =>[item.toJSValue(ctx)] })
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): List {
        List(input.asObject())
    }
}
```

> ```cangjie
> public class List<Runtime> where Runtime <: ArkTS<Runtime>  {
>
>     protected List(let arkts_object: Extern<Runtime>) {}
>
>
>     public mut prop items: Array<String> {
>         get() {
>             (Array<String>)arkts_object.items
>         }
>         set(v) {
>             arkts_object.items = v
>         }
>         // NOTE: this assume that toExtern converts Array<String> into Extern,
>         // and fromExtern converts Extern into ArrayString
>     }
>
>     /**
>     * @brief add(item: string): void
>     */
>     public func add(item: String): Unit {
>         arkts_object.add(item)
>     }
>
>     func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>
>     static func fromExtern (input: Extern<Runtime>): List<Runtime> {
>         List(input)
>     }
> }
> ```


>> ```cangjie
>> public class List<Runtime> where Runtime <: ArkTS<Runtime>  {
>>
>>     protected List(let arkts_object: Extern<Runtime>) {}
>>
>>
>>     public mut prop items: Array<String> {
>>         get() {
>>             Runtime.fromExtern<Array<String>>(MemberAccess(arkts_object, "items"))
>>         }
>>         set(v) {
>>             Runtime.eval(MemberUpdate(arkts_object, "items", v))
>>         }
>>         // NOTE: this assume that toExtern converts Array<String> into Extern,
>>         // and fromExtern converts Extern into ArrayString
>>     }
>>
>>     /**
>>     * @brief add(item: string): void
>>     */
>>     public func add(item: String): Unit {
>>         Runtime.eval(FuncCall(MemberAccess(arkts_object, "add"), [item]))
>>     }
>>
>>     func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>
>>     static func fromExtern (input: Extern<Runtime>): List<Runtime> {
>>         List(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 169 |  |
| sugared version | 116 | -53 |
| desugared: extern with eval | 143 | -26 |


## Inheritance

```cangjie
public open class A {
    
    protected A(public var p: Float64) {}
    
    
    public open func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["p"] = p.toJSValue(context)
        obj.toJSValue()
    }
    
    public static func fromJSValue(context: JSContext, input: JSValue): A {
        let obj = input.asObject()
        A(
        Float64.fromJSValue(context, obj["p"])
        )
    }
    
}
```

> ```cangjie
> public open class A<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected A(public var p: Float64) {}
>     
>     
>     public open func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.p = p
>         obj
>     }
>     
>     public static func fromExtern(input: Extern<Runtime>): A<Runtime> {
>         A(
>         (Float64)input.p
>         )
>     }
>     
> }
> ```


>> ```cangjie
>> public open class A<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected A(public var p: Float64) {}
>>     
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "p", p))
>>         obj
>>     }
>>     
>>     public static func fromExtern(input: Extern<Runtime>): A<Runtime> {
>>         A(
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "p"))
>>         )
>>     }
>>     
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 93 |  |
| sugared version | 82 | -11 |
| desugared: extern with eval | 98 | +5 |


```cangjie
/*interface B {
    p1: number;
    }*/

public open class B <: A {
    
    protected B(p: Float64,
    public var p1: Float64) { super(p) }
    
    
    public open func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["p"] = p.toJSValue(context)
        obj["p1"] = p1.toJSValue(context)
        obj.toJSValue()
    }
    
    public static func fromJSValue(context: JSContext, input: JSValue): B {
        let obj = input.asObject()
        B(
        Float64.fromJSValue(context, obj["p"]),
        Float64.fromJSValue(context, obj["p1"])
        )
    }
    
}
```

> ```cangjie
> /*interface B {
>     p1: number;
>     }*/
>
> public open class B<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected B(p: Float64,
>     public var p1: Float64) { super(p) }
>     
>     
>     public open func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.p = p
>         obj.p1 = p1
>         obj
>     }
>     
>     public static func fromExtern(input: Extern<Runtime>): B<Runtime> {
>         B(
>         (Float64)input.p,
>         (Float64)input.p1
>         )
>     }
>     
> }
> ```


>> ```cangjie
>> /*interface B {
>>     p1: number;
>>     }*/
>>
>> public open class B<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected B(p: Float64,
>>     public var p1: Float64) { super(p) }
>>     
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "p", p))
>>         Runtime.eval(MemberUpdate(obj, "p1", p1))
>>         obj
>>     }
>>     
>>     public static func fromExtern(input: Extern<Runtime>): B<Runtime> {
>>         B(
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "p")),
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "p1"))
>>         )
>>     }
>>     
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 126 |  |
| sugared version | 107 | -19 |
| desugared: extern with eval | 139 | +13 |


```cangjie
/*interface C {
    f(): void
    }*/

public open class C {
    
    protected C(public var arkts_object: JSObject) {}
    
    
    /**
     * @brief f(): void
     */
    public func f(): Unit {
        jsObjApiCall < Unit >( arkts_object, "f", emptyArg)
    }
    
    public open func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }
    
    static func fromJSValue(context: JSContext, input: JSValue): C {
        C(input.asObject())
    }
}
```

> ```cangjie
> /*interface C {
>     f(): void
>     }*/
>
> public open class C<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected C(public var arkts_object: Extern<Runtime>) {}
>     
>     
>     /**
>      * @brief f(): void
>      */
>     public func f(): Unit {
>         arkts_object.f()
>     }
>     
>     public open func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>     
>     static func fromExtern(input: Extern<Runtime>): C<Runtime> {
>         C(input)
>     }
> }
> ```


>> ```cangjie
>> /*interface C {
>>     f(): void
>>     }*/
>>
>> public open class C<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected C(public var arkts_object: Extern<Runtime>) {}
>>     
>>     
>>     /**
>>      * @brief f(): void
>>      */
>>     public func f(): Unit {
>>         Runtime.eval(FuncCall(MemberAccess(arkts_object, "f"), []))
>>     }
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>     
>>     static func fromExtern(input: Extern<Runtime>): C<Runtime> {
>>         C(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 79 |  |
| sugared version | 80 | +1 |
| desugared: extern with eval | 92 | +13 |


```cangjie
/*interface D {
    }*/

public open class D <: C {
    
    protected D(arkts_object: JSObject) { super(arkts_object) }
    
    
    
    public open func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }
    
    static func fromJSValue(context: JSContext, input: JSValue): D {
        D(input.asObject())
    }
}
```

> ```cangjie
> /*interface D {
>     }*/
>
> public open class D<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected D(arkts_object: Extern<Runtime>) { super(arkts_object) }
>     
>     
>     
>     public open func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>     
>     static func fromExtern(input: Extern<Runtime>): D<Runtime> {
>         D(input)
>     }
> }
> ```


>> ```cangjie
>> /*interface D {
>>     }*/
>>
>> public open class D<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected D(arkts_object: Extern<Runtime>) { super(arkts_object) }
>>     
>>     
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>     
>>     static func fromExtern(input: Extern<Runtime>): D<Runtime> {
>>         D(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 63 |  |
| sugared version | 73 | +10 |
| desugared: extern with eval | 73 | +10 |


```cangjie
/*interface E {
    }*/

public open class E <: A {
    
    protected E(p: Float64) { super(p) }
    
    
    public open func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["p"] = p.toJSValue(context)
        obj.toJSValue()
    }
    
    public static func fromJSValue(context: JSContext, input: JSValue): E {
        let obj = input.asObject()
        E(
        Float64.fromJSValue(context, obj["p"])
        )
    }
    
}
```

> ```cangjie
> /*interface E {
>     }*/
>
> public open class E<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected E(p: Float64) { super(p) }
>     
>     
>     public open func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.p = p
>         obj
>     }
>     
>     public static func fromExtern(input: Extern<Runtime>): E<Runtime> {
>         E(
>         (Float64)input.p
>         )
>     }
>     
> }
> ```


>> ```cangjie
>> /*interface E {
>>     }*/
>>
>> public open class E<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected E(p: Float64) { super(p) }
>>     
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "p", p))
>>         obj
>>     }
>>     
>>     public static func fromExtern(input: Extern<Runtime>): E<Runtime> {
>>         E(
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "p"))
>>         )
>>     }
>>     
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 97 |  |
| sugared version | 89 | -8 |
| desugared: extern with eval | 105 | +8 |


```cangjie
/*interface F {
    g(): void
    }*/

public open class F <: C {
    
    protected F(arkts_object: JSObject) { super(arkts_object) }
    
    
    /**
     * @brief g(): void
     */
    public func g(): Unit {
        jsObjApiCall < Unit >( arkts_object, "g", emptyArg)
    }
    
    public open func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }
    
    static func fromJSValue(context: JSContext, input: JSValue): F {
        F(input.asObject())
    }
}
```

> ```cangjie
> /*interface F {
>     g(): void
>     }*/
>
> public open class F<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime> {
>     
>     protected F(arkts_object: Extern<Runtime>) { super(arkts_object) }
>     
>     
>     /**
>      * @brief g(): void
>      */
>     public func g(): Unit {
>         arkts_object.g()
>     }
>     
>     public open func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>     
>     static func fromExtern(input: Extern<Runtime>): F<Runtime> {
>         F(input)
>     }
> }
> ```


>> ```cangjie
>> /*interface F {
>>     g(): void
>>     }*/
>>
>> public open class F<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime> {
>>     
>>     protected F(arkts_object: Extern<Runtime>) { super(arkts_object) }
>>     
>>     
>>     /**
>>      * @brief g(): void
>>      */
>>     public func g(): Unit {
>>         Runtime.eval(FuncCall(MemberAccess(arkts_object, "g"), []))
>>     }
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>     
>>     static func fromExtern(input: Extern<Runtime>): F<Runtime> {
>>         F(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 83 |  |
| sugared version | 87 | +4 |
| desugared: extern with eval | 99 | +16 |


## Nested Objects

```cangjie
public open class AutoGenType0 {
    
    protected AutoGenType0(public var : String,
    public var : String) {}
    
    
    public open func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["city"] = .toJSValue(context)
        obj["zipCode"] = .toJSValue(context)
        obj.toJSValue()
    }
    
    public static func fromJSValue(context: JSContext, input: JSValue): AutoGenType0 {
        let obj = input.asObject()
        AutoGenType0(
        String.fromJSValue(context, obj["city"]),
        String.fromJSValue(context, obj["zipCode"])
        )
    }
    
}
```

> ```cangjie
> public open class AutoGenType0<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected AutoGenType0(public var city: String,
>     public var zipCode: String) {}
>     
>
>     public open func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.city = city
>         obj.zipCode = zipCode
>         obj
>     }
>     
>     public static func fromExtern(input: Extern<Runtime>): AutoGenType0<Runtime> {
>         AutoGenType0(
>         (String)input.city,
>         (String)input.zipCode
>         )
>     }
>     
> }
> ```


>> ```cangjie
>> public open class AutoGenType0<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected AutoGenType0(public var city: String,
>>     public var zipCode: String) {}
>>     
>>
>>     public open func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "city", city))
>>         Runtime.eval(MemberUpdate(obj, "zipCode", zipCode))
>>         obj
>>     }
>>     
>>     public static func fromExtern(input: Extern<Runtime>): AutoGenType0<Runtime> {
>>         AutoGenType0(
>>         Runtime.fromExtern<String>(MemberAccess(input, "city")),
>>         Runtime.fromExtern<String>(MemberAccess(input, "zipCode"))
>>         )
>>     }
>>     
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 118 |  |
| sugared version | 100 | -18 |
| desugared: extern with eval | 132 | +14 |


```cangjie
public open class UserProfile {
    
    protected UserProfile(public var id: Float64,
    public var name: String,
    public var address: AutoGenType0) {}
    
    
    public open func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        obj["id"] = id.toJSValue(context)
        obj["name"] = name.toJSValue(context)
        obj["address"] = address.toJSValue(context)
        obj.toJSValue()
    }
    
    public static func fromJSValue(context: JSContext, input: JSValue): UserProfile {
        let obj = input.asObject()
        UserProfile(
        Float64.fromJSValue(context, obj["id"]),
        String.fromJSValue(context, obj["name"]),
        AutoGenType0.fromJSValue(context, obj["address"])
        )
    }
    
}
```

> ```cangjie
> public open class UserProfile<Runtime> where Runtime <: ArkTS<Runtime>  {
>     
>     protected UserProfile(public var id: Float64,
>     public var name: String,
>     public var address: AutoGenType0<Runtime>) {}
>     
>     
>     public open func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         obj.id = id
>         obj.name = name
>         obj.address = address.toExtern()
>         obj
>     }
>     
>     public static func fromExtern(input: Extern<Runtime>): UserProfile<Runtime> {
>         UserProfile(
>         (Float64)input.id,
>         (String)input.name,
>         AutoGenType0.fromExtern(input.address)
>         )
>     }
>     
> }
> ```


>> ```cangjie
>> public open class UserProfile<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     
>>     protected UserProfile(public var id: Float64,
>>     public var name: String,
>>     public var address: AutoGenType0<Runtime>) {}
>>     
>>     
>>     public open func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         Runtime.eval(MemberUpdate(obj, "id", id))
>>         Runtime.eval(MemberUpdate(obj, "name", name))
>>         Runtime.eval(MemberUpdate(obj, "address", address.toExtern()))
>>         obj
>>     }
>>     
>>     public static func fromExtern(input: Extern<Runtime>): UserProfile<Runtime> {
>>         UserProfile(
>>         Runtime.fromExtern<Float64>(MemberAccess(input, "id")),
>>         Runtime.fromExtern<String>(MemberAccess(input, "name")),
>>         AutoGenType0.fromExtern(Runtime.eval(MemberAccess(input, "address")))
>>         )
>>     }
>>     
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 151 |  |
| sugared version | 127 | -24 |
| desugared: extern with eval | 175 | +24 |


## Union Type Aliases

```cangjie
public enum GreetingLike {
    | STRING(String)
    | NUMBER(Float64)

    public func toJSValue(context: JSContext): JSValue {
        match(this) {
            case STRING(x) => context.string(x).toJSValue()
            case NUMBER(x) => context.number(x).toJSValue()
        }
    }
}
```

> ```cangjie
> public enum GreetingLike<Runtime> where Runtime <: ArkTS<Runtime>  {
>     | STRING(String)
>     | NUMBER(Float64)
>
>     public func toExtern(): Extern<Runtime> {
>         match(this) {
>             case STRING(x) =>
>                 let e: Extern<Runtime> = x
>                 e
>             case NUMBER(x) => 
>                 let e: Extern<Runtime> = x
>                 e
>         }
>     }
> }
> ```


>> ```cangjie
>> public enum GreetingLike<Runtime> where Runtime <: ArkTS<Runtime>  {
>>     | STRING(String)
>>     | NUMBER(Float64)
>>
>>     public func toExtern(): Extern<Runtime> {
>>         match(this) {
>>             case STRING(x) =>
>>                 let e: Extern<Runtime> = Runtime.toExtern(x)
>>                 e
>>             case NUMBER(x) => 
>>                 let e: Extern<Runtime> = Runtime.toExtern(x)
>>                 e
>>         }
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 65 |  |
| sugared version | 75 | +10 |
| desugared: extern with eval | 85 | +20 |


## Constructors

```cangjie
public class Greeter {

    protected Greeter(let arkts_object: JSObject) {}
    /**
    * @brief constructor(greeting: string): void
    */
    public init(greeting: String) {
        arkts_object = checkThreadAndCall < JSObject >(getMainContext()) {
            __ctx =>
            let clazz = __ctx.global["Greeter"].asClass(__ctx)
            clazz.new(greeting.toJSValue(__ctx)).asObject()
        }
    }

    public mut prop greeting: String {
        get() {
            checkThreadAndCall < String >(getMainContext()) {
                ctx: JSContext => String.fromJSValue(ctx, arkts_object["greeting"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => arkts_object["greeting"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief showGreeting(): void
    */
    public func showGreeting(): Unit {
        jsObjApiCall < Unit >( arkts_object, "showGreeting", emptyArg)
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): Greeter {
        Greeter(input.asObject())
    }
}
```

> ```cangjie
> public class Greeter<Runtime> where Runtime <: ArkTS<Runtime> {
>
>     protected Greeter(let arkts_object: Extern<Runtime>) {}
>     /**
>     * @brief constructor(greeting: string): void
>     */
>     public init(greeting: String) {
>         arkts_object = Runtime.global().Greeter(greeting)
>         // or
>         // arkts_object = Runtime.global().Greeter.new(greeting)
>         // or
>         // arkts_object = Runtime.new(Runtime.global().Greeter, greeting)
>     }
>
>     public mut prop greeting: String {
>         get() {
>             (String)arkts_object.greeting
>         }
>         set(v) {
>             arkts_object.greeting = v
>         }
>
>     }
>
>     /**
>     * @brief showGreeting(): void
>     */
>     public func showGreeting(): Unit {
>         arkts_object.showGreeting()
>     }
>
>     func toExtern(): Extern<Runtime> {
>         arkts_object
>     }
>
>     static func fromExtern (input: Extern<Runtime>): Greeter<Runtime> {
>         Greeter(input)
>     }
> }
> ```


>> ```cangjie
>> public class Greeter<Runtime> where Runtime <: ArkTS<Runtime> {
>>
>>     protected Greeter(let arkts_object: Extern<Runtime>) {}
>>     /**
>>     * @brief constructor(greeting: string): void
>>     */
>>     public init(greeting: String) {
>>         arkts_object = Runtime.eval(FuncCall(MemberAccess(Runtime.global(), "Greeter"), [greeting]))
>>         // or
>>         // arkts_object = Runtime.eval(FuncCall(MemberAccess(MemberAccess(Runtime.global(), "Greeter"), "new"), [greeting]))
>>     }
>>
>>     public mut prop greeting: String {
>>         get() {
>>             Runtime.fromExtern<String>(MemberAccess(arkts_object, "greeting"))
>>         }
>>         set(v) {
>>             Runtime.eval(MemberUpdate(arkts_object, "greeting", v))
>>         }
>>
>>     }
>>
>>     /**
>>     * @brief showGreeting(): void
>>     */
>>     public func showGreeting(): Unit {
>>         Runtime.eval(FuncCall(MemberAccess(arkts_object, "showGreeting"), []))
>>     }
>>
>>     func toExtern(): Extern<Runtime> {
>>         arkts_object
>>     }
>>
>>     static func fromExtern (input: Extern<Runtime>): Greeter<Runtime> {
>>         Greeter(input)
>>     }
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 199 |  |
| sugared version | 127 | -72 |
| desugared: extern with eval | 167 | -32 |


## Static Members

```cangjie
public class MathUtils {

    protected MathUtils(let arkts_object: JSObject) {}

    // Static property
    public mut prop PI: Float64 {
        get() {
            checkThreadAndCall < Float64 >(getMainContext()) {
                ctx: JSContext => Float64.fromJSValue(ctx, getClassConstructorObj("test", "MathUtils")["PI"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => getClassConstructorObj("test", "MathUtils")["PI"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief square(x: number): number
    */
    public static func square(x: Float64): Float64 {
        jsObjApiCall < Float64 >(getClassConstructorObj("test", "MathUtils"),  "square", { ctx =>[x.toJSValue(ctx)] })
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): MathUtils {
        MathUtils(input.asObject())
    }
}

// NOTE: getClassConstructorObj defined in cangjie_sdk/cangjie_tools/hyperlangExtension/src/tool/create_ark_api_call_async.cj
```

> ```cangjie
> public class MathUtils<Runtime> where Runtime <: ArkTS<Runtime>  {
>
>     protected MathUtils(let arkts_object: Extern<Runtime>) {}
>
>     // Static property
>     public mut prop PI: Float64 {
>         get() {
>             let module = Runtime.getModule("test", None)
>             (Float64)module.MathUtils.PI
>         }
>         set(v) {
>             let module = Runtime.getModule("test", None)
>             module.MathUtils.PI = v
>         }
>
>     }
>
>     /**
>     * @brief square(x: number): number
>     */
>     public static func square(x: Float64): Float64 {
>         let module = Runtime.getModule("test", None)
>         (Float64)module.MathUtils.square(x)
>     }
>
>     // ...
> }
> ```


>> ```cangjie
>> public class MathUtils<Runtime> where Runtime <: ArkTS<Runtime>  {
>>
>>     protected MathUtils(let arkts_object: Extern<Runtime>) {}
>>
>>     // Static property
>>     public mut prop PI: Float64 {
>>         get() {
>>             let module = Runtime.getModule("test", None)
>>             Runtime.fromExtern<Float64>(MemberAccess(MemberAccess(module, "MathUtils"), "PI"))
>>         }
>>         set(v) {
>>             let module = Runtime.getModule("test", None)
>>             Runtime.eval(MemberUpdate(MemberAccess(module, "MathUtils"), "PI", v))
>>         }
>>
>>     }
>>
>>     /**
>>     * @brief square(x: number): number
>>     */
>>     public static func square(x: Float64): Float64 {
>>         let module = Runtime.getModule("test", None)
>>         Runtime.fromExtern<Float64>(FuncCall(MemberAccess(MemberAccess(module, "MathUtils"), "square"), [x]))
>>     }
>>
>>     // ...
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 176 |  |
| sugared version | 119 | -57 |
| desugared: extern with eval | 156 | -20 |


## Protected Members
```cangjie
public class AnimalProtect {

    protected AnimalProtect(let arkts_object: JSObject) {}

    // Protected property
    public mut prop name: String {
        get() {
            checkThreadAndCall < String >(getMainContext()) {
                ctx: JSContext => String.fromJSValue(ctx, arkts_object["name"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => arkts_object["name"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief makeSound(): void
    */
    public func makeSound(): Unit {
        jsObjApiCall < Unit >( arkts_object, "makeSound", emptyArg)
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue (context: JSContext, input: JSValue): AnimalProtect {
        AnimalProtect(input.asObject())
    }
}
```

> ```cangjie
> public class AnimalProtect<Runtime> where Runtime <: ArkTS<Runtime>  {
>
>     protected AnimalProtect(let arkts_object: Extern<Runtime>) {}
>
>     // Protected property
>     public mut prop name: String {
>         get() {
>             (String)arkts_object.name
>         }
>         set(v) {
>             arkts_object.name = v
>         }
>
>     }
>
>     /**
>     * @brief makeSound(): void
>     */
>     public func makeSound(): Unit {
>         arkts_object.makeSound()
>     }
>
>     // ...
> }
> ```


>> ```cangjie
>> public class AnimalProtect<Runtime> where Runtime <: ArkTS<Runtime>  {
>>
>>     protected AnimalProtect(let arkts_object: Extern<Runtime>) {}
>>
>>     // Protected property
>>     public mut prop name: String {
>>         get() {
>>             Runtime.fromExtern<String>(MemberAccess(arkts_object, "name"))
>>         }
>>         set(v) {
>>             Runtime.eval(MemberUpdate(arkts_object, "name", v))
>>         }
>>
>>     }
>>
>>     /**
>>     * @brief makeSound(): void
>>     */
>>     public func makeSound(): Unit {
>>         Runtime.eval(FuncCall(MemberAccess(arkts_object, "makeSound"), []))
>>     }
>>
>>     // ...
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 146 |  |
| sugared version | 72 | -74 |
| desugared: extern with eval | 100 | -46 |


## Generic Members

```cangjie
public class Box<T> {

    protected Box(let arkts_object: JSObject) {}

    // Property
    public mut prop value: T {
        get() {
            checkThreadAndCall < T >(getMainContext()) {
                ctx: JSContext => T.fromJSValue(ctx, arkts_object["value"])
            }
        }
        set(v) {
            checkThreadAndCall < Unit >(getMainContext()) {
                ctx: JSContext => arkts_object["value"] = v.toJSValue(ctx)
            }
        }

    }

    /**
    * @brief getValue(): T
    */
    public func getValue(): T {
        jsObjApiCall < T >( arkts_object, "getValue", emptyArg) {
            ctx, res => T.fromJSValue(ctx, res)
        }
    }

    func toJSValue(context: JSContext): JSValue {
        arkts_object.toJSValue()
    }

    static func fromJSValue <T>(context: JSContext, input: JSValue): Box<T> {
        Box(input.asObject())
    }
}
```

> ```cangjie
> public class Box<Runtime, T> where Runtime <: ArkTS<Runtime>  {
>
>     protected Box(let arkts_object: Extern<Runtime>) {}
>
>     // Property
>     public mut prop value: T {
>         get() {
>             (T)arkts_object.value
>         }
>         set(v) {
>             arkts_object.value = v
>         }
>
>     }
>
>     /**
>     * @brief getValue(): T
>     */
>     public func getValue(): T {
>         (T)arkts_object.getValue()
>     }
>
>     // ...
> }
> ```


>> ```cangjie
>> public class Box<Runtime, T> where Runtime <: ArkTS<Runtime>  {
>>
>>     protected Box(let arkts_object: Extern<Runtime>) {}
>>
>>     // Property
>>     public mut prop value: T {
>>         get() {
>>             Runtime.fromExtern<T>(MemberAccess(arkts_object, "value"))
>>         }
>>         set(v) {
>>             Runtime.eval(MemberUpdate(arkts_object, "value", v))
>>         }
>>
>>     }
>>
>>     /**
>>     * @brief getValue(): T
>>     */
>>     public func getValue(): T {
>>         Runtime.fromExtern<T>(FuncCall(MemberAccess(arkts_object, "getValue"), []))
>>     }
>>
>>     // ...
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 169 |  |
| sugared version | 77 | -92 |
| desugared: extern with eval | 105 | -64 |


## Function Types
## Interface Properties

```cangjie
public class TestListener {

    protected TestListener(public var onStart!: Option<() -> Unit> = None,
    public var onDestroy!: Option<() -> Unit> = None,
    public var onError!: Option<(code: ErrorCode, msg: String) -> Unit> = None,
    public var onTouch!: Option<() -> Unit> = None,
    public var onEvent!: Option<(e: EventType) -> Unit> = None) {}


    public func toJSValue(context: JSContext): JSValue {
        let obj = context.object()
        if(let Some(v) <- onStart) {
            obj["onStart"] = context.function({ ctx, _ =>
                v()
                ctx.undefined().toJSValue()
            }).toJSValue()
        }
        if(let Some(v) <- onDestroy) {
            obj["onDestroy"] = context.function({ ctx, _ =>
                v()
                ctx.undefined().toJSValue()
            }).toJSValue()
        }
        if(let Some(v) <- onError) {
            obj["onError"] = context.function({ ctx, callInfo =>
                let p0 = ErrorCode.fromJSValue(ctx, callInfo[0])
                let p1 = String.fromJSValue(ctx, callInfo[1])
                v(p0, p1)
                ctx.undefined().toJSValue()
            }).toJSValue()
        }
        if(let Some(v) <- onTouch) {
            obj["onTouch"] = context.function({ ctx, _ =>
                v()
                ctx.undefined().toJSValue()
            }).toJSValue()
        }
        if(let Some(v) <- onEvent) {
            obj["onEvent"] = context.function({ ctx, callInfo =>
                let p0 = EventType.parse(Int32.fromJSValue(ctx, callInfo[0]))
                v(p0)
                ctx.undefined().toJSValue()
            }).toJSValue()
        }
        obj.toJSValue()
    }

    public static func fromJSValue (context: JSContext, input: JSValue): TestListener {
        let obj = input.asObject()
        TestListener(
        onStart: if(obj["onStart"].isUndefined()) {
            None
        } else {
            { =>
                checkThreadAndCall < Unit >(context, { _ =>
                    obj["onStart"].asFunction().call()
                })
            }
        },
        onDestroy: if(obj["onDestroy"].isUndefined()) {
            None
        } else {
            { =>
                checkThreadAndCall < Unit >(context, { _ =>
                    obj["onDestroy"].asFunction().call()
                })
            }
        },
        onError: if(obj["onError"].isUndefined()) {
            None
        } else {
            { code: ErrorCode, msg: String =>
                checkThreadAndCall < Unit >(context, { ctx =>
                    let arg0 = code.toJSValue(ctx)
                    let arg1 = msg.toJSValue(ctx)
                    obj["onError"].asFunction().call([arg0, arg1])
                })
            }
        },
        onTouch: if(obj["onTouch"].isUndefined()) {
            None
        } else {
            { =>
                checkThreadAndCall < Unit >(context, { _ =>
                    obj["onTouch"].asFunction().call()
                })
            }
        },
        onEvent: if(obj["onEvent"].isUndefined()) {
            None
        } else {
            { e: EventType =>
                checkThreadAndCall < Unit >(context, { ctx =>
                    let arg0 = e.get().toJSValue(ctx)
                    obj["onEvent"].asFunction().call([arg0])
                })
            }
        }
        )
    }

}
```

> ```cangjie
> public class TestListener<Runtime> where Runtime <: ArkTS<Runtime>  {
>
>     protected TestListener(public var onStart!: Option<() -> Unit> = None,
>         public var onDestroy!: Option<() -> Unit> = None,
>         public var onError!: Option<(code: ErrorCode, msg: String) -> Unit> = None,
>         public var onTouch!: Option<() -> Unit> = None,
>         public var onEvent!: Option<(e: EventType) -> Unit> = None
>     ) {}
>
>
>     public func toExtern(): Extern<Runtime> {
>         let obj = Runtime.object()
>         if(let Some(v) <- onStart) {
>             obj.onStart = { _: Extern<Runtime> =>
>                 v()
>                 Runtime.undefined()
>             }
>         }
>         if(let Some(v) <- onDestroy) {
>             obj.onDestroy = { _: Extern<Runtime> =>
>                 v()
>                 Runtime.undefined()
>             }
>         }
>         if(let Some(v) <- onError) {
>             obj.onError = { callInfo: Extern<Runtime> =>
>                 let p0 = (ErrorCode)callInfo[0]
>                 let p1 = (String)callInfo[1]
>                 v(p0, p1)
>                 Runtime.undefined()
>             }
>         }
>         if(let Some(v) <- onTouch) {
>             obj.onTouch = { _: Extern<Runtime> =>
>                 v()
>                 Runtime.undefined()
>             }
>         }
>         if(let Some(v) <- onEvent) {
>             obj.onEvent = { callInfo: Extern<Runtime> =>
>                 let p0 = EventType.parse((Int32)callInfo[0])
>                 v(p0)
>                 Runtime.undefined()
>             }
>         }
>         obj
>     }
>
>     public static func fromExtern(input: Extern<Runtime>): TestListener<Runtime> {
>         TestListener(
>             onStart: if(Runtime.isUndefined(input.onStart)) {
>                 None
>             } else {
>                 { => input.onStart()
>                 }
>             },
>             onDestroy: if(Runtime.isUndefined(input.onDestroy)) {
>                 None
>             } else {
>                 { => input.onDestroy()
>                 }
>             },
>             onError: if(Runtime.isUndefined(input.onError)) {
>                 None
>             } else {
>                 { code: ErrorCode, msg: String => input.onError(code, msg)
>                 }
>             },
>             onTouch: if(Runtime.isUndefined(input.onTouch)) {
>                 None
>             } else {
>                 { => input.onTouch()
>                 }
>             },
>             onEvent: if(Runtime.isUndefined(input.onEvent)) {
>                 None
>             } else {
>                 { e: EventType => input.onEvent(e.get())
>                 }
>             }
>         )
>     }
>
> }
> ```


>> ```cangjie
>> public class TestListener<Runtime> where Runtime <: ArkTS<Runtime>  {
>>
>>     protected TestListener(public var onStart!: Option<() -> Unit> = None,
>>         public var onDestroy!: Option<() -> Unit> = None,
>>         public var onError!: Option<(code: ErrorCode, msg: String) -> Unit> = None,
>>         public var onTouch!: Option<() -> Unit> = None,
>>         public var onEvent!: Option<(e: EventType) -> Unit> = None
>>     ) {}
>>
>>
>>     public func toExtern(): Extern<Runtime> {
>>         let obj = Runtime.object()
>>         if(let Some(v) <- onStart) {
>>             Runtime.eval(MemberUpdate(obj, "onStart", { _: Extern<Runtime> =>
>>                 v()
>>                 Runtime.undefined()
>>             }))
>>         }
>>         if(let Some(v) <- onDestroy) {
>>             Runtime.eval(MemberUpdate(obj, "onDestroy", { _: Extern<Runtime> =>
>>                 v()
>>                 Runtime.undefined()
>>             }))
>>         }
>>         if(let Some(v) <- onError) {
>>             Runtime.eval(MemberUpdate(obj, "onError", { callInfo: Extern<Runtime> =>
>>                 let p0 = Runtime.fromExtern<ErrorCode>(IndexedAccess(callInfo, 0))
>>                 let p1 = Runtime.fromExtern<String>(IndexedAccess(callInfo, 1))
>>                 v(p0, p1)
>>                 Runtime.undefined()
>>             }))
>>         }
>>         if(let Some(v) <- onTouch) {
>>             Runtime.eval(MemberUpdate(obj, "onTouch", { _: Extern<Runtime> =>
>>                 v()
>>                 Runtime.undefined()
>>             }))
>>         }
>>         if(let Some(v) <- onEvent) {
>>             Runtime.eval(MemberUpdate(obj, "onEvent", { callInfo: Extern<Runtime> =>
>>                 let p0 = EventType.parse(Runtime.fromExtern<Int32>(IndexedAccess(callInfo, 0)))
>>                 v(p0)
>>                 Runtime.undefined()
>>             }))
>>         }
>>         obj
>>     }
>>
>>     public static func fromExtern(input: Extern<Runtime>): TestListener<Runtime> {
>>         TestListener(
>>             onStart: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "onStart")))) {
>>                 None
>>             } else {
>>                 { => Runtime.eval(FuncCall(MemberAccess(input, "onStart"), []))
>>                 }
>>             },
>>             onDestroy: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "onDestroy")))) {
>>                 None
>>             } else {
>>                 { => Runtime.eval(FuncCall(MemberAccess(input, "onDestroy"), []))
>>                 }
>>             },
>>             onError: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "onError")))) {
>>                 None
>>             } else {
>>                 { code: ErrorCode, msg: String => Runtime.eval(FuncCall(MemberAccess(input, "onError"), [code, msg]))
>>                 }
>>             },
>>             onTouch: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "onTouch")))) {
>>                 None
>>             } else {
>>                 { => Runtime.eval(FuncCall(MemberAccess(input, "onTouch"), []))
>>                 }
>>             },
>>             onEvent: if(Runtime.isUndefined(Runtime.eval(MemberAccess(input, "onEvent")))) {
>>                 None
>>             } else {
>>                 { e: EventType => Runtime.eval(FuncCall(MemberAccess(input, "onEvent"), [e.get()]))
>>                 }
>>             }
>>         )
>>     }
>>
>> }
>> ```

| | Number of lexical tokens | Diff |
| --- | --- | --- |
| ohos.ark_interop | 702 |  |
| sugared version | 509 | -193 |
| desugared: extern with eval | 670 | -32 |


```cangjie
// NOTE: defined in cangjie_sdk/cangjie_tools/hyperlangExtension/tests/expected/my_module/function_types.cj
public type ErrorCode = Float64
public enum EventType <: ToString & Equatable < EventType > {
    | DefaultEvent 

    func get(): Int32 {
        match(this) {
            case DefaultEvent => 0  //todo: please check the value
        }
    }
    static func parse(val: Int32): EventType {
        match(val) {
            case 0 => DefaultEvent  //todo: please check the value
            case _ => throw IllegalArgumentException("unknown value ${val}")
        }
    }
    public func toString(): String {
        match(this) {
            case DefaultEvent => "DefaultEvent"
        }
    }
    public override operator func ==(that: EventType): Bool {
        match((this, that)) {
            case(DefaultEvent, DefaultEvent) => true
        }
    }
    public override operator func !=(that: EventType): Bool {
        !(this == that)
    }
}
```

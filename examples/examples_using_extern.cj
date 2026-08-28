package ohos_app_cangjie_entry.examples_v1

import ohos_app_cangjie_entry.arkts_runtime_v1.*

// The original examples below are reproduced as shown in:
// https://gitcode.com/Cangjie/cangjie_docs/blob/main/docs/tools/source_zh_cn/cmd-tools/cj-dts2cj-translation-rules.md

// LLM generated ArkTS module compatible with this file is in ExternDeclarationFixtures.ets

// The examples below assume the following definition of ArkTS foreign runtime
class ArkTSNotImplemented <: Exception {}

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
    public static func requireSystemNativeModule(_: String, _: ?String): Extern<T> { throw ArkTSNotImplemented() }
    public static func requireArkModule(specifier: String): Extern<T>
    public static func object(): Extern<T>                                  { throw ArkTSNotImplemented() }
    public static func isUndefined(_: Extern<T>): Bool                      { throw ArkTSNotImplemented() }
    public static func global(): Extern<T>                                  { throw ArkTSNotImplemented() }
}

// ---------------------------------------------
// 1. Helper functions defined in arkcompiler_cangjie_ark_interop/ohos/ark_interop_helper/ark_api_call_async.cj
// ---------------------------------------------

// protected func jsGlobalApiCall<T>(moduleName: String, modulePrefix: ?String, funcName: String,
//     args: (JSContext) -> Array<JSValue>, onResolve: (JSContext, JSValue) -> T): T {
//     func call(context: JSContext): T {
//         let jsModule = getJSModule(context, moduleName, modulePrefix)
//         let jsRet = jsModule.callMethod(funcName, args(context))
//         onResolve(context, jsRet)
//     }
//     checkThreadAndCall<T>(getMainContext(), call)
// }

func jsGlobalApiCall<Runtime, T>(moduleName: String, modulePrefix: ?String, funcName: String,
    args: Array<Extern<Runtime>>, onResolve: (Extern<Runtime>) -> T): T where Runtime <: ArkTS<Runtime> {
    // let jsModule = Runtime.requireSystemNativeModule(moduleName, modulePrefix)
    let jsModule = Runtime.requireArkModule(moduleName) // cannot be bothered to build a system native module and use the above ^^^^^^^
    let function = Runtime.memberAccess(jsModule, funcName)
    let argsAny: Array<Any> = Array<Any>(args.size) { index => args[index] }
    let jsRet = Runtime.functionCall(function, argsAny) // this will run on the main thread
    onResolve(jsRet)
}

// protected func hmsGlobalApiCall<T>(moduleName: String, funcName: String, args: (JSContext) -> Array<JSValue>,
//     onResolve: (JSContext, JSValue) -> T): T {
//     jsGlobalApiCall<T>(moduleName, "hms", funcName, args, onResolve)
// }

func hmsGlobalApiCall<Runtime, T>(moduleName: String, funcName: String, args: Array<Extern<Runtime>>,
    onResolve: (Extern<Runtime>) -> T): T where Runtime <: ArkTS<Runtime> {
    jsGlobalApiCall<Runtime, T>(moduleName, "hms", funcName, args, onResolve)
}

// protected func hmsGlobalApiCall<T>(moduleName: String, funcName: String, args: (JSContext) -> Array<JSValue>): T where T <: JSInteropType<T> {
//     hmsGlobalApiCall<T>(moduleName, funcName, args) {ctx, info => T.fromJSValue(ctx, info)}
// }

func hmsGlobalApiCall<Runtime, T>(moduleName: String, funcName: String, args: Array<Extern<Runtime>>): T where Runtime <: ArkTS<Runtime> {
    hmsGlobalApiCall<Runtime, T>(moduleName, funcName, args) { res => (T)res }
}

// ---------------------------------------------
// Global Functions
// ---------------------------------------------

// public func greeter(fn: (a: String) -> Unit): Unit {
//     hmsGlobalApiCall < Unit >( "_ark_interop_api", "greeter", { ctx =>[ctx.function({ ctx, info =>
//             let p0 = String.fromJSValue(ctx, info[0])
//             fn(p0)
//             ctx.undefined().toJSValue()
//         }).toJSValue()] })
// }

public func greeter<Runtime>(fn: (a: String) -> Unit): Unit where Runtime <: ArkTS<Runtime> {
    hmsGlobalApiCall<Runtime, Unit>( "entry/src/main/ets/poc/ExternDeclarationFixtures", "greeter", [{ info: Extern<Runtime> =>
            let p0: String = (String)info[0]
            fn(p0)
            Runtime.undefined()
        }])
}

public func greeter2<Runtime>(fn: (a: String) -> Unit): Unit where Runtime <: ArkTS<Runtime> {
    let jsModule = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
    let efn: Extern<Runtime> = { arg: Extern<Runtime> =>
        let p0 = (String)arg[0]
        fn(p0)
        Runtime.undefined()
    }
    let res = jsModule.greeter(efn)
    (Unit)res
}

// /**
// * @brief printToConsole(s: string): void
// */
// public func printToConsole(s: String): Unit {
//     hmsGlobalApiCall < Unit >( "_ark_interop_api", "printToConsole", { ctx =>[s.toJSValue(ctx)] })
// }

public func printToConsole<Runtime>(s: String): Unit where Runtime <: ArkTS<Runtime> {
    hmsGlobalApiCall <Runtime, Unit >( "entry/src/main/ets/poc/ExternDeclarationFixtures", "printToConsole", [s])
}

public func printToConsole2<Runtime>(s: String): Unit where Runtime <: ArkTS<Runtime> {
    let jsModule = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
    let res = jsModule.printToConsole(s) // implicit conversion String -> Extern<Runtime>
    (Unit)res
}

// /**
//   * @brief testMultiGenericT(t: T, m: M): T
//   */
// public func testMultiGenericT < T, M >(t: T, m: M): T where T <: JSInteropType<T>, M <: JSInteropType<M> {
//     hmsGlobalApiCall < T >( "my_module_genericFunction", "testMultiGenericT", { ctx =>[t.toJSValue(ctx), m.toJSValue(ctx)] }) {
//         ctx, info => T.fromJSValue(ctx, info)
//     }
// }

public func testMultiGenericT <Runtime, T, M >(t: T, m: M): T where Runtime <: ArkTS<Runtime> {
    hmsGlobalApiCall <Runtime, T >( "entry/src/main/ets/poc/ExternDeclarationFixtures", "testMultiGenericT", [t, m]) {
        res: Extern<Runtime> => (T)res
    }
}

public func testMultiGenericT2 <Runtime, T, M >(t: T, m: M): T where Runtime <: ArkTS<Runtime> {
    let jsModule = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
    let res = jsModule.testMultiGenericT(t, m) // implicit conversion T -> Extern<Runtime>, M -> Extern<Runtime>
    (T)res
}

// ---------------------------------------------
// Basic Types
// ---------------------------------------------

// public class GreetingSettings {

//     protected GreetingSettings(public var greeting: String,
//     public var duration!: Option<Float64> = None,
//     public var color!: Option<String> = None) {}


//     public func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["greeting"] = greeting.toJSValue(context)
//         if(let Some(v) <- duration) {
//             obj["duration"] = v.toJSValue(context)
//         }
//         if(let Some(v) <- color) {
//             obj["color"] = v.toJSValue(context)
//         }
//         obj.toJSValue()
//     }

//     public static func fromJSValue (context: JSContext, input: JSValue): GreetingSettings {
//         let obj = input.asObject()
//         GreetingSettings(
//         String.fromJSValue(context, obj["greeting"]),
//         duration: if(obj["duration"].isUndefined()) {
//             None
//         } else {
//             Float64.fromJSValue(context, obj["duration"])
//         },
//         color: if(obj["color"].isUndefined()) {
//             None
//         } else {
//             String.fromJSValue(context, obj["color"])
//         }
//         )
//     }

// }

public class GreetingSettings<Runtime> where Runtime <: ArkTS<Runtime> {

    protected GreetingSettings(
        public var greeting: String,
        public var duration!: Option<Float64> = None,
        public var color!: Option<String> = None
    ) {}

    public func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.greeting = greeting
        if(let Some(v) <- duration) {
            obj.duration = v
        }
        if(let Some(v) <- color) {
            obj.color = v
        }
        obj
    }

    public static func fromExtern(input: Extern<Runtime>): GreetingSettings<Runtime> {
        GreetingSettings(
            (String)input.greeting,
            duration: if(Runtime.isUndefined(input.duration)) {
                None
            } else {
                (Float64)input.duration
            },
            color: if(Runtime.isUndefined(input.color)) {
                None
            } else {
                (String)input.color
            }
        )
    }

}

// ---------------------------------------------
// #### Optional Properties
// ---------------------------------------------

// public class Product {

//     protected Product(public var price!: Option<Float64> = None) {}


//     public func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         if(let Some(v) <- price) {
//             obj["price"] = v.toJSValue(context)
//         }
//         obj.toJSValue()
//     }

//     public static func fromJSValue (context: JSContext, input: JSValue): Product {
//         let obj = input.asObject()
//         Product(
//         price: if(obj["price"].isUndefined()) {
//             None
//         } else {
//             Float64.fromJSValue(context, obj["price"])
//         }
//         )
//     }

// }

public class Product<Runtime> where Runtime <: ArkTS<Runtime> {

    protected Product(public var price!: Option<Float64> = None) {}

    public func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        if(let Some(v) <- price) {
            obj.price = v
        }
        obj
    }

    public static func fromExtern(input: Extern<Runtime>): Product<Runtime> {
        Product(
        price: if (Runtime.isUndefined(input.price)) {
            None
        } else {
            (Float64)input.price
        }
        )
    }

}

// ---------------------------------------------
// #### Readonly Properties
// ---------------------------------------------

// public class Point {

//     protected Point(public let x: Float64,
//     public let y: Float64) {}


//     public func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["x"] = x.toJSValue(context)
//         obj["y"] = y.toJSValue(context)
//         obj.toJSValue()
//     }

//     public static func fromJSValue (context: JSContext, input: JSValue): Point {
//         let obj = input.asObject()
//         Point(
//         Float64.fromJSValue(context, obj["x"]),
//         Float64.fromJSValue(context, obj["y"])
//         )
//     }

// }

public class Point<Runtime> where Runtime <: ArkTS<Runtime> {

    protected Point(public let x: Float64,
    public let y: Float64) {}


    public func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.x = x
        obj.y = y
        obj
    }

    public static func fromJSValue(input: Extern<Runtime>): Point<Runtime> {
        Point(
        (Float64)input.x,
        (Float64)input.y
        )
    }

}

// ---------------------------------------------
// #### Member Functions
// ---------------------------------------------

// public class Person {

//     protected Person(let arkts_object: JSObject) {}


//     public mut prop name: String {
//         get() {
//             checkThreadAndCall < String >(getMainContext()) {
//                 ctx: JSContext => String.fromJSValue(ctx, arkts_object["name"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => arkts_object["name"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief greet(): String
//     */
//     public func greet(): String {
//         jsObjApiCall < String >( arkts_object, "greet", emptyArg)
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): Person {
//         Person(input.asObject())
//     }
// }

public class Person<Runtime> where Runtime <: ArkTS<Runtime> {
    protected Person(let arkts_object: Extern<Runtime>) {}

    public mut prop name: String {
        get() {
            (String)arkts_object.name
        }
        set(v) {
            arkts_object.name = v
        }

    }

    public func greet(): String {
        (String)arkts_object.greet()
    }

    func toExtern(): Extern<Runtime> {
        arkts_object
    }

    static func fromExtern (input: Extern<Runtime>): Person<Runtime> {
        Person(input)
    }
}

// ---------------------------------------------
// #### Function Overloading
// ---------------------------------------------
// public class Calculator {

//     protected Calculator(let arkts_object: JSObject) {}


//     /**
//     * @brief add(x: number,y: number): number
//     */
//     public func add(x: Float64, y: Float64): Float64 {
//         jsObjApiCall < Float64 >( arkts_object, "add", { ctx =>[x.toJSValue(ctx), y.toJSValue(ctx)] })
//     }
//     /**
//     * @brief add(x: string,y: string): String
//     */
//     public func add(x: String, y: String): String {
//         jsObjApiCall < String >( arkts_object, "add", { ctx =>[x.toJSValue(ctx), y.toJSValue(ctx)] })
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): Calculator {
//         Calculator(input.asObject())
//     }
// }

public class Calculator<Runtime> where Runtime <: ArkTS<Runtime> {

    protected Calculator(let arkts_object: Extern<Runtime>) {}


    /**
    * @brief add(x: number,y: number): number
    */
    public func add(x: Float64, y: Float64): Float64 {
        (Float64)arkts_object.add(x, y)
    }
    /**
    * @brief add(x: string,y: string): String
    */
    public func add(x: String, y: String): String {
        (String)arkts_object.add(x, y)
    }

    func toExtern(): Extern<Runtime> {
        arkts_object
    }

    static func fromJSValue (input: Extern<Runtime>): Calculator<Runtime> {
        Calculator(input)
    }
}

// ---------------------------------------------
// #### Array Types
// ---------------------------------------------
// public class List {

//     protected List(let arkts_object: JSObject) {}


//     public mut prop items: Array<String> {
//         get() {
//             checkThreadAndCall < Array<String> >(getMainContext()) {
//                 ctx: JSContext => Array<String>.fromJSValue(ctx, arkts_object["items"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => arkts_object["items"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief add(item: string): void
//     */
//     public func add(item: String): Unit {
//         jsObjApiCall < Unit >( arkts_object, "add", { ctx =>[item.toJSValue(ctx)] })
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): List {
//         List(input.asObject())
//     }
// }

public class List<Runtime> where Runtime <: ArkTS<Runtime>  {

    protected List(let arkts_object: Extern<Runtime>) {}


    public mut prop items: Array<String> {
        get() {
            (Array<String>)arkts_object.items
        }
        set(v) {
            arkts_object.items = v
        }
        // NOTE: this assume that toExtern converts Array<String> into Extern, and Extern into ArrayString
    }

    /**
    * @brief add(item: string): void
    */
    public func add(item: String): Unit {
        arkts_object.add(item)
    }

    func toExtern(): Extern<Runtime> {
        arkts_object
    }

    static func fromExtern (input: Extern<Runtime>): List<Runtime> {
        List(input)
    }
}

// ---------------------------------------------
// #### Inheritance
// ---------------------------------------------

// public open class A {
    
//     protected A(public var p: Float64) {}
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["p"] = p.toJSValue(context)
//         obj.toJSValue()
//     }
    
//     public static func fromJSValue(context: JSContext, input: JSValue): A {
//         let obj = input.asObject()
//         A(
//         Float64.fromJSValue(context, obj["p"])
//         )
//     }
    
// }

public open class A<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected A(public var p: Float64) {}
    
    
    public open func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.p = p
        obj
    }
    
    public static func fromExtern(input: Extern<Runtime>): A<Runtime> {
        A(
        (Float64)input.p
        )
    }
    
}

// /*interface B {
//     p1: number;
//     }*/

// public open class B <: A {
    
//     protected B(p: Float64,
//     public var p1: Float64) { super(p) }
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["p"] = p.toJSValue(context)
//         obj["p1"] = p1.toJSValue(context)
//         obj.toJSValue()
//     }
    
//     public static func fromJSValue(context: JSContext, input: JSValue): B {
//         let obj = input.asObject()
//         B(
//         Float64.fromJSValue(context, obj["p"]),
//         Float64.fromJSValue(context, obj["p1"])
//         )
//     }
    
// }


/*interface B {
    p1: number;
    }*/

public open class B<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected B(p: Float64,
    public var p1: Float64) { super(p) }
    
    
    public open func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.p = p
        obj.p1 = p1
        obj
    }
    
    public static func fromExtern(input: Extern<Runtime>): B<Runtime> {
        B(
        (Float64)input.p,
        (Float64)input.p1
        )
    }
    
}

// /*interface C {
//     f(): void
//     }*/

// public open class C {
    
//     protected C(public var arkts_object: JSObject) {}
    
    
//     /**
//      * @brief f(): void
//      */
//     public func f(): Unit {
//         jsObjApiCall < Unit >( arkts_object, "f", emptyArg)
//     }
    
//     public open func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }
    
//     static func fromJSValue(context: JSContext, input: JSValue): C {
//         C(input.asObject())
//     }
// }

/*interface C {
    f(): void
    }*/

public open class C<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected C(public var arkts_object: Extern<Runtime>) {}
    
    
    /**
     * @brief f(): void
     */
    public func f(): Unit {
        arkts_object.f()
    }
    
    public open func toExtern(): Extern<Runtime> {
        arkts_object
    }
    
    static func fromExtern(input: Extern<Runtime>): C<Runtime> {
        C(input)
    }
}

// /*interface D {
//     }*/

// public open class D <: C {
    
//     protected D(arkts_object: JSObject) { super(arkts_object) }
    
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }
    
//     static func fromJSValue(context: JSContext, input: JSValue): D {
//         D(input.asObject())
//     }
// }

/*interface D {
    }*/

public open class D<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected D(arkts_object: Extern<Runtime>) { super(arkts_object) }
    
    
    
    public open func toExtern(): Extern<Runtime> {
        arkts_object
    }
    
    static func fromExtern(input: Extern<Runtime>): D<Runtime> {
        D(input)
    }
}

// /*interface E {
//     }*/

// public open class E <: A {
    
//     protected E(p: Float64) { super(p) }
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["p"] = p.toJSValue(context)
//         obj.toJSValue()
//     }
    
//     public static func fromJSValue(context: JSContext, input: JSValue): E {
//         let obj = input.asObject()
//         E(
//         Float64.fromJSValue(context, obj["p"])
//         )
//     }
    
// }

/*interface E {
    }*/

public open class E<Runtime> <: A<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected E(p: Float64) { super(p) }
    
    
    public open func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.p = p
        obj
    }
    
    public static func fromExtern(input: Extern<Runtime>): E<Runtime> {
        E(
        (Float64)input.p
        )
    }
    
}

// /*interface F {
//     g(): void
//     }*/

// public open class F <: C {
    
//     protected F(arkts_object: JSObject) { super(arkts_object) }
    
    
//     /**
//      * @brief g(): void
//      */
//     public func g(): Unit {
//         jsObjApiCall < Unit >( arkts_object, "g", emptyArg)
//     }
    
//     public open func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }
    
//     static func fromJSValue(context: JSContext, input: JSValue): F {
//         F(input.asObject())
//     }
// }

/*interface F {
    g(): void
    }*/

public open class F<Runtime> <: C<Runtime> where Runtime <: ArkTS<Runtime> {
    
    protected F(arkts_object: Extern<Runtime>) { super(arkts_object) }
    
    
    /**
     * @brief g(): void
     */
    public func g(): Unit {
        arkts_object.g()
    }
    
    public open func toExtern(): Extern<Runtime> {
        arkts_object
    }
    
    static func fromExtern(input: Extern<Runtime>): F<Runtime> {
        F(input)
    }
}

// ---------------------------------------------
// #### Nested Objects
// ---------------------------------------------
// public open class AutoGenType0 {
    
//     protected AutoGenType0(public var : String,
//     public var : String) {}
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["city"] = .toJSValue(context)
//         obj["zipCode"] = .toJSValue(context)
//         obj.toJSValue()
//     }
    
//     public static func fromJSValue(context: JSContext, input: JSValue): AutoGenType0 {
//         let obj = input.asObject()
//         AutoGenType0(
//         String.fromJSValue(context, obj["city"]),
//         String.fromJSValue(context, obj["zipCode"])
//         )
//     }
    
// }

public open class AutoGenType0<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected AutoGenType0(public var city: String,
    public var zipCode: String) {}
    

    public open func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.city = city
        obj.zipCode = zipCode
        obj
    }
    
    public static func fromExtern(input: Extern<Runtime>): AutoGenType0<Runtime> {
        AutoGenType0(
        (String)input.city,
        (String)input.zipCode
        )
    }
    
}

// public open class UserProfile {
    
//     protected UserProfile(public var id: Float64,
//     public var name: String,
//     public var address: AutoGenType0) {}
    
    
//     public open func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         obj["id"] = id.toJSValue(context)
//         obj["name"] = name.toJSValue(context)
//         obj["address"] = address.toJSValue(context)
//         obj.toJSValue()
//     }
    
//     public static func fromJSValue(context: JSContext, input: JSValue): UserProfile {
//         let obj = input.asObject()
//         UserProfile(
//         Float64.fromJSValue(context, obj["id"]),
//         String.fromJSValue(context, obj["name"]),
//         AutoGenType0.fromJSValue(context, obj["address"])
//         )
//     }
    
// }


public open class UserProfile<Runtime> where Runtime <: ArkTS<Runtime>  {
    
    protected UserProfile(public var id: Float64,
    public var name: String,
    public var address: AutoGenType0<Runtime>) {}
    
    
    public open func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        obj.id = id
        obj.name = name
        obj.address = address.toExtern()
        obj
    }
    
    public static func fromExtern(input: Extern<Runtime>): UserProfile<Runtime> {
        UserProfile(
        (Float64)input.id,
        (String)input.name,
        AutoGenType0.fromExtern(input.address)
        )
    }
    
}

// ---------------------------------------------
// #### Union Type Aliases
// ---------------------------------------------
// public enum GreetingLike {
//     | STRING(String)
//     | NUMBER(Float64)

//     public func toJSValue(context: JSContext): JSValue {
//         match(this) {
//             case STRING(x) => context.string(x).toJSValue()
//             case NUMBER(x) => context.number(x).toJSValue()
//         }
//     }
// }

public enum GreetingLike<Runtime> where Runtime <: ArkTS<Runtime>  {
    | STRING(String)
    | NUMBER(Float64)

    public func toExtern(): Extern<Runtime> {
        match(this) {
            case STRING(x) =>
                let e: Extern<Runtime> = x
                e
            case NUMBER(x) => 
                let e: Extern<Runtime> = x
                e
        }
    }
}

// ---------------------------------------------
// #### Constructors
// ---------------------------------------------

// public class Greeter {

//     protected Greeter(let arkts_object: JSObject) {}
//     /**
//     * @brief constructor(greeting: string): void
//     */
//     public init(greeting: String) {
//         arkts_object = checkThreadAndCall < JSObject >(getMainContext()) {
//             __ctx =>
//             let clazz = __ctx.global["Greeter"].asClass(__ctx)
//             clazz.new(greeting.toJSValue(__ctx)).asObject()
//         }
//     }

//     public mut prop greeting: String {
//         get() {
//             checkThreadAndCall < String >(getMainContext()) {
//                 ctx: JSContext => String.fromJSValue(ctx, arkts_object["greeting"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => arkts_object["greeting"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief showGreeting(): void
//     */
//     public func showGreeting(): Unit {
//         jsObjApiCall < Unit >( arkts_object, "showGreeting", emptyArg)
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): Greeter {
//         Greeter(input.asObject())
//     }
// }

public class Greeter<Runtime> where Runtime <: ArkTS<Runtime> {

    protected Greeter(_: Unit, let arkts_object: Extern<Runtime>) {}
    /**
    * @brief constructor(greeting: string): void
    */
    public init(greeting: String) {
        arkts_object = Runtime.global().Greeter(greeting)
        // or
        // arkts_object = Runtime.global().Greeter.new(greeting)
    }

    public mut prop greeting: String {
        get() {
            (String)arkts_object.greeting
        }
        set(v) {
            arkts_object.greeting = v
        }

    }

    /**
    * @brief showGreeting(): void
    */
    public func showGreeting(): Unit {
        arkts_object.showGreeting()
    }

    func toExtern(): Extern<Runtime> {
        arkts_object
    }

    static func fromExtern (input: Extern<Runtime>): Greeter<Runtime> {
        Greeter((), input)
    }
}

// ---------------------------------------------
// #### Static Members
// ---------------------------------------------

// public class MathUtils {

//     protected MathUtils(let arkts_object: JSObject) {}

//     // Static property
//     public mut prop PI: Float64 {
//         get() {
//             checkThreadAndCall < Float64 >(getMainContext()) {
//                 ctx: JSContext => Float64.fromJSValue(ctx, getClassConstructorObj("test", "MathUtils")["PI"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => getClassConstructorObj("test", "MathUtils")["PI"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief square(x: number): number
//     */
//     public static func square(x: Float64): Float64 {
//         jsObjApiCall < Float64 >(getClassConstructorObj("test", "MathUtils"),  "square", { ctx =>[x.toJSValue(ctx)] })
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): MathUtils {
//         MathUtils(input.asObject())
//     }
// }

// NOTE: getClassConstructorObj defined in cangjie_sdk/cangjie_tools/hyperlangExtension/src/tool/create_ark_api_call_async.cj

public class MathUtils<Runtime> where Runtime <: ArkTS<Runtime>  {

    protected MathUtils(let arkts_object: Extern<Runtime>) {}

    // Static property
    public mut prop PI: Float64 {
        get() {
            // let module = Runtime.requireSystemNativeModule("test", None)
            let module = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
            (Float64)module.MathUtils.PI
        }
        set(v) {
            // let module = Runtime.requireSystemNativeModule("test", None)
            let module = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
            module.MathUtils.PI = v
        }

    }

    /**
    * @brief square(x: number): number
    */
    public static func square(x: Float64): Float64 {
        // let module = Runtime.requireSystemNativeModule("test", None)
        let module = Runtime.requireArkModule("entry/src/main/ets/poc/ExternDeclarationFixtures")
        (Float64)module.MathUtils.square(x)
    }

    // ...
}

// ---------------------------------------------
// #### Protected Members
// ---------------------------------------------

// public class AnimalProtect {

//     protected AnimalProtect(let arkts_object: JSObject) {}

//     // Protected property
//     public mut prop name: String {
//         get() {
//             checkThreadAndCall < String >(getMainContext()) {
//                 ctx: JSContext => String.fromJSValue(ctx, arkts_object["name"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => arkts_object["name"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief makeSound(): void
//     */
//     public func makeSound(): Unit {
//         jsObjApiCall < Unit >( arkts_object, "makeSound", emptyArg)
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue (context: JSContext, input: JSValue): AnimalProtect {
//         AnimalProtect(input.asObject())
//     }
// }

public class AnimalProtect<Runtime> where Runtime <: ArkTS<Runtime>  {

    protected AnimalProtect(let arkts_object: Extern<Runtime>) {}

    // Protected property
    public mut prop name: String {
        get() {
            (String)arkts_object.name
        }
        set(v) {
            arkts_object.name = v
        }

    }

    /**
    * @brief makeSound(): void
    */
    public func makeSound(): Unit {
        arkts_object.makeSound()
    }

    // ...
}

// ---------------------------------------------
// #### Generic Members
// ---------------------------------------------

// public class BBox<T> {

//     protected BBox(let arkts_object: JSObject) {}

//     // Property
//     public mut prop value: T {
//         get() {
//             checkThreadAndCall < T >(getMainContext()) {
//                 ctx: JSContext => T.fromJSValue(ctx, arkts_object["value"])
//             }
//         }
//         set(v) {
//             checkThreadAndCall < Unit >(getMainContext()) {
//                 ctx: JSContext => arkts_object["value"] = v.toJSValue(ctx)
//             }
//         }

//     }

//     /**
//     * @brief getValue(): T
//     */
//     public func getValue(): T {
//         jsObjApiCall < T >( arkts_object, "getValue", emptyArg) {
//             ctx, info => T.fromJSValue(ctx, info)
//         }
//     }

//     func toJSValue(context: JSContext): JSValue {
//         arkts_object.toJSValue()
//     }

//     static func fromJSValue <T>(context: JSContext, input: JSValue): BBox<T> {
//         BBox(input.asObject())
//     }
// }

public class BBox<Runtime, T> where Runtime <: ArkTS<Runtime>  {

    protected BBox(let arkts_object: Extern<Runtime>) {}

    // Property
    public mut prop value: T {
        get() {
            (T)arkts_object.value
        }
        set(v) {
            arkts_object.value = v
        }

    }

    /**
    * @brief getValue(): T
    */
    public func getValue(): T {
        (T)arkts_object.getValue()
    }

    // ...
}

// ---------------------------------------------
// ### Function Types
// #### Interface Properties
// ---------------------------------------------

// public class TestListener {

//     protected TestListener(public var onStart!: Option<() -> Unit> = None,
//     public var onDestroy!: Option<() -> Unit> = None,
//     public var onError!: Option<(code: ErrorCode, msg: String) -> Unit> = None,
//     public var onTouch!: Option<() -> Unit> = None,
//     public var onEvent!: Option<(e: EventType) -> Unit> = None) {}


//     public func toJSValue(context: JSContext): JSValue {
//         let obj = context.object()
//         if(let Some(v) <- onStart) {
//             obj["onStart"] = context.function({ ctx, _ =>
//                 v()
//                 ctx.undefined().toJSValue()
//             }).toJSValue()
//         }
//         if(let Some(v) <- onDestroy) {
//             obj["onDestroy"] = context.function({ ctx, _ =>
//                 v()
//                 ctx.undefined().toJSValue()
//             }).toJSValue()
//         }
//         if(let Some(v) <- onError) {
//             obj["onError"] = context.function({ ctx, info =>
//                 let p0 = ErrorCode.fromJSValue(ctx, info[0])
//                 let p1 = String.fromJSValue(ctx, info[1])
//                 v(p0, p1)
//                 ctx.undefined().toJSValue()
//             }).toJSValue()
//         }
//         if(let Some(v) <- onTouch) {
//             obj["onTouch"] = context.function({ ctx, _ =>
//                 v()
//                 ctx.undefined().toJSValue()
//             }).toJSValue()
//         }
//         if(let Some(v) <- onEvent) {
//             obj["onEvent"] = context.function({ ctx, info =>
//                 let p0 = EventType.parse(Int32.fromJSValue(ctx, info[0]))
//                 v(p0)
//                 ctx.undefined().toJSValue()
//             }).toJSValue()
//         }
//         obj.toJSValue()
//     }

//     public static func fromJSValue (context: JSContext, input: JSValue): TestListener {
//         let obj = input.asObject()
//         TestListener(
//         onStart: if(obj["onStart"].isUndefined()) {
//             None
//         } else {
//             { =>
//                 checkThreadAndCall < Unit >(context, { _ =>
//                     obj["onStart"].asFunction().call()
//                 })
//             }
//         },
//         onDestroy: if(obj["onDestroy"].isUndefined()) {
//             None
//         } else {
//             { =>
//                 checkThreadAndCall < Unit >(context, { _ =>
//                     obj["onDestroy"].asFunction().call()
//                 })
//             }
//         },
//         onError: if(obj["onError"].isUndefined()) {
//             None
//         } else {
//             { code: ErrorCode, msg: String =>
//                 checkThreadAndCall < Unit >(context, { ctx =>
//                     let arg0 = code.toJSValue(ctx)
//                     let arg1 = msg.toJSValue(ctx)
//                     obj["onError"].asFunction().call([arg0, arg1])
//                 })
//             }
//         },
//         onTouch: if(obj["onTouch"].isUndefined()) {
//             None
//         } else {
//             { =>
//                 checkThreadAndCall < Unit >(context, { _ =>
//                     obj["onTouch"].asFunction().call()
//                 })
//             }
//         },
//         onEvent: if(obj["onEvent"].isUndefined()) {
//             None
//         } else {
//             { e: EventType =>
//                 checkThreadAndCall < Unit >(context, { ctx =>
//                     let arg0 = e.get().toJSValue(ctx)
//                     obj["onEvent"].asFunction().call([arg0])
//                 })
//             }
//         }
//         )
//     }

// }

public class TestListener<Runtime> where Runtime <: ArkTS<Runtime>  {

    protected TestListener(public var onStart!: Option<() -> Unit> = None,
        public var onDestroy!: Option<() -> Unit> = None,
        public var onError!: Option<(code: ErrorCode, msg: String) -> Unit> = None,
        public var onTouch!: Option<() -> Unit> = None,
        public var onEvent!: Option<(e: EventType) -> Unit> = None
    ) {}


    public func toExtern(): Extern<Runtime> {
        let obj = Runtime.object()
        if(let Some(v) <- onStart) {
            obj.onStart = { _: Extern<Runtime> =>
                v()
                Runtime.undefined()
            }
        }
        if(let Some(v) <- onDestroy) {
            obj.onDestroy = { _: Extern<Runtime> =>
                v()
                Runtime.undefined()
            }
        }
        if(let Some(v) <- onError) {
            obj.onError = { info: Extern<Runtime> =>
                let p0 = (ErrorCode)info[0]
                let p1 = (String)info[1]
                v(p0, p1)
                Runtime.undefined()
            }
        }
        if(let Some(v) <- onTouch) {
            obj.onTouch = { _: Extern<Runtime> =>
                v()
                Runtime.undefined()
            }
        }
        if(let Some(v) <- onEvent) {
            obj.onEvent = { info: Extern<Runtime> =>
                let p0 = EventType.parse((Int32)info[0])
                v(p0)
                Runtime.undefined()
            }
        }
        obj
    }

    public static func fromExtern(input: Extern<Runtime>): TestListener<Runtime> {
        TestListener(
            onStart: if(Runtime.isUndefined(input.onStart)) {
                None
            } else {
                { => input.onStart()
                }
            },
            onDestroy: if(Runtime.isUndefined(input.onDestroy)) {
                None
            } else {
                { => input.onDestroy()
                }
            },
            onError: if(Runtime.isUndefined(input.onError)) {
                None
            } else {
                { code: ErrorCode, msg: String => input.onError(code, msg)
                }
            },
            onTouch: if(Runtime.isUndefined(input.onTouch)) {
                None
            } else {
                { => input.onTouch()
                }
            },
            onEvent: if(Runtime.isUndefined(input.onEvent)) {
                None
            } else {
                { e: EventType => input.onEvent(e.get())
                }
            }
        )
    }

}

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

main () {}

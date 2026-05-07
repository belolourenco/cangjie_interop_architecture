package prototype2

import std.ast.*
import std.convert.*

type Handle = Int64

class ExternConversionException <: Exception {
    ExternConversionException(message: String) {
        super(message)
    }
}

class ExternDynamicException <: Exception {
    ExternDynamicException(message: String) {
        super(message)
    }
}

public interface Runtime<T> {
    static func instance() : Runtime<T>
    func eval(e: Expr): Handle
    func serialize<R>(e: Handle): R
    func deserialize<R>(e: R): Handle
}

public struct Extern<T> where T <: Runtime<T> {
    Extern(let handle : Handle) { }
}

private struct Wrapped<T> {}

public class ArkTSRuntime <: Runtime<ArkTSRuntime> {
    private static var singleton : Option<ArkTSRuntime> = None

    private let pool: ArrayList<Token> = ArrayList<Token>()

    private init() {}

    static public func instance() : ArkTSRuntime {
        match(singleton) {
            case Some(i) => i
            case None => let i = ArkTSRuntime()
                         singleton = Some(i)
                         i
        }
    }

    public func eval(expr: Expr): Handle {
        match(expr) {
            case lit: LitConstExpr =>
                pool.add(lit.literal)
                pool.size - 1
            case _ => throw ExternDynamicException("Expression not supported by ArkTSRuntime")
        }
    }

    public func serialize<T>(h: Handle): T {
        let token : Token = pool[h]
        match (Wrapped<T>()) {
            case _ : Wrapped<String> => (token.value as T).getOrThrow()
            case _ : Wrapped<Int8> => (Int8.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Int16> => (Int16.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Int32> => (Int32.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Int64> => (Int64.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<UInt8> => (UInt8.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<UInt16> => (UInt16.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<UInt32> => (UInt32.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<UInt64> => (UInt64.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Float32> => (Float32.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Float64> => (Float64.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Bool> => (Bool.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Rune> => (Rune.parse(token.value) as T).getOrThrow()
            case _ : Wrapped<Unit> => (() as T).getOrThrow()
            case _ => throw ExternConversionException("Type not supported by ArkTSRuntime")
        }
    }

    public func deserialize<T>(_: T): Handle {
        0
    }
}

main() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.instance().eval(parseExpr(quote(42))))

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = ArkTSRuntime.instance().serialize(arkTs_fourty_two.handle)

    println(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.instance().eval(parseExpr(quote("Hello World!"))))

    // let hello_world : String = ArkTSRuntime.instance().serialize(arkTs_hello_world)
    // ->
    let hello_world : String = ArkTSRuntime.instance().serialize(arkTs_hello_world.handle)

    println(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<ArkTSRuntime> = 1
    // ->
    let arkTs_one : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.instance().eval(parseExpr(quote(1))))

    // let one : UInt8 = ArkTSRuntime.instance().serialize(arkTs_one)
    // ->
    let one : UInt8 = ArkTSRuntime.instance().serialize(arkTs_one.handle)

    println(one)
}
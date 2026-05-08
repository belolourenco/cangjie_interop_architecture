package prototype1

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
    // static func instance() : T
    static func eval(e: Expr): Handle
    static func fromExtern<R>(h: Handle): R
    static func toExtern<R>(v: R): Handle
}

public struct Extern<T> where T <: Runtime<T> {
    Extern(let handle : Handle) { }
}

private func decomposeFieldAccess(memberAccess: MemberAccess): (Handle, ArrayList<String>) {
    let fields: ArrayList<String> = ArrayList<String>()
    fields.add(memberAccess.field.value)
    var baseExpr = memberAccess.baseExpr
    while(baseExpr is MemberAccess) {
        let memberAccess = (baseExpr as MemberAccess).getOrThrow()
        fields.add(memberAccess.field.value)
        baseExpr = memberAccess.baseExpr
    }
    let handle = match (baseExpr) {
        case lit: LitConstExpr => match (lit.literal.kind) {
            case INTEGER_LITERAL => Int64.parse(lit.literal.value)
            case _ => throw ExternDynamicException("Base expression not supported by ArkTSRuntime: ${memberAccess.toTokens().toString()}")
        }
        case _ => throw ExternDynamicException("Base expression not supported by ArkTSRuntime: ${memberAccess.toTokens().toString()}")
    }
    fields.reverse()
    (handle, fields)
}

private func decomposeArguments(arguments: ArrayList<Argument>): ArrayList<Handle> {
    let handles: ArrayList<Handle> = ArrayList<Handle>()
    for (argument in arguments) {
        match (argument.expr) {
            case lit: LitConstExpr => match (lit.literal.kind) {
                case INTEGER_LITERAL => handles.add(Int64.parse(lit.literal.value))
                case _ => throw ExternDynamicException("Argument not supported by ArkTSRuntime: ${argument.expr.toTokens().toString()}")
            }
            case _ => throw ExternDynamicException("Argument not supported by ArkTSRuntime: ${argument.expr.toTokens().toString()}")
        }
    }
    handles
}

abstract public class ArkTSRuntime <: Runtime<ArkTSRuntime> {
    // private static var singleton : ArkTSRuntime = ArkTSRuntime()

    private static let pool: ArrayList<Any> = ArrayList<Any>()

    private init() {}

    static func getModule(moduleName: String): Handle {
        match (moduleName) {
            case "geocoding" => ArkTSRuntime.toExtern({ symbolName: String => 
                    match (symbolName) {
                        case "lookup" => ArkTSRuntime.toExtern({ lat: Handle, long: Handle => toExtern((fromExtern<Float32>(lat), fromExtern<Float32>(long))) })
                        case _ => throw ExternDynamicException("Function not found: ${symbolName}")
                    }
                })
            case _ => throw ExternDynamicException("Module not found: ${moduleName}")
        }
    }
    
    static private func performCall(handle: Handle, fields: ArrayList<String>, arguments: ArrayList<Handle>): Handle {
        let f = fromExtern<(String) -> Handle>(handle)
        let handle2 = f(fields[0])
        let f2 = fromExtern<(Handle, Handle) -> Handle>(handle2)
        f2(arguments[0], arguments[1])
    }

    public static func eval(expr: Expr): Handle {
        match(expr) {
            case lit: LitConstExpr =>
                pool.add(lit.literal)
                pool.size - 1
            case call: CallExpr =>
                let (baseExpr, fields) = match (call.callFunc) {
                    case memberAccess: MemberAccess => decomposeFieldAccess(memberAccess)
                    case _ => throw ExternDynamicException("Call function not supported by ArkTSRuntime: ${call.toTokens().toString()}")
                }
                let arguments = decomposeArguments(call.arguments)
                performCall(baseExpr, fields, arguments)
            case _ => throw ExternDynamicException("Expression not supported by ArkTSRuntime: ${expr.dump()}")
            // case _ => throw ExternDynamicException("Expression not supported by ArkTSRuntime: ${expr.toTokens().toString()}")
        }
    }

    public static func fromExtern<T>(h: Handle): T {
        (pool[h] as T).getOrThrow()
    }

    public static func toExtern<T>(v: T): Handle {
        pool.add(v)
        pool.size - 1
    }
}

func lookup(lat: Float32, long: Float32): Extern<ArkTSRuntime> {
    let extModule : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.getModule("geocoding"))
    // let extLookup : Extern<ArkTSRuntime> = extModule.lookup(lat, long)
    let e_lat = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(lat))
    let e_long = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(long))
    Extern<ArkTSRuntime>(ArkTSRuntime.eval(parseExpr(quote($(extModule.handle).lookup($(e_lat.handle), $(e_long.handle))))))
}

main() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(42))

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = ArkTSRuntime.fromExtern(arkTs_fourty_two.handle)

    println(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern("Hello World!"))

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = ArkTSRuntime.fromExtern(arkTs_hello_world.handle)

    println(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<ArkTSRuntime> = 1u8
    // ->
    let arkTs_one : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(1u8))

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = ArkTSRuntime.fromExtern(arkTs_one.handle)

    println(one)

    // ---- var Int64 ----
    let x: Int64 = 101
    
    // let arkTs_x: Extern<ArkTSRuntime> = x
    // ->
    let arkTs_x: Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(x))

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = ArkTSRuntime.fromExtern(arkTs_x.handle)

    println(x_2)

    // ---- lookup ----
    let result: Extern<ArkTSRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = ArkTSRuntime.fromExtern(result.handle)
    println("(${result_value[0]}, ${result_value[1]})")

}
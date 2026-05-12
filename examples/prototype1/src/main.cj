package prototype1

import prototype1.extern.*
import prototype1.dummy_runtime.*

import std.ast.*
import std.convert.*

func lookup(lat: Float32, long: Float32): Extern<ArkTSRuntime> {
    let extModule : Extern<ArkTSRuntime> = ArkTSRuntime.getModule("geocoding")
    // let extLookup : Extern<ArkTSRuntime> = extModule.lookup(lat, long)
    let e_lat = ArkTSRuntime.toExtern(lat)
    let e_long = ArkTSRuntime.toExtern(long)
    ArkTSRuntime.eval(parseExpr(quote(extModule.lookup($(lat), $(long)))))
    Extern<ArkTSRuntime>(0)
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

main() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(42)

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = ArkTSRuntime.fromExtern(arkTs_fourty_two)

    println(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern("Hello World!")

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = ArkTSRuntime.fromExtern(arkTs_hello_world)

    println(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<ArkTSRuntime> = 1u8
    // ->
    let arkTs_one : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(1u8)

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = ArkTSRuntime.fromExtern(arkTs_one)

    println(one)

    // ---- var Int64 ----
    let x: Int64 = 101
    
    // let arkTs_x: Extern<ArkTSRuntime> = x
    // ->
    let arkTs_x: Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(x)

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = ArkTSRuntime.fromExtern(arkTs_x)

    println(x_2)

    // ---- lookup ----
    // let result: Extern<ArkTSRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    // let result_value: (Float32, Float32) = ArkTSRuntime.fromExtern<(Float32, Float32)>(result)
    // println("(${result_value[0]}, ${result_value[1]})")

}
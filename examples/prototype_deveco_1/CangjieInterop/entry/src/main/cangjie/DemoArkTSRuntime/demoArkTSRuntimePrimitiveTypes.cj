package ohos_app_cangjie_entry.DemoArkTSRuntime

import ohos_app_cangjie_entry.Extern.Extern
import ohos_app_cangjie_entry.ArkTSRuntime.ArkTSRuntime
import ohos_app_cangjie_entry.Extern.mylog
import std.math.numeric.BigInt

public func demoArkTSRuntimeTestPrimitives() {
    testBool()
    testString()
    testInt8()
    testInt32()
    testInt64()
    testBigInt()
    testFloat16()
    testFloat32()
    testFloat64()
}

func testBool() {
    mylog("---- Bool ----")
    // let arkTs_true_bool: Extern<ArkTSRuntime> = true
    // ->
    let arkTs_true_bool : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(true)

    // let true_bool : Bool = arkTs_true_bool
    // ->
    let true_bool : Bool = ArkTSRuntime.fromExtern<Bool>(arkTs_true_bool)
    mylog("Bool true: ${true_bool}")

    // let arkTs_false_bool: Extern<ArkTSRuntime> = false
    // ->
    let arkTs_false_bool : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(false)

    // let false_bool : Bool = arkTs_false_bool
    // ->
    let false_bool : Bool = ArkTSRuntime.fromExtern<Bool>(arkTs_false_bool)
    mylog("Bool false: ${false_bool}")
}

func testString() {
    mylog("---- String ----")
    // let arkTs_hello_string: Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_string : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern("Hello World!")

    // let hello_string : String = arkTs_hello_string
    // ->
    let hello_string : String = ArkTSRuntime.fromExtern<String>(arkTs_hello_string)
    mylog("String: ${hello_string}")
}

func testInt8() {
    mylog("---- Int8 ----")
    // let arkTs_fourty_two_from_int8: Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two_from_int8 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Int8(42))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int8)
     mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int8)
     mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int8)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int8)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int8)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int8)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int8)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int8)
     mylog("Float64: ${fourty_two_float64}")
}

func testInt32() {
    mylog("---- Int32 ----")
    // let arkTs_fourty_two_from_int32: Extern<ArkTSRuntime> = Int32.Max
    // ->
    let arkTs_fourty_two_from_int32 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Int32.Max)

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int32
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int32)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int8: expected overflow")
    }

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int32
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int32)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int32
    // ->
    let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int32)
    mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int32)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int32)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int32)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int32)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int32)
     mylog("Float64: ${fourty_two_float64}")

}

func testInt64() {
    mylog("---- Int64 ----")
    // let arkTs_fourty_two_from_int64: Extern<ArkTSRuntime> = Int64.Max
    // ->
    let arkTs_fourty_two_from_int64 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Int64.Max)

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int64)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int8: expected overflow")
    }

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int64)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int64)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int32: expected overflow")
    }

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int64)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int64)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int64)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int64)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int64)
     mylog("Float64: ${fourty_two_float64}")
}

func testBigInt() {
    mylog("---- Int64 ----")
    let bi = BigInt(Int64.Max) + BigInt(1)
    // let arkTs_fourty_two_from_bigInt: Extern<ArkTSRuntime> = bi
    // ->
    let arkTs_fourty_two_from_bigInt : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(bi)

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_bigInt)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int8: expected overflow")
    }

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_bigInt)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_bigInt)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int32: expected overflow")
    }

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_bigInt)
        throw Exception("Should not happen!")
    } catch (e: OverflowException) {
        mylog("Int64: expected overflow")
    }

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_bigInt)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_bigInt)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_bigInt)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_bigInt)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat16() {
    mylog("---- Float16 ----")
    // let arkTs_fourty_two_from_float16: Extern<ArkTSRuntime> = Float16(42.4242)
    // ->
    let arkTs_fourty_two_from_float16 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Float16(42.4242))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float16
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float16)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float16
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float16)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float16)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float16)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float16)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float16)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float16)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float16)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat32() {
    mylog("---- Float32 ----")
    // let arkTs_fourty_two_from_float32: Extern<ArkTSRuntime> = Float32(42.4242)
    // ->
    let arkTs_fourty_two_from_float32 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Float32(42.4242))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float32
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float32)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float32
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float32)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float32)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float32)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float32)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float32)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float32)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float32)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat64() {
    mylog("---- Float64 ----")
    // let arkTs_fourty_two_from_float64: Extern<ArkTSRuntime> = Float64(42.4242)
    // ->
    let arkTs_fourty_two_from_float64 : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(Float64(42.4242))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float64
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float64)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float64
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float64)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float64)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float64)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float64)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float64)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float64)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float64)
     mylog("Float64: ${fourty_two_float64}")
}
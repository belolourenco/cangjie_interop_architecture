package ohos_app_cangjie_entry

import ohos_app_cangjie_entry.Extern.*
import ohos_app_cangjie_entry.DummyRuntime.*

import std.collection.ArrayList

import ohos.ark_interop.JSModule
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSCallInfo
import ohos.ark_interop.JSValue
import ohos_app_cangjie_entry.ArkTSRuntime.ArkTSRuntime
import std.math.numeric.BigInt
import ohos.ark_interop.JSRuntime
import ohos.arkui.state_management.AppStorage

class Assert {
    public static func isUnreachable(reason!: String = "") {
        mylog("unreachable, ${reason}")
        throw Exception()
    }
}

func testCJ(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    try {
//        dummy_demo_entry_point()
        // arkts_demo_entry_point()
        mytest(runtime)
    } catch (e: Exception) {
        mylog(printStackTrace(e))
    }
    let result = "Hello ${callInfo[0].toString()}"
    runtime.string(result).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["testCJ"] = runtime.function(testCJ).toJSValue()
}

func mytest(context: JSContext) {
//    let jsRuntime = JSRuntime()
//    let context2 = jsRuntime.mainContext

    // ---- ArkTS Module ----
    let arktsModule = context.requireArkModule("entry/src/main/ets/my_arkts_module").asObject()

    // ---- my_arkts_function ----
    arktsModule["my_arkts_function"].asFunction().call()

    // ---- Lookup ----
    let lat = context.number(42.4242).toJSValue()
    let long = context.number(1.111).toJSValue()
    let lookupResultValue = arktsModule["lookup"].asFunction().call([lat, long])
    let lookupResultObject = lookupResultValue.asObject()
    mylog("Lookup result: ${lookupResultObject.keys()}")

    let coordinatesJSValue = lookupResultObject.getProperty("coordinates")
    let nameJSValue = lookupResultObject.getProperty("name")
    let cityJSValue = lookupResultObject.getProperty("city")
    let categoryJSValue = lookupResultObject.getProperty("category")

    let coordinates = coordinatesJSValue.asArray()
    let name = nameJSValue.asString()
    let city = cityJSValue.asString()
    let category = categoryJSValue.asString()
    mylog("Coordinates: (${coordinates[0].asNumber().toFloat64()}, ${coordinates[1].asNumber().toFloat64()}), Name: ${name}, City: ${city}, Category: ${category}")


    // ---- Rectangle ----
    let widthJSValue = context.number(10).toJSValue()
    let heightJSValue = context.number(11).toJSValue()
    let rectangleJSValue = arktsModule["Rectangle"].asClass().new([widthJSValue, heightJSValue])
    let rectangleObject = rectangleJSValue.asObject()

    let rectangleWidth = rectangleObject.callMethod("getWidth", []).asNumber().toFloat64()
    mylog("Rectangle width: ${rectangleWidth}")
    let rectangleHeight = rectangleObject.callMethod("getHeight", []).asNumber().toFloat64()
    mylog("Rectangle height: ${rectangleHeight}")

    // ---- createRectangle ----
    let widthJSValue2 = context.number(12).toJSValue()
    let heightJSValue2 = context.number(13).toJSValue()
    let rectangleJSValue2 = arktsModule["createRectangle"].asFunction().call()
    let rectangleObject2 = rectangleJSValue2.asObject()

    let rectangleWidth2 = rectangleObject2.callMethod("getWidth", []).asNumber().toFloat64()
    mylog("Rectangle width: ${rectangleWidth2}")
    let rectangleHeight2 = rectangleObject2.callMethod("getHeight", []).asNumber().toFloat64()
    mylog("Rectangle height: ${rectangleHeight2}")
}

func arkts_demo_entry_point() {
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
    let arkTs_true_bool : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(true))

    // let true_bool : Bool = arkTs_true_bool
    // ->
    let true_bool : Bool = ArkTSRuntime.fromExtern<Bool>(arkTs_true_bool.handle)
    mylog("Bool true: ${true_bool}")

    // let arkTs_false_bool: Extern<ArkTSRuntime> = false
    // ->
    let arkTs_false_bool : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(false))

    // let false_bool : Bool = arkTs_false_bool
    // ->
    let false_bool : Bool = ArkTSRuntime.fromExtern<Bool>(arkTs_false_bool.handle)
    mylog("Bool false: ${false_bool}")
}

func testString() {
    mylog("---- String ----")
    // let arkTs_hello_string: Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_string : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern("Hello World!"))

    // let hello_string : String = arkTs_hello_string
    // ->
    let hello_string : String = ArkTSRuntime.fromExtern<String>(arkTs_hello_string.handle)
    mylog("String: ${hello_string}")
}

func testInt8() {
    mylog("---- Int8 ----")
    // let arkTs_fourty_two_from_int8: Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two_from_int8 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Int8(42)))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int8.handle)
     mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int8.handle)
     mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int8.handle)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int8.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int8.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int8.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int8.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int8
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int8.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func testInt32() {
    mylog("---- Int32 ----")
    // let arkTs_fourty_two_from_int32: Extern<ArkTSRuntime> = Int32.Max
    // ->
    let arkTs_fourty_two_from_int32 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Int32.Max))
    
    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int32
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int32.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int8: expected overflow")
    }
    
    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int32
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int32.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int32
    // ->
    let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int32.handle)
    mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int32.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int32.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int32.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int32.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int32
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int32.handle)
     mylog("Float64: ${fourty_two_float64}")

}

func testInt64() {
    mylog("---- Int64 ----")
    // let arkTs_fourty_two_from_int64: Extern<ArkTSRuntime> = Int64.Max
    // ->
    let arkTs_fourty_two_from_int64 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Int64.Max))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_int64.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int8: expected overflow")
    }

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_int64.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_int64
    // ->
    try {
        let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_int64.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int32: expected overflow")
    }

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_int64.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_int64.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_int64.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_int64.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_int64
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_int64.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func testBigInt() {
    mylog("---- Int64 ----")
    let bi = BigInt(Int64.Max) + BigInt(1)
    // let arkTs_fourty_two_from_bigInt: Extern<ArkTSRuntime> = bi
    // ->
    let arkTs_fourty_two_from_bigInt : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(bi))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_bigInt.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int8: expected overflow")
    }

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_bigInt.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int16: expected overflow")
    }

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_bigInt.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int32: expected overflow")
    }

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_bigInt
    // ->
    try {
        let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_bigInt.handle)
        Assert.isUnreachable()
    } catch (e: Exception) {
        mylog("Int64: expected overflow")
    }

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_bigInt.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_bigInt.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_bigInt.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_bigInt
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_bigInt.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat16() {
    mylog("---- Float16 ----")
    // let arkTs_fourty_two_from_float16: Extern<ArkTSRuntime> = Float16(42.4242)
    // ->
    let arkTs_fourty_two_from_float16 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Float16(42.4242)))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float16
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float16.handle)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float16
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float16.handle)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float16.handle)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float16.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float16.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float16.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float16.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float16
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float16.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat32() {
    mylog("---- Float32 ----")
    // let arkTs_fourty_two_from_float32: Extern<ArkTSRuntime> = Float32(42.4242)
    // ->
    let arkTs_fourty_two_from_float32 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Float32(42.4242)))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float32
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float32.handle)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float32
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float32.handle)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float32.handle)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float32.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float32.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float32.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float32.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float32
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float32.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func testFloat64() {
    mylog("---- Float64 ----")
    // let arkTs_fourty_two_from_float64: Extern<ArkTSRuntime> = Float64(42.4242)
    // ->
    let arkTs_fourty_two_from_float64 : Extern<ArkTSRuntime> = Extern<ArkTSRuntime>(ArkTSRuntime.toExtern(Float64(42.4242)))

    // let fourty_two_int8 : Int8 = arkTs_fourty_two_from_float64
    // ->
    let fourty_two_int8 : Int8 = ArkTSRuntime.fromExtern<Int8>(arkTs_fourty_two_from_float64.handle)
    mylog("Int8: ${fourty_two_int8}")

    // let fourty_two_int16 : Int16 = arkTs_fourty_two_from_float64
    // ->
    let fourty_two_int16 : Int16 = ArkTSRuntime.fromExtern<Int16>(arkTs_fourty_two_from_float64.handle)
    mylog("Int16: ${fourty_two_int16}")

    // let fourty_two_int32 : Int32 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_int32 : Int32 = ArkTSRuntime.fromExtern<Int32>(arkTs_fourty_two_from_float64.handle)
     mylog("Int32: ${fourty_two_int32}")

    // let fourty_two_int64 : Int64 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_int64 : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two_from_float64.handle)
     mylog("Int64: ${fourty_two_int64}")

    // let fourty_two_bigInt : BigInt = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_bigInt : BigInt = ArkTSRuntime.fromExtern<BigInt>(arkTs_fourty_two_from_float64.handle)
     mylog("BigInt: ${fourty_two_bigInt}")

    // let fourty_two_float16 : Float16 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float16 : Float16 = ArkTSRuntime.fromExtern<Float16>(arkTs_fourty_two_from_float64.handle)
     mylog("Float16: ${fourty_two_float16}")

    // let fourty_two_float32 : Float32 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float32 : Float32 = ArkTSRuntime.fromExtern<Float32>(arkTs_fourty_two_from_float64.handle)
     mylog("Float32: ${fourty_two_float32}")

    // let fourty_two_float64 : Float64 = arkTs_fourty_two_from_float64
    // ->
     let fourty_two_float64 : Float64 = ArkTSRuntime.fromExtern<Float64>(arkTs_fourty_two_from_float64.handle)
     mylog("Float64: ${fourty_two_float64}")
}

func lookup(lat: Float32, long: Float32): Extern<DummyRuntime> {
    let extModule: Extern<DummyRuntime> = DummyRuntime.getModule("geocoding") // I'm not sure about this!

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(lat))
    let e_long: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(long))
    Extern<DummyRuntime>(DummyRuntime.eval(Call(extModule.handle, ArrayList<String>(["lookup"]), ArrayList<Handle>([e_lat.handle, e_long.handle]))))
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    public let blob : Extern<DummyRuntime>
    public init(x: Float64, y: Float64) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Point(x, y)
        // ->
        blob = Extern<DummyRuntime>(DummyRuntime.eval(Call(shapeModule.handle, ArrayList<String>(["Point"]), ArrayList<Handle>([DummyRuntime.toExtern(x), DummyRuntime.toExtern(y)]))))
    }

    public init(extern: Extern<DummyRuntime>) {
        blob = extern
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["x"])))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.x = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["x"]), DummyRuntime.toExtern(v)))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["y"])))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.y = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["y"]), DummyRuntime.toExtern(v)))
        }
    }
}

class Rectangle {
    private var blob : Extern<DummyRuntime>
    public Rectangle(topLeft: Point, bottomRight: Point) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Rectangle(topLeft, bottomRight)
        // ->
        blob = Extern<DummyRuntime>(DummyRuntime.eval(Call(shapeModule.handle, ArrayList<String>(["Rectangle"]), ArrayList<Handle>([topLeft.blob.handle, bottomRight.blob.handle]))))
    }

    public mut prop topLeft: Point {
        get() {
            // blob.topLeft
            // ->
            let topLeft_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["topLeft"])))
            Point(Extern<DummyRuntime>(topLeft_handle))
        }
        set(v) {
            // blob.topLeft = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["topLeft"]), v.blob.handle))
        }
    }

    public mut prop bottomRight: Point {
        get() {
            // blob.bottomRight
            // ->
            let bottomRight_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["bottomRight"])))
            Point(Extern<DummyRuntime>(bottomRight_handle))
        }
        set(v) {
            // blob.bottomRight = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["bottomRight"]), v.blob.handle))
        }
    }

    public func perimeter(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.perimeter())
        // ->
        let perimeter_handle: Handle = DummyRuntime.eval(Call(blob.handle, ArrayList<String>(["perimeter"]), ArrayList<Handle>([])))
        DummyRuntime.fromExtern<Float64>(perimeter_handle)
    }

    public func area(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.area())
        // ->
        let perimeter_handle: Handle = DummyRuntime.eval(Call(blob.handle, ArrayList<String>(["area"]), ArrayList<Handle>([])))
        DummyRuntime.fromExtern<Float64>(perimeter_handle)
    }

}

func dummy_demo_entry_point() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<DummyRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(42))

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = DummyRuntime.fromExtern(arkTs_fourty_two.handle)

    mylog(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<DummyRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern("Hello World!"))

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = DummyRuntime.fromExtern(arkTs_hello_world.handle)

    mylog(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<DummyRuntime> = 1u8
    // ->
    let arkTs_one : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(1u8))

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = DummyRuntime.fromExtern(arkTs_one.handle)

    mylog(one)

    // ---- var Int64 ----
    let x: Int64 = 101

    // let arkTs_x: Extern<DummyRuntime> = x
    // ->
    let arkTs_x: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(x))

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = DummyRuntime.fromExtern(arkTs_x.handle)

    mylog(x_2)

    // ---- lookup ----
    let result: Extern<DummyRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = DummyRuntime.fromExtern(result.handle)
    mylog("(${result_value[0]}, ${result_value[1]})")

    // ---- Point ----
    let point: Point = Point(3.0, 4.0)

    mylog("Point: (${point.x}, ${point.y})")

    point.x = 5.0
    point.y = 6.0

    mylog("Point: (${point.x}, ${point.y})")

    // ---- Rectangle ----
    let rectangle: Rectangle = Rectangle(Point(0.0, 0.0), Point(10.0, 10.0))

    mylog("Rectangle 1: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    rectangle.topLeft = Point(1.0, 1.0)
    rectangle.bottomRight = Point(9.0, 9.0)

    mylog("Rectangle 2: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    rectangle.topLeft.x = 2.0
    rectangle.bottomRight.y = 8.0

    mylog("Rectangle 3: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    // mylog("Rectangle perimeter: ${rectangle.perimeter()}")
    // mylog("Rectangle area: ${rectangle.area()}")

    // mylog("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}, ${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
}

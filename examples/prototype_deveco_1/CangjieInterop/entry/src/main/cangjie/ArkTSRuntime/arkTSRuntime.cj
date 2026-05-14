package ohos_app_cangjie_entry.ArkTSRuntime

import ohos_app_cangjie_entry.Extern.*
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSRuntime
import std.collection.ArrayList
import ohos.ark_interop.JSValue
import std.math.numeric.BigInt

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

    rectangleObject2.setProperty("width", context.number(42).toJSValue())

    let rectangleWidth2 = rectangleObject2.getProperty("width").asNumber().toFloat64()
    mylog("Rectangle width: ${rectangleWidth2}")
    let rectangleHeight2 = rectangleObject2.getProperty("height").asNumber().toFloat64()
    mylog("Rectangle height: ${rectangleHeight2}")

    let area = rectangleObject2.callMethod("area", []).asNumber().toFloat64()
    mylog("Rectangle area: ${area}")
    let perimeter = rectangleObject2.callMethod("perimeter", []).asNumber().toFloat64()
    mylog("Rectangle perimeter: ${perimeter}")
}

private func js2cangjie<T>(value: JSValue, cjType: Option<T>) {
    match(cjType) {
        case _: Option<Bool> =>
            if (value.isBoolean()) {
                return (value.toBoolean() as T).getOrThrow()
            }
        case _: Option<String> =>
            if (value.isString()) {
                return (value.toString() as T).getOrThrow()
            }
        case _: Option<Int8> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Int8(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toInt8()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Int16> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Int16(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toInt16()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Int32> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Int32(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toInt32()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Int64> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Int64(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toInt64()
                return (bigint as T).getOrThrow()
            }
        case _: Option<BigInt> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (BigInt(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Float16> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Float16(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toFloat16()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Float32> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Float32(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toFloat32()
                return (bigint as T).getOrThrow()
            }
        case _: Option<Float64> =>
            if (value.isNumber()) {
                let number = value.toNumber()
                return (Float64(number) as T).getOrThrow()
            } else if (value.isBigInt()) {
                let bigint = value.toBigInt().toFloat64()
                return (bigint as T).getOrThrow()
            }
        case _ => ()
    }
    throw ExternConversionException("Unsupported type conversion by ArkTSRuntime")
}

abstract public class ArkTSRuntime <: Runtime<ArkTSRuntime> {

    private static let jsRuntime = JSRuntime()
    public static var context = jsRuntime.mainContext
    
    private static let pool = ArrayList<JSValue>()

    // TODO: remove this!
    public static func runDummyTest() {
        mytest(context)
    }

    public static func evalMemberAccess(e: Extern<ArkTSRuntime>, field: String): Extern<ArkTSRuntime> {
        throw ExternDynamicException("")
    }

    public static func evalFunctionCall(e: Extern<ArkTSRuntime>, args: Array<Any>): Extern<ArkTSRuntime> {
        let jsValue = pool[e.handle]
        throw ExternDynamicException("")
    }

    public static func evalAssignment  (e: Extern<ArkTSRuntime>, field: String, value: Any): Unit {
        let jsValue = pool[e.handle]
        throw ExternDynamicException("")
    }

    public static func evalIndexAccess (e: Extern<ArkTSRuntime>, arg: Any): Extern<ArkTSRuntime> {
        throw ExternDynamicException("")
    }

    public static func getModule(moduleName: String): Extern<ArkTSRuntime> {
        let module = context.requireArkModule(moduleName)
        pool.add(module)
        Extern<ArkTSRuntime>(pool.size - 1)
    }

    public static func fromExtern<T>(e: Extern<ArkTSRuntime>): T {
        let dummy : Option<T> = None
        let value = pool[e.handle]
        js2cangjie(value, dummy)
    }

    public static func toExtern<T>(v: T): Extern<ArkTSRuntime> {
        match(v) {
            case i: Int8 =>
                pool.add(context.number(Int32(i)).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case i: Int16 =>
                pool.add(context.number(Int32(i)).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case i: Int32 =>
                pool.add(context.number(i).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case i: Int64 =>
                pool.add(context.bigint(i).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case i: BigInt =>
                pool.add(context.bigint(i).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case f: Float16 =>
                pool.add(context.number(Float64(f)).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case f: Float32 =>
                pool.add(context.number(Float64(f)).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case f: Float64 =>
                pool.add(context.number(f).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case b: Bool =>
                pool.add(context.boolean(b).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case s: String =>
                pool.add(context.string(s).toJSValue())
                Extern<ArkTSRuntime>(pool.size - 1)
            case _ => throw ExternConversionException("Unsupported type by ArkTSRuntime")
        }
    }
}
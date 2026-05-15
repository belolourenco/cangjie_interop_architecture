package ohos_app_cangjie_entry.ArkTSRuntime

import ohos_app_cangjie_entry.Extern.*
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSRuntime
import std.collection.ArrayList
import ohos.ark_interop.JSValue
import std.math.numeric.BigInt
import ohos.ark_interop.JSObject
import ohos.ark_interop.JSFunction

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

    private static func toJSValue(v: Any): JSValue {
        match(v) {
            case e: Extern<ArkTSRuntime> =>
                (e.content as JSValue).getOrThrow()
            case jsValue: JSValue =>
                jsValue
            case i: Int8 =>
                context.number(Int32(i)).toJSValue()
            case i: Int16 =>
                context.number(Int32(i)).toJSValue()
            case i: Int32 =>
                context.number(i).toJSValue()
            case i: Int64 =>
                context.bigint(i).toJSValue()
            case i: BigInt =>
                context.bigint(i).toJSValue()
            case f: Float16 =>
                context.number(Float64(f)).toJSValue()
            case f: Float32 =>
                context.number(Float64(f)).toJSValue()
            case f: Float64 =>
                context.number(f).toJSValue()
            case b: Bool =>
                context.boolean(b).toJSValue()
            case s: String =>
                context.string(s).toJSValue()
            case _ => throw ExternConversionException("Unsupported type by ArkTSRuntime")
        }
    }

    public static func evalMemberAccess(e: Extern<ArkTSRuntime>, field: String): Extern<ArkTSRuntime> {
        match(e.content) {
            case jsValue: JSValue =>
                let fieldValue = jsValue.asObject()[field]
                if (fieldValue.isFunction() && !fieldValue.isClass()) {
                    Extern((fieldValue.asFunction(), jsValue))
                } else {
                    Extern(fieldValue)
                }
            case _ => throw Exception("Not supposed to happen!")
        }
    }

    public static func evalFunctionCall(e: Extern<ArkTSRuntime>, args: Array<Any>): Extern<ArkTSRuntime> {
        match(e.content) {
            case methodAndThis: (JSFunction, JSValue) =>
                let result = methodAndThis[0].call(args.map(toJSValue), thisArg: methodAndThis[1])
                Extern(result)
            case jsValue: JSValue =>
                // if (jsValue.isClass()) {
                    // I don't understand why this works, but it does!
                    let jsClass = jsValue.asClass()
                    Extern(jsClass.new(args.map(toJSValue)))
                // } else if (jsValue.isObject()) {
                //     mylog("HMM, here is an object")
                //     let jsObject = jsValue.asFunction()
                //     Extern(jsObject.call(args.map(toJSValue)))
                // } else if (jsValue.isFunction()) {
                //     mylog("HMM, here is a function")
                //     let jsFunction = jsValue.asFunction()
                //     Extern(jsFunction.call(args.map(toJSValue)))
                // } else {
                //     throw ExternDynamicException("Expected function or class, got ${jsValue.typeof().toString()}")
                // }
            case _ => throw Exception("Not supposed to happen!")
        }
    }

    public static func evalAssignment  (e: Extern<ArkTSRuntime>, field: String, value: Any): Unit {
        match((e.content as JSValue).getOrThrow().asObject()) {
            case jsObject: JSObject =>
                jsObject.setProperty(field, toJSValue(value))
            case _ => throw ExternDynamicException("Unsupported assignment!")
        }
    }

    public static func evalIndexAccess (e: Extern<ArkTSRuntime>, arg: Any): Extern<ArkTSRuntime> {
        let array = (e.content as JSValue).getOrThrow().asArray()
        // TODO: deal with non Int arguments?!?!! Not sure if this or just change the argument type to Int64?
        Extern(array[(arg as Int64).getOrThrow()])
    }

    public static func getModule(moduleName: String): Extern<ArkTSRuntime> {
        let module = context.requireArkModule(moduleName)
        Extern<ArkTSRuntime>(module)
    }

    public static func fromExtern<T>(e: Extern<ArkTSRuntime>): T {
        let dummy : Option<T> = None
        let value = (e.content as JSValue).getOrThrow()
        js2cangjie(value, dummy)
    }

    public static func toExtern<T>(v: T): Extern<ArkTSRuntime> {
        Extern(toJSValue(v))
    }
}
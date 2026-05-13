package ohos_app_cangjie_entry.ArkTSRuntime

import ohos_app_cangjie_entry.Extern.*
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSRuntime
import std.collection.ArrayList
import ohos.ark_interop.JSValue
import std.math.numeric.BigInt

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

abstract public class ArkTSRuntime <: Runtime {

    private static let jsRuntime = JSRuntime()
    private static let context = jsRuntime.mainContext
    
    private static let pool = ArrayList<JSValue>()

    public static func eval(expr: Expr): Handle {
        0
    }

    public static func fromExtern<T>(h: Handle): T {
        let dummy : Option<T> = None
        let value = pool[h]
        js2cangjie(value, dummy)
    }

    public static func toExtern<T>(v: T): Handle {
        match(v) {
            case i: Int8 =>
                pool.add(context.number(Int32(i)).toJSValue())
                pool.size - 1
            case i: Int16 =>
                pool.add(context.number(Int32(i)).toJSValue())
                pool.size - 1
            case i: Int32 =>
                pool.add(context.number(i).toJSValue())
                pool.size - 1
            case i: Int64 =>
                pool.add(context.bigint(i).toJSValue())
                pool.size - 1
            case i: BigInt =>
                pool.add(context.bigint(i).toJSValue())
                pool.size - 1
            case f: Float16 =>
                pool.add(context.number(Float64(f)).toJSValue())
                pool.size - 1
            case f: Float32 =>
                pool.add(context.number(Float64(f)).toJSValue())
                pool.size - 1
            case f: Float64 =>
                pool.add(context.number(f).toJSValue())
                pool.size - 1
            case b: Bool =>
                pool.add(context.boolean(b).toJSValue())
                pool.size - 1
            case s: String =>
                pool.add(context.string(s).toJSValue())
                pool.size - 1
            case _ => throw ExternConversionException("Unsupported type by ArkTSRuntime")
        }
    }
}
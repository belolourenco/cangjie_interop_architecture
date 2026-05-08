package prototype2.dummy_runtime

import prototype2.extern.*

import std.collection.HashMap
import std.ast.*
import std.convert.*

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
            case _ => throw ExternDynamicException("Base expression not supported by DummyRuntime: ${memberAccess.toTokens().toString()}")
        }
        case _ => throw ExternDynamicException("Base expression not supported by DummyRuntime: ${memberAccess.toTokens().toString()}")
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
                case _ => throw ExternDynamicException("Argument not supported by DummyRuntime: ${argument.expr.toTokens().toString()}")
            }
            case _ => throw ExternDynamicException("Argument not supported by DummyRuntime: ${argument.expr.toTokens().toString()}")
        }
    }
    handles
}

abstract public class DummyRuntime <: Runtime {

    private static let pool: ArrayList<Any> = ArrayList<Any>()

    private static let modules: HashMap<String, Handle> =
        HashMap<String, Handle>([(
            "geocoding",
            DummyRuntime.toExtern({ symbolName: String =>
                match (symbolName) {
                    case "lookup" => DummyRuntime.toExtern({ lat: Handle, long: Handle => toExtern((fromExtern<Float32>(lat), fromExtern<Float32>(long))) })
                    case _ => throw ExternDynamicException("Function not found: ${symbolName}")
                }
            })
        ), (
            "shape",
            DummyRuntime.toExtern({ symbolName: String =>
                match (symbolName) {
                    case "Point" => DummyRuntime.toExtern({ x: Handle, y: Handle => toExtern(Point(fromExtern<Float64>(x), fromExtern<Float64>(y))) })
                    case "Rectangle" => DummyRuntime.toExtern({ topLeft: Handle, bottomRight: Handle => toExtern(Rectangle(fromExtern<Point>(topLeft), fromExtern<Point>(bottomRight))) })
                    case "Circle" => DummyRuntime.toExtern({ center: Handle, radius: Handle => toExtern(Circle(fromExtern<Point>(center), fromExtern<Float64>(radius))) })
                    case "Triangle" => DummyRuntime.toExtern({ a: Handle, b: Handle, c: Handle => toExtern(Triangle(fromExtern<Point>(a), fromExtern<Point>(b), fromExtern<Point>(c))) })
                    case _ => throw ExternDynamicException("Function not found: ${symbolName}")
                }
            })
        )])

    static public func getModule(moduleName: String): Extern<DummyRuntime> {
        try {
            Extern<DummyRuntime>(modules[moduleName])
        } catch (e: NoneValueException) {
            throw ExternDynamicException("Module not found: ${moduleName}")
        }
    }
    
    static private func performCall(handle: Handle, fields: ArrayList<String>, arguments: ArrayList<Handle>): Handle {
        let f = fromExtern<(String) -> Handle>(handle)
        let handle2 = f(fields[0])
        let f2 = fromExtern<(Handle, Handle) -> Handle>(handle2)
        f2(arguments[0], arguments[1])
    }

    static private func performFieldAccess(handle: Handle, fields: ArrayList<String>): Handle {
        let value = pool[handle]
        match (value) {
            case point: Point =>
                match (fields[0]) {
                    case "x" => toExtern(point.x)
                    case "y" => toExtern(point.y)
                    case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                }
            case _ => throw ExternDynamicException("Value not supported by DummyRuntime")
        }

    }

    public static func eval(expr: Expr): Handle {
        match(expr) {
            case lit: LitConstExpr =>
                pool.add(lit.literal)
                pool.size - 1
            case call: CallExpr =>
                let (baseExpr, fields) = match (call.callFunc) {
                    case memberAccess: MemberAccess => decomposeFieldAccess(memberAccess)
                    case _ => throw ExternDynamicException("Call function not supported by DummyRuntime: ${call.toTokens().toString()}")
                }
                let arguments = decomposeArguments(call.arguments)
                performCall(baseExpr, fields, arguments)
            case memberAccess: MemberAccess =>
                let (baseExpr, fields) = decomposeFieldAccess(memberAccess)
                performFieldAccess(baseExpr, fields)
            case _ => throw ExternDynamicException("Expression not supported by DummyRuntime: ${expr.dump()}")
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
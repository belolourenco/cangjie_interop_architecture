package ohos_app_cangjie_entry.DummyRuntime

import ohos_app_cangjie_entry.Extern.*

import std.collection.ArrayList

abstract public class DummyRuntime <: Runtime {

    private static func lookup_impl(lat: Handle, long: Handle): Handle {
        mylog("lookup_impl")
        toExtern<(Float32, Float32)>((fromExtern<Float32>(lat), fromExtern<Float32>(long)))
    }

    private static let geocodingModule: (String) -> Any = { symbolName: String =>
        match (symbolName) {
            case "lookup" => lookup_impl
            case _ => throw ExternDynamicException("Function not found: ${symbolName}")
        }
    }

    private static func point_impl(x: Handle, y: Handle): Handle {
        toExtern(Point(fromExtern<Float64>(x), fromExtern<Float64>(y)))
    }

    private static func rectangle_impl(topLeft: Handle, bottomRight: Handle): Handle {
        toExtern(Rectangle(fromExtern<Point>(topLeft), fromExtern<Point>(bottomRight)))
    }

    private static func circle_impl(center: Handle, radius: Handle): Handle {
        toExtern(Circle(fromExtern<Point>(center), fromExtern<Float64>(radius)))
    }

    private static func triangle_impl(a: Handle, b: Handle, c: Handle): Handle {
        toExtern(Triangle(fromExtern<Point>(a), fromExtern<Point>(b), fromExtern<Point>(c)))
    }

    private static let shapeModule: (String) -> Any = { symbolName: String =>
       match (symbolName) {
           case "Point" => point_impl
           case "Rectangle" => rectangle_impl
           case "Circle" => circle_impl
           case "Triangle" => triangle_impl
           case _ => throw ExternDynamicException("Function not found: ${symbolName}")
       }
    }

    private static let pool: ArrayList<Any> = ArrayList<Any>([(), geocodingModule, shapeModule])
    static public func getModule(moduleName: String): Extern<DummyRuntime> {
        match (moduleName) {
            case "geocoding" => Extern<DummyRuntime>(1)
            case "shape" => Extern<DummyRuntime>(2)
            case _ => throw ExternDynamicException("Module not found: ${moduleName}")
        }
    }

    static private func resolveField(handle: Handle, fields: ArrayList<String>): Any {
        var value = pool[handle]
        var it = 0
        while (it < fields.size) {
            match (value) {
                case point: Point =>
                    match (fields[it]) {
                        case "x" => value = point.x
                        case "y" => value = point.y
                        case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                    }
                case rectangle: Rectangle =>
                    match (fields[it]) {
                        case "topLeft" => value = rectangle.topLeft
                        case "bottomRight" => value = rectangle.bottomRight
                        case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                    }
                case module: (String) -> Any =>
                    value = module(fields[it])
                case _ => throw ExternDynamicException("Value not supported by DummyRuntime")
            }
            it++
        }
        if (it == fields.size) {
            return value
        } else {
            throw ExternDynamicException("Field not found: ${fields}")
        }
    }

    static private func performCall(handle: Handle, fields: ArrayList<String>, arguments: ArrayList<Handle>): Handle {
        let function = resolveField(handle, fields)
        match (function) {
            case function: () -> Handle => function()
            case function: (Handle) -> Handle => function(arguments[0])
            case function: (Handle, Handle) -> Handle => function(arguments[0], arguments[1])
            case _ => throw ExternDynamicException("Function not found: ${(function as ToString).getOrThrow()}")
        }
    }

    static private func performFieldAccess(handle: Handle, fields: ArrayList<String>): Handle {
        toExtern(resolveField(handle, fields))
    }

    static private func performAssignment(handle: Handle, fields: ArrayList<String>, value: Handle): Handle {
        var content = pool[handle]
        var it = 0
        while (it < fields.size) {
            match (content) {
                case point: Point =>
                    if (it != fields.size - 1) {
                        throw ExternDynamicException("Field not found: ${fields}")
                    } else {
                        match (fields[it]) {
                            case "x" =>
                                point.x = fromExtern<Float64>(value)
                            case "y" =>
                                point.y = fromExtern<Float64>(value)
                            case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                        }
                    }
                case rectangle: Rectangle =>
                    if (it == fields.size - 1) {
                        match (fields[it]) {
                            case "topLeft" =>
                                rectangle.topLeft = fromExtern<Point>(value)
                            case "bottomRight" =>
                                rectangle.bottomRight = fromExtern<Point>(value)
                            case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                        }
                    } else {
                        match (fields[it]) {
                            case "topLeft" =>
                                println("topLeft")
                                content = rectangle.topLeft
                            case "bottomRight" =>
                                println("bottomRight")
                                content = rectangle.bottomRight
                            case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                        }
                    }
                case _ => throw ExternDynamicException("Unsupported assignment by DummyRuntime")
            }
            it++
        }
        return 0
    }

    public static func eval(expr: Expr): Handle {
        mylog("eval: ${expr.toString()}")
        match(expr) {
            case Call(baseExpr, fields, arguments) => performCall(baseExpr, fields, arguments)
            case FieldAccess(baseExpr, fields) => performFieldAccess(baseExpr, fields)
            case Assignment(baseExpr, fields, value) => performAssignment(baseExpr, fields, value)
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
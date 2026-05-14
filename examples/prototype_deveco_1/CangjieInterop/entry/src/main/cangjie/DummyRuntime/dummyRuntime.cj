package ohos_app_cangjie_entry.DummyRuntime

import ohos_app_cangjie_entry.Extern.*

import std.collection.ArrayList

abstract public class DummyRuntime <: Runtime<DummyRuntime> {

    private static func lookup_impl(lat: Extern<DummyRuntime>, long: Extern<DummyRuntime>): Extern<DummyRuntime> {
        mylog("lookup_impl")
        toExtern<(Float32, Float32)>((fromExtern<Float32>(lat), fromExtern<Float32>(long)))
    }

    private static let geocodingModule: (String) -> Any = { symbolName: String =>
        match (symbolName) {
            case "lookup" => lookup_impl
            case _ => throw ExternDynamicException("Function not found: ${symbolName}")
        }
    }

    private static func point_impl(x: Extern<DummyRuntime>, y: Extern<DummyRuntime>): Extern<DummyRuntime> {
        toExtern(Point(fromExtern<Float64>(x), fromExtern<Float64>(y)))
    }

    private static func rectangle_impl(topLeft: Extern<DummyRuntime>, bottomRight: Extern<DummyRuntime>): Extern<DummyRuntime> {
        toExtern(Rectangle(fromExtern<Point>(topLeft), fromExtern<Point>(bottomRight)))
    }

    private static func circle_impl(center: Extern<DummyRuntime>, radius: Extern<DummyRuntime>): Extern<DummyRuntime> {
        toExtern(Circle(fromExtern<Point>(center), fromExtern<Float64>(radius)))
    }

    private static func triangle_impl(a: Extern<DummyRuntime>, b: Extern<DummyRuntime>, c: Extern<DummyRuntime>): Extern<DummyRuntime> {
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

    public static func evalFunctionCall(e: Extern<DummyRuntime>, args: Array<Any>): Extern<DummyRuntime> {
        var value = pool[e.handle]
        match (value) {
            case function: () -> Extern<DummyRuntime> => function()
            case function: (Extern<DummyRuntime>) -> Extern<DummyRuntime> => function((args[0] as Extern<DummyRuntime>).getOrThrow())
            case function: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> => function((args[0] as Extern<DummyRuntime>).getOrThrow(), (args[1] as Extern<DummyRuntime>).getOrThrow())
            case _ => throw ExternDynamicException("Function not found!")
        }
    }

    public static func evalIndexAccess (e: Extern<DummyRuntime>, arg: Any): Extern<DummyRuntime> {
        throw ExternDynamicException("Index access not supported by DummyRuntime")
    }

    public static func evalMemberAccess(e: Extern<DummyRuntime>, field: String): Extern<DummyRuntime> {
    // static private func performFieldAccess(handle: Handle, fields: ArrayList<String>): Handle {
        var value = pool[e.handle]
        match (value) {
            case point: Point =>
                match (field) {
                    case "x" => return toExtern(point.x)
                    case "y" => return toExtern(point.y)
                    case _ => throw ExternDynamicException("Field not found: ${field}")
                }
            case rectangle: Rectangle =>
                match (field) {
                    case "topLeft" => return toExtern(rectangle.topLeft)
                    case "bottomRight" => return toExtern(rectangle.bottomRight)
                    case _ => throw ExternDynamicException("Field not found: ${field}")
                }
            case module: (String) -> Any => return toExtern(module(field))
            case _ => throw ExternDynamicException("Value not supported by DummyRuntime")
        }
    }

    public static func evalAssignment(e: Extern<DummyRuntime>, field: String, value: Any): Unit {
    // static private func performAssignment(handle: Handle, fields: ArrayList<String>, value: Handle): Handle {
        var content = pool[e.handle]
        match (content) {
            case point: Point =>
                match (field) {
                    case "x" =>
                        point.x = fromExtern<Float64>((value as Extern<DummyRuntime>).getOrThrow())
                    case "y" =>
                        point.y = fromExtern<Float64>((value as Extern<DummyRuntime>).getOrThrow())
                    case _ => throw ExternDynamicException("Field not found: ${field}")
                }
            case rectangle: Rectangle =>
                match (field) {
                    case "topLeft" =>
                        rectangle.topLeft = fromExtern<Point>((value as Extern<DummyRuntime>).getOrThrow())
                    case "bottomRight" =>
                        rectangle.bottomRight = fromExtern<Point>((value as Extern<DummyRuntime>).getOrThrow())
                    case _ => throw ExternDynamicException("Field not found: ${field}")
                }
            case _ => throw ExternDynamicException("Unsupported assignment by DummyRuntime")
        }
    }

    public static func fromExtern<T>(e: Extern<DummyRuntime>): T {
        (pool[e.handle] as T).getOrThrow()
    }

    public static func toExtern<T>(v: T): Extern<DummyRuntime> {
        pool.add(v)
        Extern(pool.size - 1)
    }
}
package prototype4.dummy_runtime

import prototype4.extern.*

import std.collection.ArrayList

abstract public class DummyRuntime <: Runtime<DummyRuntime> {

    private static let geocodingModule: (String) -> Any = { symbolName: String =>
        match (symbolName) {
            case "lookup" =>
                let lookup: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> = { lat: Extern<DummyRuntime>, long: Extern<DummyRuntime> =>
                    toExtern((fromExtern<Float32>(lat), fromExtern<Float32>(long)))}
                lookup
            case _ => throw ExternDynamicException("Function not found: ${symbolName}")
        }
    }

    private static let shapeModule: (String) -> Any = { symbolName: String =>
        match (symbolName) {
            case "Point" => 
                let pointConstructor: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> = { x: Extern<DummyRuntime>, y: Extern<DummyRuntime> =>
                toExtern(Point(fromExtern<Float64>(x), fromExtern<Float64>(y)))}
                pointConstructor
            case "Rectangle" =>
                let rectangleConstructor: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> = { topLeft: Extern<DummyRuntime>, bottomRight: Extern<DummyRuntime> =>
                toExtern(Rectangle(fromExtern<Point>(topLeft), fromExtern<Point>(bottomRight))) }
                rectangleConstructor
            case "Circle" =>
                let circleConstructor: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> = { center: Extern<DummyRuntime>, radius: Extern<DummyRuntime> =>
                toExtern(Circle(fromExtern<Point>(center), fromExtern<Float64>(radius))) }
                circleConstructor
            case "Triangle" =>
                let triangleConstructor: (Extern<DummyRuntime>, Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> = { a: Extern<DummyRuntime>, b: Extern<DummyRuntime>, c: Extern<DummyRuntime> =>
                toExtern(Triangle(fromExtern<Point>(a), fromExtern<Point>(b), fromExtern<Point>(c))) }
                triangleConstructor
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

    static private func resolveField(extern: Extern<DummyRuntime>, fields: ArrayList<String>): Any {
        var value = pool[extern.handle]
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
    
    static private func performCall(handle: Extern<DummyRuntime>, fields: ArrayList<String>, arguments: ArrayList<Extern<DummyRuntime>>): Extern<DummyRuntime> {
        let function = resolveField(handle, fields)
        match (function) {
            case function: () -> Extern<DummyRuntime> => function()
            case function: (Extern<DummyRuntime>) -> Extern<DummyRuntime> => function(arguments[0])
            case function: (Extern<DummyRuntime>, Extern<DummyRuntime>) -> Extern<DummyRuntime> => function(arguments[0], arguments[1])
            case _ => throw ExternDynamicException("Function not found: ${(function as ToString).getOrThrow()}")
        }
    }

    static private func performFieldAccess(handle: Extern<DummyRuntime>, fields: ArrayList<String>): Extern<DummyRuntime> {
        toExtern(resolveField(handle, fields))
    }

    static private func performAssignment(extern: Extern<DummyRuntime>, fields: ArrayList<String>, value: Extern<DummyRuntime>): Extern<DummyRuntime> {
        var content = pool[extern.handle]
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
        Extern<DummyRuntime>(0)
    }

    public static func eval(expr: Expr<DummyRuntime>): Extern<DummyRuntime> {
        match(expr) {
            case Call(baseExpr, fields, arguments) => performCall(baseExpr, fields, arguments)
            case FieldAccess(baseExpr, fields) => performFieldAccess(baseExpr, fields)
            case Assignment(baseExpr, fields, value) => performAssignment(baseExpr, fields, value)
        }
    }

    public static func fromExtern<T>(extern: Extern<DummyRuntime>): T {
        (pool[extern.handle] as T).getOrThrow()
    }

    public static func toExtern<T>(v: T): Extern<DummyRuntime> {
        pool.add(v)
        Extern<DummyRuntime>(pool.size - 1)
    }
}
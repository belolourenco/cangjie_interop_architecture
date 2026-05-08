package prototype3.dummy_runtime

import prototype3.extern.*

import std.collection.ArrayList
import std.collection.HashMap

abstract public class DummyRuntime <: Runtime {

    private static let pool: ArrayList<Any> = ArrayList<Any>([()])

    private static let modules: HashMap<String, Handle> =
        HashMap<String, Handle>([(
            "geocoding",
            DummyRuntime.toExtern({ symbolName: String =>
                match (symbolName) {
                    case "lookup" => DummyRuntime.toExtern({ lat: Handle, long: Handle =>
                            toExtern((fromExtern<Float32>(lat), fromExtern<Float32>(long))) 
                        })
                    case _ => throw ExternDynamicException("Function not found: ${symbolName}")
                }
            })
        ), (
            "shape",
            DummyRuntime.toExtern({ symbolName: String =>
                match (symbolName) {
                    case "Point" => DummyRuntime.toExtern({ x: Handle, y: Handle => toExtern(Point(fromExtern<Float64>(x), fromExtern<Float64>(y)))})
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
        match (pool[handle]) {
            case module: (String) -> Handle =>
                let functionHandle = module(fields[0])
                match (pool[functionHandle]) {
                    case function: (Handle, Handle) -> Handle =>
                        function(arguments[0], arguments[1])
                    case _ => throw ExternDynamicException("Function not found: ${functionHandle}")
                }
            case _ => throw ExternDynamicException("Function not found: ${handle}")
        }
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

    static private func performAssignment(handle: Handle, fields: ArrayList<String>, value: Handle): Handle {
        let content = pool[handle]
        match (content) {
            case point: Point =>
                match (fields[0]) {
                    case "x" => 
                        point.x = fromExtern<Float64>(value)
                        0
                    case "y" =>
                        point.y = fromExtern<Float64>(value)
                        0
                    case _ => throw ExternDynamicException("Field not found: ${fields[0]}")
                }
            case _ => throw ExternDynamicException("Value ${value} not supported by DummyRuntime")   
        }
    }

    public static func eval(expr: Expr): Handle {
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
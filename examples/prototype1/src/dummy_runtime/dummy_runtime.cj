package prototype1.dummy_runtime

import prototype1.extern.*
import std.ast.*

abstract public class ArkTSRuntime <: Runtime<ArkTSRuntime> {
    // private static var singleton : ArkTSRuntime = ArkTSRuntime()

    private static let pool: ArrayList<Any> = ArrayList<Any>()

    private init() {}

    static public func getModule(moduleName: String): Extern<ArkTSRuntime> {
        match (moduleName) {
            case "geocoding" => ArkTSRuntime.toExtern({ symbolName: String => 
                    match (symbolName) {
                        case "lookup" => ArkTSRuntime.toExtern({ lat: Extern<ArkTSRuntime>, long: Extern<ArkTSRuntime> => 
                            pool.add((lat, long))
                            Extern<ArkTSRuntime>(pool.size - 1)
                        })
                        case _ => throw ExternDynamicException("Function not found: ${symbolName}")
                    }
                })
            case _ => throw ExternDynamicException("Module not found: ${moduleName}")
        }
    }

    public static func eval(expr: Expr): Extern<ArkTSRuntime> {
        match(expr) {
            case lit: LitConstExpr =>
                pool.add(lit.literal)
                Extern<ArkTSRuntime>(pool.size - 1)
            case _ => throw ExternDynamicException("Expression not supported by ArkTSRuntime")
        }
    }

    public static func fromExtern<T>(e: Extern<ArkTSRuntime>): T {
        (pool[e.handle] as T).getOrThrow()
    }

    public static func toExtern<T>(v: T): Extern<ArkTSRuntime> {
        pool.add(v)
        Extern<ArkTSRuntime>(pool.size - 1)
    }
}
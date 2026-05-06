package prototype2

import std.ast.Expr

type Handle = Int64

class ExternConversionException <: Exception {
    ExternConversionException(message: String) {
        super(message)
    }
}

class ExternDynamicException <: Exception {
    ExternDynamicException(message: String) {
        super(message)
    }
}

public interface Runtime<T> where T <: Runtime<T>{
    static func instance() : T
    func eval(e: Expr): Extern<T>
    func serialize<R>(e: Extern<T>): R
    func deserialize<R>(e: R): Extern<T>
}

public struct Extern<T> where T <: Runtime<T> {
    Extern(let handle : Handle) { }
}

public class ArkTSRuntime <: Runtime<ArkTSRuntime> {
    private static var singleton : Option<ArkTSRuntime> = None

    private init() {}

    static public func instance() : ArkTSRuntime {
        match(singleton) {
            case Some(i) => i
            case None => let i = ArkTSRuntime()
                         singleton = Some(i)
                         i
        }
    }

    public func eval(_: Expr): Extern<ArkTSRuntime> {
        Extern<ArkTSRuntime>(0)
    }

    public func serialize<T>(_: Extern<ArkTSRuntime>): T {
        (() as T).getOrThrow()
    }

    public func deserialize<T>(_: T): Extern<ArkTSRuntime> {
        Extern<ArkTSRuntime>(0)
    }
}

public class PythonRuntime <: Runtime<PythonRuntime> {
    private static var singleton : Option<PythonRuntime> = None

    private init() {}

    static public func instance() : PythonRuntime {
        match(singleton) {
            case Some(i) => i
            case None => let i = PythonRuntime()
                         singleton = Some(i)
                         i
        }
    }

    public func eval(_: Expr): Extern<PythonRuntime> {
        Extern<PythonRuntime>(0)
    }

    public func serialize<T>(_: Extern<PythonRuntime>): T {
        (() as T).getOrThrow()
    }

    public func deserialize<T>(_: T): Extern<PythonRuntime> {
        Extern<PythonRuntime>(0)
    }
}

main() {
    // let vm = ArkTSRuntime().instance()
    // let e1 = 
    // let x = e1.ctx.convert<Int64>(e1.handle)
    // println(x)
    // let e2 = Extern(vm, vm.create(43))
    // e1.ctx.update(e1.handle, 44)
    // let y = e1.ctx.convert<Int64>(e1.handle)
    // println(y)

}
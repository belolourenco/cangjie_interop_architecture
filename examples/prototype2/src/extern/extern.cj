package prototype2.extern

import std.ast.*

public type Handle = Int64

public class ExternConversionException <: Exception {
    public ExternConversionException(message: String) {
        super(message)
    }
}

public class ExternDynamicException <: Exception {
    public ExternDynamicException(message: String) {
        super(message)
    }
}

public interface Runtime {
    static func eval(e: Expr): Handle
    static func fromExtern<R>(h: Handle): R
    static func toExtern<R>(v: R): Handle
}

public struct Extern<T> where T <: Runtime {
    public Extern(public let handle : Handle) { }
}
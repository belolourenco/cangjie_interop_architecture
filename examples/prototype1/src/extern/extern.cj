package prototype1.extern

import std.ast.*
// import std.convert.*

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

public interface Runtime<T> where T <: Runtime<T> {
    // static func instance() : T
    static func eval(e: Expr): Extern<T>
    static func fromExtern<R>(e: Extern<T>): R
    static func toExtern<R>(e: R): Extern<T>
}

public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let handle : Handle) { }
}
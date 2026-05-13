package prototype4.extern

import std.collection.ArrayList

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

public enum Expr<T> where T <: Runtime<T> {
    | FieldAccess(Extern<T>, ArrayList<String>)             // baseExpr , fields
    | Call(Extern<T>, ArrayList<String>, ArrayList<Extern<T>>) // baseExpr , fields , arguments
    | Assignment(Extern<T>, ArrayList<String>, Extern<T>)      // baseExpr , fields , value
}

public interface Runtime<T> where T <: Runtime<T> {
    static func eval(e: Expr<T>): Extern<T>
    static func fromExtern<R>(e: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}

public type Handle = Int64

public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let handle : Handle) { }
}
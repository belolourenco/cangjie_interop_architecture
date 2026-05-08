package prototype3.extern

import std.collection.ArrayList

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

public enum Expr <: ToString {
    | FieldAccess(Handle, ArrayList<String>)             // baseExpr , fields
    | Call(Handle, ArrayList<String>, ArrayList<Handle>) // baseExpr , fields , arguments
    | Assignment(Handle, ArrayList<String>, Handle)      // baseExpr , fields , value

    public func toString(): String {
        match (this) {
            case FieldAccess(baseExpr, fields) =>
                "FieldAccess(${baseExpr}, ${fields})"
            case Call(baseExpr, fields, arguments) =>
                "Call(${baseExpr}, ${fields}, ${arguments})"
            case Assignment(baseExpr, fields, value) =>
                "Assignment(${baseExpr}, ${fields}, ${value})"
        }
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
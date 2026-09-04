// Intended to be thrown if an attempt is made to access or update a non-existing member
public class ExternMemberAccessException <: Exception {}

// Intended to be thrown if an attempt is made to access a non-existing function
public class ExternFunctionAccessException <: Exception {}

// Intended to be thrown if an attempt is made to call a function with the wrong arguments
public class ExternFunctionCallException <: Exception {}

// Intended to be thrown if an attempt is made to access or update with the wrong index, including out-of-bounds errors
public class ExternIndexedAccessException <: Exception {}

// Intended to be thrown if a function in the foreign runtime throws a runtime exception
public class ForeignRuntimeException <: Exception {}

// Intended to be thrown if data cannot be converted to or from an Extern type as required.
public class ExternConversionException <: Exception {}

// Intended to be thrown when an operation is not supported by the runtime
private class ExternUnsupportedOperation <: Exception {}

private class ExternUnsupportedOperation <: Exception {}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(t: Extern<T>): Extern<T> {
        eval_unsupported(t)
    }

    static func eval_unsupported(t: Extern<T>): Extern<T> {
        match(t) {
            case Seq(e1, e2) =>
                let _ = eval(e1)
                return eval(e2)
            case _ => throw ExternUnsupportedOperation()
        }
    }
}

public enum Extern<T> where T <: ForeignRuntime<T> {
    | Payload(Any)
    | MemberAccess(Extern<T>, String)
    | IndexedAccess(Extern<T>, Any)
    | MemberUpdate(Extern<T>, String, Any)
    | IndexedUpdate(Extern<T>, Any, Any)
    | FuncCall(Extern<T>, Array<Any>)
    | Seq(Extern<T>, Extern<T>)
    | ...
}

main () {
    0
}
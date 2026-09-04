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

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(t: Extern<T>): Extern<T>
}

public enum Extern<T> where T <: ForeignRuntime<T> {
    | ExternPayload(Any)
    | ExternMemberAccess(Extern<T>, String)
    | ExternIndexedAccess(Extern<T>, Any)
    | ExternMemberUpdate(Extern<T>, String, Any)
    | ExternIndexedUpdate(Extern<T>, Any, Any)
    | ExternFunctionCall(Extern<T>, Array<Any>)
}

main () {
    0
}
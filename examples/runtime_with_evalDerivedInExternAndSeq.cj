public class ExternMemberAccessException <: Exception {}
public class ExternFunctionAccessException <: Exception {}
public class ExternFunctionCallException <: Exception {}
public class ExternIndexedAccessException <: Exception {}
public class ForeignRuntimeException <: Exception {}
public class ExternConversionException <: Exception {}
public class ExternUnsupportedOperation <: Exception {}

public enum Extern<T> where T <: ForeignRuntime<T> {
    // primitive constructors
    | ExternPayload(Any)
    | ExternMemberAccess(Extern<T>,  /* field */ String)
    | ExternIndexedAccess(Extern<T>, /* index */ Any)
    | ExternMemberUpdate(Extern<T>,  /* field */ String, /* value */ Any)
    | ExternIndexedUpdate(Extern<T>, /* index */ Any,    /* value */ Any)
    | ExternFunctionCall(Extern<T>,  /* args  */ Array<Any>)
    // derived constructors
    | ExternSequence(Extern<T>, Extern<T>)
    | ...

    public static func evalDerived(e: Extern<T>): Extern<T> {
        match(e) {
            case ExternSequence(e1, e2) =>
                T.eval(e1)
                return T.eval(e2)
            case _ => throw ExternUnsupportedOperation()
        }
    }
}

public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func fromExtern<R>(e: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    static func eval(t: Extern<T>): Extern<T>
}

public class MockRT <: ForeignRuntime<MockRT> {
    public static func eval(t: Extern<MockRT>): Extern<MockRT> {
        match (t) {
            case ExternPayload(_) => t
            case ExternMemberAccess(_, _) => /* specific implementation of ExternMemberAccess */ throw ExternMemberAccessException()
            case ExternIndexedAccess(_, _) => /* specific implementation of ExternIndexedAccess */ throw ExternIndexedAccessException()
            case ExternMemberUpdate(_, _, _) => /* specific implementation of ExternMemberUpdate */ throw ExternMemberAccessException()
            case ExternIndexedUpdate(_, _, _) => /* specific implementation of ExternIndexedUpdate */ throw ExternIndexedAccessException()
            case ExternFunctionCall(_, _) => /* specific implementation of ExternFunctionCall */ throw ExternFunctionAccessException()
            case _ => Extern<MockRT>.evalDerived(t) // <==== Calling `evalDerived` from `ForeignRuntime<MockRT>`
        }
    }
    public static func fromExtern<R>(_: Extern<MockRT>): R { throw ExternConversionException() }
    public static func toExtern<R>(_: R): Extern<MockRT> { throw ExternConversionException() }
}

main () {}
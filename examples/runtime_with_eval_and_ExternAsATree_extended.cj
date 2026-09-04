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
    static func memberAccess(e: Extern<T>, field: String): Extern<T>
    static func indexedAccess(e: Extern<T>, arg: Any): Extern<T>

    static func memberUpdate(e: Extern<T>, field: String, value: Any) : Unit
    static func indexedUpdate(e: Extern<T>, field: Any, value: Any): Unit

    static func functionCall(e: Extern<T>, args: Array<Any>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(t: Extern<T>): Extern<T> {
        match (t) {
            case Payload(e) => return t
            case MemberAccess(t, field) =>
                let e = eval(t)
                return memberAccess(e, field)
            case IndexedAccess(t, idx) =>
                let e = eval(t)
                return indexedAccess(e, idx)
            case MemberUpdate(t, field, value) =>
                let e = eval(t)
                return toExtern(memberUpdate(e, field, value))
            case IndexedUpdate(t, idx, value) =>
                let e = eval(t)
                toExtern(indexedUpdate(e, idx, value))
            case FuncCall(t, args) =>
                let e = eval(t)
                return functionCall(e, args)
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
}

main () {
    ArkTS.eval(MemberAccess(Payload(42), "foo"))
    0
}

public class ArkTS <: ForeignRuntime<ArkTS> {
    public static func memberAccess(e: Extern<ArkTS>, field: String): Extern<ArkTS> { throw Exception("memberAccess") }
    public static func indexedAccess(e: Extern<ArkTS>, arg: Any): Extern<ArkTS> { throw Exception("indexedAccess") }

    public static func memberUpdate(e: Extern<ArkTS>, field: String, value: Any) : Unit { throw Exception("memberUpdate") }
    public static func indexedUpdate(e: Extern<ArkTS>, field: Any, value: Any): Unit { throw Exception("indexedUpdate") }

    public static func functionCall(e: Extern<ArkTS>, args: Array<Any>): Extern<ArkTS> { throw Exception("functionCall") }

    public static func fromExtern<R>(h: Extern<ArkTS>): R { throw Exception("fromExtern") }
    public static func toExtern<R>(v: R): Extern<ArkTS> { throw Exception("toExtern") }
}
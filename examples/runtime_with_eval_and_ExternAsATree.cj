
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
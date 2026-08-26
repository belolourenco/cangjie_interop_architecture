
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
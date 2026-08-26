public interface ForeignRuntime<T> where T <: ForeignRuntime<T> {
    static func memberAccess(e: Extern<T>, field: String): Extern<T>
    static func indexedAccess(e: Extern<T>, arg: Any): Extern<T>

    static func memberUpdate(e: Extern<T>, field: String, value: Any) : Unit
    static func indexedUpdate(e: Extern<T>, field: Any, value: Any): Unit

    static func functionCall(e: Extern<T>, args: Array<Any>): Extern<T>

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
    
    static func eval(externExpTree: ExternExpTree<T>): Extern<T> {
        match (externExpTree) {
            case Value(e) => return e
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

public enum ExternExpTree<T> where T <: ForeignRuntime<T> {
    | Value(Extern<T>)
    | MemberAccess(ExternExpTree<T>, String)
    | IndexedAccess(ExternExpTree<T>, Any)
    | MemberUpdate(ExternExpTree<T>, String, Any)
    | IndexedUpdate(ExternExpTree<T>, Any, Any)
    | FuncCall(ExternExpTree<T>, Array<Any>)
}

public struct Extern<T> where T <: ForeignRuntime<T> {
    private var payload: Any = ()

    public Extern(payload: Any) {
        this.payload = payload
    }
    public static func getPayload(e: Extern<T>): Any {
        e.payload
    }
}

main () {
    ArkTS.eval(MemberAccess(Value(Extern(42)), "foo"))
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
public enum ExternExpTree<T> where T <: ForeignRuntime<T> {
    | Value(Extern<T>)
    | MemberAccess(ExternExpTree<T>, String)
    | IndexedAccess(ExternExpTree<T>, Any)
    | MemberUpdate(ExternExpTree<T>, String, Any)
    | IndexedUpdate(ExternExpTree<T>, Any, Any)
    | FuncCall(ExternExpTree<T>, Array<Any>)
}

public interface EfficientForeignRuntime <: ForeignRuntime<EfficientForeignRuntime> {
    static func eval(externExpTree: ExternExpTree<EfficientForeignRuntime>): Extern<EfficientForeignRuntime> {
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

main () {}
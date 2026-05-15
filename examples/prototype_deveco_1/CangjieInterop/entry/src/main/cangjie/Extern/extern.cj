package ohos_app_cangjie_entry.Extern

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

public interface Runtime<T> where T <: Runtime<T> {
    static func evalMemberAccess(e: Extern<T>, field: String)            : Extern<T>
    static func evalFunctionCall(e: Extern<T>, args: Array<Any>)         : Extern<T>
    static func evalIndexAccess (e: Extern<T>, arg: Any)                 : Extern<T>
    static func evalAssignment  (e: Extern<T>, field: String, value: Any): Unit

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}

public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let content : Any) { }
}
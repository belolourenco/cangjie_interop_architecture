package ohos_app_cangjie_entry.Extern

import std.collection.ArrayList
import ohos.hilog.Hilog

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

public interface Runtime<T> where T <: Runtime<T> {
    static func evalMemberAccess(e: Extern<T>, field: String)            : Extern<T>
    static func evalFunctionCall(e: Extern<T>, args: Array<Any>)         : Extern<T>
    static func evalIndexAccess (e: Extern<T>, arg: Any)                 : Extern<T>
    static func evalAssignment  (e: Extern<T>, field: String, value: Any): Unit

    static func fromExtern<R>(h: Extern<T>): R
    static func toExtern<R>(v: R): Extern<T>
}

public struct Extern<T> where T <: Runtime<T> {
    public Extern(public let handle : Handle) { }
}


// ====== JUST HELPER FUNCTIONS TO HELP WITH OHOS DEBUGGING ======

public func mylog(s: ToString) {
    Hilog.info(0, "MYLOG", s.toString())
}

public func printStackTrace(e: Exception): String {
    let result = StringBuilder()
    let caption: String = "An exception has occurred:\n"
    let enclosingTrace: Array<StackTraceElement> = Array<StackTraceElement>()
    result.append("${caption}${e.toString()}\n")
    let trace = e.getStackTrace()
    var ourSize = trace.size - 1
    var enclosingSize = enclosingTrace.size - 1

    func equals(self: StackTraceElement, other: StackTraceElement): Bool {
        return self.declaringClass == other.declaringClass &&
            self.methodName == other.methodName &&
            self.fileName == other.fileName &&
            self.lineNumber == other.lineNumber
    }
    while (ourSize >= 0 && enclosingSize >= 0 && equals(trace[ourSize], enclosingTrace[enclosingSize])) {
        ourSize--
        enclosingSize--
    }
    let commonSize = trace.size - 1 - ourSize
    for (i in 0..=ourSize) {
        let element = trace[i]
        if (element.methodName.contains("Exception::init")) {
            continue
        }
        if (element.declaringClass.isEmpty() && element.methodName.isEmpty()) { // simple stack trace format
            result.append("\t at ${element.fileName}:${element.lineNumber}\n")
        } else {
            let packageDelimiter: String = if (element.declaringClass.isEmpty()) { "" } else { "::" }
            result.append(
                "\t at ${element.declaringClass}${packageDelimiter}${element.methodName}(${element.fileName}:${element.lineNumber})\n")
        }
    }
    if (commonSize > 0) {
        result.append("\t ... ${commonSize} more\n")
    }
    result.toString()
}
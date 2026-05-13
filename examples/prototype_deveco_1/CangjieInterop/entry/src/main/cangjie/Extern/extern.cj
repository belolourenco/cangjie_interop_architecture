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

public enum Expr <: ToString {
    | FieldAccess(Handle, ArrayList<String>)             // baseExpr , fields
    | Call(Handle, ArrayList<String>, ArrayList<Handle>) // baseExpr , fields , arguments
    | Assignment(Handle, ArrayList<String>, Handle)      // baseExpr , fields , value

    public func toString(): String {
        match (this) {
            case FieldAccess(baseExpr, fields) =>
                "FieldAccess(${baseExpr}, ${fields})"
            case Call(baseExpr, fields, arguments) =>
                "Call(${baseExpr}, ${fields}, ${arguments})"
            case Assignment(baseExpr, fields, value) =>
                "Assignment(${baseExpr}, ${fields}, ${value})"
        }
    }
}

public interface Runtime {
    static func eval(e: Expr): Handle
    static func fromExtern<R>(h: Handle): R
    static func toExtern<R>(v: R): Handle
}

public struct Extern<T> where T <: Runtime {
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
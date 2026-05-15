package ohos_app_cangjie_entry.Utils

import ohos.hilog.Hilog

public func mylog(s: String) {
    Hilog.info(0, "MYLOG", s)
}

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
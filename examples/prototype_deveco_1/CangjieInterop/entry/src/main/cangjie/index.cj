package ohos_app_cangjie_entry

import ohos_app_cangjie_entry.Extern.*

import std.collection.ArrayList

import ohos.ark_interop.JSModule
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSCallInfo
import ohos.ark_interop.JSValue
import ohos_app_cangjie_entry.ArkTSRuntime.ArkTSRuntime
import std.math.numeric.BigInt
import ohos.ark_interop.JSRuntime
import ohos.arkui.state_management.AppStorage

class Assert {
    public static func isUnreachable(reason!: String = "") {
        mylog("unreachable, ${reason}")
        throw Exception()
    }
}

func testCJ(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    try {
//        dummyRuntimeDemoEntryPoint()
        ArkTSRuntime.context = runtime
        arkTSRuntimePrimitiveTypesTestsEntryPoint()
        ArkTSRuntime.runDummyTest()
    } catch (e: Exception) {
        mylog(printStackTrace(e))
    }
    let result = "Hello ${callInfo[0].toString()}"
    runtime.string(result).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["testCJ"] = runtime.function(testCJ).toJSValue()
}
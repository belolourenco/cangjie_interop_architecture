package ohos_app_cangjie_entry

import ohos_app_cangjie_entry.Extern.{mylog, printStackTrace}
import ohos_app_cangjie_entry.ArkTSRuntime.ArkTSRuntime
import ohos_app_cangjie_entry.DemoNativeInterop.demoArkTSNativeInterop
import ohos_app_cangjie_entry.DemoDummyRuntime.dummyRuntimeDemo
import ohos_app_cangjie_entry.DemoArkTSRuntime.{demoArkTSRuntimeTestPrimitives, demoArkTSRuntime_1, demoArkTSRuntime_2}

import std.collection.ArrayList

import ohos.ark_interop.JSModule
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSCallInfo
import ohos.ark_interop.JSValue
import std.math.numeric.BigInt
import ohos.ark_interop.JSRuntime
import ohos.arkui.state_management.AppStorage

func testCJ(runtime: JSContext, callInfo: JSCallInfo): JSValue {
    try {
        // ---- Dummy Runtime ----
        mylog("######################### Dummy Runtime #########################")
        dummyRuntimeDemo()

        // ---- ArkTS Native Interop ----
        mylog("######################### ArkTS Native Interop #########################")
        demoArkTSNativeInterop(runtime)

        // ---- ArkTS Runtime ----
        ArkTSRuntime.context = runtime
        mylog("######################### ArkTS Runtime Test Primitives #########################")
        demoArkTSRuntimeTestPrimitives()
        mylog("######################### ArkTS Runtime Demo 1 #########################")
        demoArkTSRuntime_1()

        // TODO: Need to fix entry/src/main/cangjie/DemoArkTSRuntime/demoArkTSRuntime_2.cj. In particular:
        // - Make Shapes in entry/src/main/ets/my_arkts_module.ets more similar to those in entry/src/main/ets/my_arkts_module.ets
        // - Adjust demoArkTSRuntime_2.cj accordingly

        mylog("######################### ArkTS Runtime Demo 2 #########################")
        demoArkTSRuntime_2()


    } catch (e: Exception) {
        mylog(printStackTrace(e))
    }
    let result = "Hello ${callInfo[0].toString()}"
    runtime.string(result).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["testCJ"] = runtime.function(testCJ).toJSValue()
}
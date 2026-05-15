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
        dummyRuntimeDemoEntryPoint()
        ArkTSRuntime.context = runtime
        // arkTSRuntimePrimitiveTypesTestsEntryPoint()
        testArkTS()
        // mytest(runtime)
        // ArkTSRuntime.runDummyTest()
    } catch (e: Exception) {
        mylog(printStackTrace(e))
    }
    let result = "Hello ${callInfo[0].toString()}"
    runtime.string(result).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports => exports["testCJ"] = runtime.function(testCJ).toJSValue()
}

func testArkTS() {
    // ---- ArkTS Module ----
    let arktsModule: Extern<ArkTSRuntime> = ArkTSRuntime.getModule("entry/src/main/ets/my_arkts_module")

    // ---- my_arkts_function ----

    // arktsModule.my_arkts_function()
    // ->
    let my_arkts_function: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(arktsModule, "my_arkts_function")
    ArkTSRuntime.evalFunctionCall(my_arkts_function, [])

    // ---- lookup ----

    // let lookupResult: Extern<ArkTSRuntime> = arktsModule.lookup(42.4242, 1.111)
    // ->
    let lookup: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(arktsModule, "lookup")
    let lookupResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(lookup, [42.4242, 1.111])

    // mylog("Lookup coordinates: (${(lookupResult.coordinates[0] as Float64).getOrThrow()}, ${(lookupResult.coordinates[1] as Float64).getOrThrow()})")
    // ->
    let lookup_coordinates: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(lookupResult, "coordinates")
    let lookup_coordinates_0: Extern<ArkTSRuntime> = ArkTSRuntime.evalIndexAccess(lookup_coordinates, 0)
    let lookup_coordinates_1: Extern<ArkTSRuntime> = ArkTSRuntime.evalIndexAccess(lookup_coordinates, 1)
    mylog("Lookup coordinates: (${ArkTSRuntime.fromExtern<Float64>(lookup_coordinates_0)}, ${ArkTSRuntime.fromExtern<Float64>(lookup_coordinates_1)})")

    // mylog("Lookup result: ${lookupResult.name}")
    // ->
    let lookup_name: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(lookupResult, "name")
    mylog("Lookup name: ${ArkTSRuntime.fromExtern<String>(lookup_name)}")

    // mylog("Lookup result: ${lookupResult.city}")
    // ->
    let lookup_city: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(lookupResult, "city")
    mylog("Lookup city: ${ArkTSRuntime.fromExtern<String>(lookup_city)}")

    // mylog("Lookup result: ${lookupResult.category}")
    // ->
    let lookup_category: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(lookupResult, "category")
    mylog("Lookup category: ${ArkTSRuntime.fromExtern<String>(lookup_category)}")

    // ---- Rectangle ----

    // let rectangle: Extern<ArkTSRuntime> = arktsModule.Rectangle(10, 11)
    // ->
    let rectangleConstructor: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(arktsModule, "Rectangle")
    let rectangleObject: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(rectangleConstructor, [10, 11])

    // let rectangleWidth: Extern<ArkTSRuntime> = rectangleObject.getWidth()
    // ->
    let rectangleWidthMethod: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject, "getWidth")
//    let rectangleWidthResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(rectangleWidthMethod, [])
//    mylog("Rectangle width: ${ArkTSRuntime.fromExtern<Float64>(rectangleWidthResult)}")

    // let rectangleWidth = rectangleObject.callMethod("getWidth", []).asNumber().toFloat64()
    // mylog("Rectangle width: ${rectangleWidth}")
    // let rectangleHeight = rectangleObject.callMethod("getHeight", []).asNumber().toFloat64()
    // mylog("Rectangle height: ${rectangleHeight}")

    // // ---- createRectangle ----
    // let widthJSValue2 = context.number(12).toJSValue()
    // let heightJSValue2 = context.number(13).toJSValue()
    // let rectangleJSValue2 = arktsModule["createRectangle"].asFunction().call()
    // let rectangleObject2 = rectangleJSValue2.asObject()

    // rectangleObject2.setProperty("width", context.number(42).toJSValue())

    // let rectangleWidth2 = rectangleObject2.getProperty("width").asNumber().toFloat64()
    // mylog("Rectangle width: ${rectangleWidth2}")
    // let rectangleHeight2 = rectangleObject2.getProperty("height").asNumber().toFloat64()
    // mylog("Rectangle height: ${rectangleHeight2}")

    // let area = rectangleObject2.callMethod("area", []).asNumber().toFloat64()
    // mylog("Rectangle area: ${area}")
    // let perimeter = rectangleObject2.callMethod("perimeter", []).asNumber().toFloat64()
    // mylog("Rectangle perimeter: ${perimeter}")

}
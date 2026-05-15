package ohos_app_cangjie_entry

import ohos.ark_interop.JSContext
import ohos.ark_interop.JSRuntime
import ohos.ark_interop.JSValue
import ohos.ark_interop.JSObject
import ohos.ark_interop.JSArray
import ohos.ark_interop.JSString
import ohos.ark_interop.JSNumber
import ohos_app_cangjie_entry.Extern.mylog

func mytest(context: JSContext) {
//    let jsRuntime = JSRuntime()
//    let context2 = jsRuntime.mainContext

    // ---- ArkTS Module ----
    let arktsModule = context.requireArkModule("entry/src/main/ets/my_arkts_module").asObject()

    // ---- my_arkts_function ----
    arktsModule["my_arkts_function"].asFunction().call()

    arktsModule["my_arkts_function"].asFunction().call([], thisArg: arktsModule["my_arkts_function"])

    // ---- Lookup ----
    let lat = context.number(42.4242).toJSValue()
    let long = context.number(1.111).toJSValue()
    let lookupResultValue = arktsModule["lookup"].asFunction().call([lat, long])
    let lookupResultObject = lookupResultValue.asObject()
    mylog("Lookup result: ${lookupResultObject.keys()}")

    let coordinatesJSValue = lookupResultObject.getProperty("coordinates")
    let nameJSValue = lookupResultObject.getProperty("name")
    let cityJSValue = lookupResultObject.getProperty("city")
    let categoryJSValue = lookupResultObject.getProperty("category")

    let coordinates = coordinatesJSValue.asArray()
    let name = nameJSValue.asString()
    let city = cityJSValue.asString()
    let category = categoryJSValue.asString()
    mylog("Coordinates: (${coordinates[0].asNumber().toFloat64()}, ${coordinates[1].asNumber().toFloat64()}), Name: ${name}, City: ${city}, Category: ${category}")


    // ---- Rectangle ----
    let widthJSValue = context.number(10).toJSValue()
    let heightJSValue = context.number(11).toJSValue()
    let rectangleJSValue = arktsModule["Rectangle"].asClass().new([widthJSValue, heightJSValue])
    let rectangleObject = rectangleJSValue.asObject()

    let rectangleWidth = rectangleObject.callMethod("getWidth", []).asNumber().toFloat64()
    mylog("Rectangle width: ${rectangleWidth}")
    let rectangleHeight = rectangleObject.callMethod("getHeight", []).asNumber().toFloat64()
    mylog("Rectangle height: ${rectangleHeight}")

    // ---- createRectangle ----
    let widthJSValue2 = context.number(12).toJSValue()
    let heightJSValue2 = context.number(13).toJSValue()
    let rectangleJSValue2 = arktsModule["createRectangle"].asFunction().call()
    let rectangleObject2 = rectangleJSValue2.asObject()

    rectangleObject2.setProperty("width", context.number(42).toJSValue())

    let rectangleWidth2 = rectangleObject2.getProperty("width").asNumber().toFloat64()
    mylog("Rectangle width: ${rectangleWidth2}")
    let rectangleHeight2 = rectangleObject2.getProperty("height").asNumber().toFloat64()
    mylog("Rectangle height: ${rectangleHeight2}")

    let area = rectangleObject2.callMethod("area", []).asNumber().toFloat64()
    mylog("Rectangle area: ${area}")
    let perimeter = rectangleObject2.callMethod("perimeter", []).asNumber().toFloat64()
    mylog("Rectangle perimeter: ${perimeter}")
}
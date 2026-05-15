package ohos_app_cangjie_entry.DemoArkTSRuntime

import ohos_app_cangjie_entry.Utils.mylog
import ohos_app_cangjie_entry.ArkTSRuntime.ArkTSRuntime
import ohos_app_cangjie_entry.Extern.Extern

public func demoArkTSRuntime_1() {
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
    let rectangleWidthResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(rectangleWidthMethod, [])
    mylog("Rectangle width: ${ArkTSRuntime.fromExtern<Float64>(rectangleWidthResult)}")

    // let rectangleHeight: Extern<ArkTSRuntime> = rectangleObject.getHeight()
    // ->
    let rectangleHeightMethod: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject, "getHeight")
    let rectangleHeightResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(rectangleHeightMethod, [])
    mylog("Rectangle height: ${ArkTSRuntime.fromExtern<Float64>(rectangleHeightResult)}")

    // ---- createRectangle ----

    // let rectangleObject2: Extern<ArkTSRuntime> = arktsModule.createRectangle()
    // ->
    let createRectangleMethod: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(arktsModule, "createRectangle")
    let rectangleObject2: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(createRectangleMethod, [])

    // rectangleObject2.width = 42
    // ->
    ArkTSRuntime.evalAssignment(rectangleObject2, "width", 42.0)

    // let rectangleWidth2: Extern<ArkTSRuntime> = rectangleObject2.width
    // ->
    let rectangleWidthResult2: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject2, "width")
    mylog("Rectangle width: ${ArkTSRuntime.fromExtern<Float64>(rectangleWidthResult2)}")

    // let rectangleHeight2: Extern<ArkTSRuntime> = rectangleObject2.height
    // ->
    let rectangleHeightResult2: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject2, "height")
    mylog("Rectangle height: ${ArkTSRuntime.fromExtern<Float64>(rectangleHeightResult2)}")

    // let area = rectangleObject2.area()
    // ->
    let areaMethod: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject2, "area")
    let areaResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(areaMethod, [])
    mylog("Rectangle area: ${ArkTSRuntime.fromExtern<Float64>(areaResult)}")

    // let perimeter = rectangleObject2.perimeter()
    // ->
    let perimeterMethod: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(rectangleObject2, "perimeter")
    let perimeterResult: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(perimeterMethod, [])
    mylog("Rectangle perimeter: ${ArkTSRuntime.fromExtern<Float64>(perimeterResult)}")

}
package ohos_app_cangjie_entry.DemoArkTSRuntime

import ohos_app_cangjie_entry.Extern.*
import ohos_app_cangjie_entry.ArkTSRuntime.*

func lookup(lat: Float32, long: Float32): Extern<ArkTSRuntime> {
    let extModule: Extern<ArkTSRuntime> = ArkTSRuntime.getModule("geocoding") // I'm not sure about this!

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(lat)
    let e_long: Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(long)
    let e_lookup: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(extModule, "lookup")
    ArkTSRuntime.evalFunctionCall(e_lookup, [e_lat, e_long])
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    public let blob : Extern<ArkTSRuntime>
    public init(x: Float64, y: Float64) {
        let shapeModule: Extern<ArkTSRuntime> = ArkTSRuntime.getModule("shape")

        // blob = shapeModule.Point(x, y)
        // ->
        let e_func = ArkTSRuntime.evalMemberAccess(shapeModule, "Point")
        blob = ArkTSRuntime.evalFunctionCall(e_func, [ArkTSRuntime.toExtern(x), ArkTSRuntime.toExtern(y)])
    }

    public init(extern: Extern<ArkTSRuntime>) {
        blob = extern
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(blob, "x")
            ArkTSRuntime.fromExtern<Float64>(x_extern)
        }
        set(v) {
            // blob.x = v
            // ->
            ArkTSRuntime.evalAssignment(blob, "x", ArkTSRuntime.toExtern(v))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(blob, "y")
            ArkTSRuntime.fromExtern<Float64>(x_extern)
        }
        set(v) {
            // blob.y = v
            // ->
            ArkTSRuntime.evalAssignment(blob, "y", ArkTSRuntime.toExtern(v))
        }
    }
}

class Rectangle {
    private var blob : Extern<ArkTSRuntime>
    public Rectangle(topLeft: Point, bottomRight: Point) {
        let shapeModule: Extern<ArkTSRuntime> = ArkTSRuntime.getModule("shape")

        // blob = shapeModule.Rectangle(topLeft, bottomRight)
        // ->
        let e_func = ArkTSRuntime.evalMemberAccess(shapeModule, "Rectangle")
        blob = ArkTSRuntime.evalFunctionCall(e_func, [topLeft.blob, bottomRight.blob])
    }

    public mut prop topLeft: Point {
        get() {
            // blob.topLeft
            // ->
            let topLeft_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(blob, "topLeft")
            Point(topLeft_extern)
        }
        set(v) {
            // blob.topLeft = v
            // ->
            ArkTSRuntime.evalAssignment(blob, "topLeft", v.blob)
        }
    }

    public mut prop bottomRight: Point {
        get() {
            // blob.bottomRight
            // ->
            let bottomRight_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalMemberAccess(blob, "bottomRight")
            Point(bottomRight_extern)
        }
        set(v) {
            // blob.bottomRight = v
            // ->
            ArkTSRuntime.evalAssignment(blob, "bottomRight", v.blob)
        }
    }

    public func perimeter(): Float64 {
        // ArkTSRuntime.fromExtern<Float64>(blob.perimeter())
        // ->
        let e_func = ArkTSRuntime.evalMemberAccess(blob, "perimeter")
        let perimeter_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(e_func, [])
        ArkTSRuntime.fromExtern<Float64>(perimeter_extern)
    }

    public func area(): Float64 {
        // ArkTSRuntime.fromExtern<Float64>(blob.area())
        // ->
        let e_func = ArkTSRuntime.evalMemberAccess(blob, "area")
        let area_extern: Extern<ArkTSRuntime> = ArkTSRuntime.evalFunctionCall(e_func, [])
        ArkTSRuntime.fromExtern<Float64>(area_extern)
    }

}

public func demoArkTSRuntime_2() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<ArkTSRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(42)

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_fourty_two)

    mylog(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<ArkTSRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern("Hello World!")

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = ArkTSRuntime.fromExtern<String>(arkTs_hello_world)

    mylog(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<ArkTSRuntime> = 1u8
    // ->
    let arkTs_one : Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(1u8)

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = ArkTSRuntime.fromExtern<UInt8>(arkTs_one)

    mylog(one)

    // ---- var Int64 ----
    let x: Int64 = 101

    // let arkTs_x: Extern<ArkTSRuntime> = x
    // ->
    let arkTs_x: Extern<ArkTSRuntime> = ArkTSRuntime.toExtern(x)

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = ArkTSRuntime.fromExtern<Int64>(arkTs_x)

    mylog(x_2)

    // ---- lookup ----
    let result: Extern<ArkTSRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = ArkTSRuntime.fromExtern<(Float32, Float32)>(result)
    mylog("(${result_value[0]}, ${result_value[1]})")

    // // ---- Point ----
    let point: Point = Point(3.0, 4.0)

    mylog("Point: (${point.x}, ${point.y})")

    point.x = 5.0
    point.y = 6.0

    mylog("Point: (${point.x}, ${point.y})")

    // ---- Rectangle ----
    let rectangle: Rectangle = Rectangle(Point(0.0, 0.0), Point(10.0, 10.0))

    mylog("Rectangle 1: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    rectangle.topLeft = Point(1.0, 1.0)
    rectangle.bottomRight = Point(9.0, 9.0)

    mylog("Rectangle 2: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

     rectangle.topLeft.x = 2.0
     rectangle.bottomRight.y = 8.0

     mylog("Rectangle 3: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

//     mylog("Rectangle perimeter: ${rectangle.perimeter()}")
//     mylog("Rectangle area: ${rectangle.area()}")

    // mylog("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}, ${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
}

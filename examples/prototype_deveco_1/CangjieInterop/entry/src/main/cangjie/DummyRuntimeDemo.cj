package ohos_app_cangjie_entry

import ohos_app_cangjie_entry.Extern.*
import ohos_app_cangjie_entry.DummyRuntime.*

func lookup(lat: Float32, long: Float32): Extern<DummyRuntime> {
    let extModule: Extern<DummyRuntime> = DummyRuntime.getModule("geocoding") // I'm not sure about this!

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<DummyRuntime> = DummyRuntime.toExtern(lat)
    let e_long: Extern<DummyRuntime> = DummyRuntime.toExtern(long)
    let e_lookup: Extern<DummyRuntime> = DummyRuntime.evalMemberAccess(extModule, "lookup")
    DummyRuntime.evalFunctionCall(e_lookup, [e_lat, e_long])
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    public let blob : Extern<DummyRuntime>
    public init(x: Float64, y: Float64) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Point(x, y)
        // ->
        let e_func = DummyRuntime.evalMemberAccess(shapeModule, "Point")
        blob = DummyRuntime.evalFunctionCall(e_func, [DummyRuntime.toExtern(x), DummyRuntime.toExtern(y)])
    }

    public init(extern: Extern<DummyRuntime>) {
        blob = extern
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_handle: Extern<DummyRuntime> = DummyRuntime.evalMemberAccess(blob, "x")
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.x = v
            // ->
            DummyRuntime.evalAssignment(blob, "x", DummyRuntime.toExtern(v))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_handle: Extern<DummyRuntime> = DummyRuntime.evalMemberAccess(blob, "y")
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.y = v
            // ->
            DummyRuntime.evalAssignment(blob, "y", DummyRuntime.toExtern(v))
        }
    }
}

class Rectangle {
    private var blob : Extern<DummyRuntime>
    public Rectangle(topLeft: Point, bottomRight: Point) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Rectangle(topLeft, bottomRight)
        // ->
        let e_func = DummyRuntime.evalMemberAccess(shapeModule, "Rectangle")
        blob = DummyRuntime.evalFunctionCall(e_func, [topLeft.blob, bottomRight.blob])
    }

    public mut prop topLeft: Point {
        get() {
            // blob.topLeft
            // ->
            let topLeft_handle: Extern<DummyRuntime> = DummyRuntime.evalMemberAccess(blob, "topLeft")
            Point(topLeft_handle)
        }
        set(v) {
            // blob.topLeft = v
            // ->
            DummyRuntime.evalAssignment(blob, "topLeft", v.blob)
        }
    }

    public mut prop bottomRight: Point {
        get() {
            // blob.bottomRight
            // ->
            let bottomRight_handle: Extern<DummyRuntime> = DummyRuntime.evalMemberAccess(blob, "bottomRight")
            Point(bottomRight_handle)
        }
        set(v) {
            // blob.bottomRight = v
            // ->
            DummyRuntime.evalAssignment(blob, "bottomRight", v.blob)
        }
    }

    public func perimeter(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.perimeter())
        // ->
        let e_func = DummyRuntime.evalMemberAccess(blob, "perimeter")
        let perimeter_handle: Extern<DummyRuntime> = DummyRuntime.evalFunctionCall(e_func, [])
        DummyRuntime.fromExtern<Float64>(perimeter_handle)
    }

    public func area(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.area())
        // ->
        let e_func = DummyRuntime.evalMemberAccess(blob, "area")
        let area_handle: Extern<DummyRuntime> = DummyRuntime.evalFunctionCall(e_func, [])
        DummyRuntime.fromExtern<Float64>(area_handle)
    }

}

func dummyRuntimeDemoEntryPoint() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<DummyRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<DummyRuntime> = DummyRuntime.toExtern(42)

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = DummyRuntime.fromExtern<Int64>(arkTs_fourty_two)

    mylog(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<DummyRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<DummyRuntime> = DummyRuntime.toExtern("Hello World!")

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = DummyRuntime.fromExtern<String>(arkTs_hello_world)

    mylog(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<DummyRuntime> = 1u8
    // ->
    let arkTs_one : Extern<DummyRuntime> = DummyRuntime.toExtern(1u8)

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = DummyRuntime.fromExtern<UInt8>(arkTs_one)

    mylog(one)

    // ---- var Int64 ----
    let x: Int64 = 101

    // let arkTs_x: Extern<DummyRuntime> = x
    // ->
    let arkTs_x: Extern<DummyRuntime> = DummyRuntime.toExtern(x)

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = DummyRuntime.fromExtern<Int64>(arkTs_x)

    mylog(x_2)

    // ---- lookup ----
    let result: Extern<DummyRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = DummyRuntime.fromExtern<(Float32, Float32)>(result)
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

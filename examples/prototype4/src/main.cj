package prototype4

import std.collection.ArrayList
import prototype4.extern.*
import prototype4.dummy_runtime.*

func lookup(lat: Float32, long: Float32): Extern<DummyRuntime> {
    let extModule: Extern<DummyRuntime> = DummyRuntime.getModule("geocoding") // I'm not sure about this! 

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<DummyRuntime> = DummyRuntime.toExtern(lat)
    let e_long: Extern<DummyRuntime> = DummyRuntime.toExtern(long)
    DummyRuntime.eval(Call(extModule, ArrayList<String>(["lookup"]), ArrayList<Extern<DummyRuntime>>([e_lat, e_long])))
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    public let blob : Extern<DummyRuntime>
    public init(x: Float64, y: Float64) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Point(x, y)
        // ->
        blob = DummyRuntime.eval(Call(shapeModule, ArrayList<String>(["Point"]), ArrayList<Extern<DummyRuntime>>([DummyRuntime.toExtern(x), DummyRuntime.toExtern(y)])))
    }

    public init(extern: Extern<DummyRuntime>) {
        blob = extern
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_extern: Extern<DummyRuntime> = DummyRuntime.eval(FieldAccess(blob, ArrayList<String>(["x"])))
            DummyRuntime.fromExtern<Float64>(x_extern)
        }
        set(v) {
            // blob.x = v
            // ->
            DummyRuntime.eval(Assignment(blob, ArrayList<String>(["x"]), DummyRuntime.toExtern(v)))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_extern: Extern<DummyRuntime> = DummyRuntime.eval(FieldAccess(blob, ArrayList<String>(["y"])))
            DummyRuntime.fromExtern<Float64>(x_extern)
        }
        set(v) {
            // blob.y = v
            // ->
            DummyRuntime.eval(Assignment(blob, ArrayList<String>(["y"]), DummyRuntime.toExtern(v)))
        }
    }
}

class Rectangle {
    private var blob : Extern<DummyRuntime>
    public Rectangle(topLeft: Point, bottomRight: Point) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Rectangle(topLeft, bottomRight)
        // ->
        blob = DummyRuntime.eval(Call(shapeModule, ArrayList<String>(["Rectangle"]), ArrayList<Extern<DummyRuntime>>([topLeft.blob, bottomRight.blob])))
    }

    public mut prop topLeft: Point {
        get() {
            // blob.topLeft
            // ->
            let topLeft_extern: Extern<DummyRuntime> = DummyRuntime.eval(FieldAccess(blob, ArrayList<String>(["topLeft"])))
            Point(topLeft_extern)
        }
        set(v) {
            // blob.topLeft = v
            // ->
            DummyRuntime.eval(Assignment(blob, ArrayList<String>(["topLeft"]), v.blob))
        }
    }

    public mut prop bottomRight: Point {
        get() {
            // blob.bottomRight
            // ->
            let bottomRight_extern: Extern<DummyRuntime> = DummyRuntime.eval(FieldAccess(blob, ArrayList<String>(["bottomRight"])))
            Point(bottomRight_extern)
        }
        set(v) {
            // blob.bottomRight = v
            // ->
            DummyRuntime.eval(Assignment(blob, ArrayList<String>(["bottomRight"]), v.blob))
        }
    }

    public func perimeter(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.perimeter())
        // ->
        let perimeter_extern: Extern<DummyRuntime> = DummyRuntime.eval(Call(blob, ArrayList<String>(["perimeter"]), ArrayList<Extern<DummyRuntime>>([])))
        DummyRuntime.fromExtern<Float64>(perimeter_extern)
    }

    public func area(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.area())
        // ->
        let perimeter_extern: Extern<DummyRuntime> = DummyRuntime.eval(Call(blob, ArrayList<String>(["area"]), ArrayList<Extern<DummyRuntime>>([])))
        DummyRuntime.fromExtern<Float64>(perimeter_extern)
    }
    
}

main() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<DummyRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<DummyRuntime> = DummyRuntime.toExtern(42)

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = DummyRuntime.fromExtern(arkTs_fourty_two)

    println(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<DummyRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<DummyRuntime> = DummyRuntime.toExtern("Hello World!")

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = DummyRuntime.fromExtern(arkTs_hello_world)

    println(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<DummyRuntime> = 1u8
    // ->
    let arkTs_one : Extern<DummyRuntime> = DummyRuntime.toExtern(1u8)

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = DummyRuntime.fromExtern(arkTs_one)

    println(one)

    // ---- var Int64 ----
    let x: Int64 = 101
    
    // let arkTs_x: Extern<DummyRuntime> = x
    // ->
    let arkTs_x: Extern<DummyRuntime> = DummyRuntime.toExtern(x)

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = DummyRuntime.fromExtern(arkTs_x)

    println(x_2)

    // ---- lookup ----
    let result: Extern<DummyRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = DummyRuntime.fromExtern(result)
    println("(${result_value[0]}, ${result_value[1]})")

    // ---- Point ----
    let point: Point = Point(3.0, 4.0)

    println("Point: (${point.x}, ${point.y})")

    point.x = 5.0
    point.y = 6.0

    println("Point: (${point.x}, ${point.y})")

    // ---- Rectangle ----
    let rectangle: Rectangle = Rectangle(Point(0.0, 0.0), Point(10.0, 10.0))

    println("Rectangle 1: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    rectangle.topLeft = Point(1.0, 1.0)
    rectangle.bottomRight = Point(9.0, 9.0)
    
    println("Rectangle 2: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
    
    rectangle.topLeft.x = 2.0
    rectangle.bottomRight.y = 8.0
    
    println("Rectangle 3: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
    
    // println("Rectangle perimeter: ${rectangle.perimeter()}")
    // println("Rectangle area: ${rectangle.area()}")

    // println("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}, ${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
}
package prototype3

import std.ast.*
import prototype3.extern.*
import prototype3.dummy_runtime.*

func lookup(lat: Float32, long: Float32): Extern<DummyRuntime> {
    let extModule: Extern<DummyRuntime> = DummyRuntime.getModule("geocoding") // I'm not sure about this! 

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(lat))
    let e_long: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(long))
    Extern<DummyRuntime>(DummyRuntime.eval(Call(extModule.handle, ArrayList<String>(["lookup"]), ArrayList<Handle>([e_lat.handle, e_long.handle]))))
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    public let blob : Extern<DummyRuntime>
    public Point(x: Float64, y: Float64) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Point(x, y)
        // ->
        blob = Extern<DummyRuntime>(DummyRuntime.eval(Call(shapeModule.handle, ArrayList<String>(["Point"]), ArrayList<Handle>([DummyRuntime.toExtern(x), DummyRuntime.toExtern(y)]))))
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["x"])))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.x = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["x"]), DummyRuntime.toExtern(v)))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["y"])))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.y = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["y"]), DummyRuntime.toExtern(v)))
        }
    }
}

class Rectangle {
    private var blob : Extern<DummyRuntime>
    public Rectangle(topLeft: Point, bottomRight: Point) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")

        // blob = shapeModule.Rectangle(topLeft, bottomRight)
        // ->
        blob = Extern<DummyRuntime>(DummyRuntime.eval(Call(shapeModule.handle, ArrayList<String>(["Rectangle"]), ArrayList<Handle>([topLeft.blob.handle, bottomRight.blob.handle]))))
    }

    public mut prop topLeft: Point {
        get() {
            // blob.topLeft
            // ->
            let topLeft_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["topLeft"])))
            Point(DummyRuntime.fromExtern<Float64>(DummyRuntime.eval(FieldAccess(topLeft_handle, ArrayList<String>(["x"])))),
                  DummyRuntime.fromExtern<Float64>(DummyRuntime.eval(FieldAccess(topLeft_handle, ArrayList<String>(["y"])))))
        }
        set(v) {
            // blob.topLeft = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["topLeft"]), v.blob.handle))
        }
    }

    public mut prop bottomRight: Point {
        get() {
            // blob.bottomRight
            // ->
            let bottomRight_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["bottomRight"])))
            Point(DummyRuntime.fromExtern<Float64>(DummyRuntime.eval(FieldAccess(bottomRight_handle, ArrayList<String>(["x"])))),
                  DummyRuntime.fromExtern<Float64>(DummyRuntime.eval(FieldAccess(bottomRight_handle, ArrayList<String>(["y"])))))
        }
        set(v) {
            // blob.bottomRight = v
            // ->
            DummyRuntime.eval(Assignment(blob.handle, ArrayList<String>(["bottomRight"]), v.blob.handle))
        }
    }

    public func perimeter(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.perimeter())
        // ->
        let perimeter_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["perimeter"])))
        DummyRuntime.fromExtern<Float64>(perimeter_handle)
    }

    public func area(): Float64 {
        // DummyRuntime.fromExtern<Float64>(blob.area())
        // ->
        let area_handle: Handle = DummyRuntime.eval(FieldAccess(blob.handle, ArrayList<String>(["area"])))
        DummyRuntime.fromExtern<Float64>(area_handle)
    }
    
}

main() {
    // ---- Int64 ----

    // let arkTs_fourty_two : Extern<DummyRuntime> = 42
    // ->
    let arkTs_fourty_two : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(42))

    // let fourty_two : Int64 = arkTs_fourty_two
    // ->
    let fourty_two : Int64 = DummyRuntime.fromExtern(arkTs_fourty_two.handle)

    println(fourty_two)

    // ---- String ----

    // let arkTs_hello_world : Extern<DummyRuntime> = "Hello World!"
    // ->
    let arkTs_hello_world : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern("Hello World!"))

    // let hello_world : String = arkTs_hello_world
    // ->
    let hello_world : String = DummyRuntime.fromExtern(arkTs_hello_world.handle)

    println(hello_world)

    // ---- UInt8 ----

    // let arkTs_one : Extern<DummyRuntime> = 1u8
    // ->
    let arkTs_one : Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(1u8))

    // let one : UInt8 = arkTs_one
    // ->
    let one : UInt8 = DummyRuntime.fromExtern(arkTs_one.handle)

    println(one)

    // ---- var Int64 ----
    let x: Int64 = 101
    
    // let arkTs_x: Extern<DummyRuntime> = x
    // ->
    let arkTs_x: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(x))

    // let y: Int64 = arkTs_x
    // ->
    let x_2: Int64 = DummyRuntime.fromExtern(arkTs_x.handle)

    println(x_2)

    // ---- lookup ----
    let result: Extern<DummyRuntime> = lookup(1.0, 2.0)

    // let result_value: (Float32, Float32) = result
    // ->
    let result_value: (Float32, Float32) = DummyRuntime.fromExtern(result.handle)
    println("(${result_value[0]}, ${result_value[1]})")

    // ---- Point ----
    let point: Point = Point(3.0, 4.0)

    println("Point: (${point.x}, ${point.y})")

    point.x = 5.0
    point.y = 6.0

    println("Point: (${point.x}, ${point.y})")

    // ---- Rectangle ----
    let rectangle: Rectangle = Rectangle(Point(0.0, 0.0), Point(10.0, 10.0))

    println("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")

    // rectangle.topLeft = Point(1.0, 1.0)
    // rectangle.bottomRight = Point(9.0, 9.0)
    
    // println("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}), (${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
    
    // println("Rectangle perimeter: ${rectangle.perimeter()}")
    // println("Rectangle area: ${rectangle.area()}")

    // println("Rectangle: (${rectangle.topLeft.x}, ${rectangle.topLeft.y}, ${rectangle.bottomRight.x}, ${rectangle.bottomRight.y})")
}
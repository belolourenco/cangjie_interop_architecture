package prototype2

import std.ast.*
import prototype2.extern.*
import prototype2.dummy_runtime.*

func lookup(lat: Float32, long: Float32): Extern<DummyRuntime> {
    let extModule: Extern<DummyRuntime> = DummyRuntime.getModule("geocoding") // I'm not sure about this! 

    // extModule.lookup(lat, long)
    // ->
    let e_lat: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(lat))
    let e_long: Extern<DummyRuntime> = Extern<DummyRuntime>(DummyRuntime.toExtern(long))
    Extern<DummyRuntime>(DummyRuntime.eval(parseExpr(quote($(extModule.handle).lookup($(e_lat.handle), $(e_long.handle))))))
}

// Alternative if we make getModule a method of the Runtime interface:
// class Point<T> where T <: Runtime {
class Point {
    private var blob : Extern<DummyRuntime>
    public Point(x: Float64, y: Float64) {
        let shapeModule: Extern<DummyRuntime> = DummyRuntime.getModule("shape")
        
        // blob = shapeModule.Point(x, y)
        // ->
        blob = Extern<DummyRuntime>(DummyRuntime.eval(parseExpr(quote($(shapeModule.handle).Point($(DummyRuntime.toExtern(x)), $(DummyRuntime.toExtern(y)))))))
    }

    public mut prop x: Float64 {
        get() {
            // blob.x
            // ->
            let x_handle: Handle = DummyRuntime.eval(parseExpr(quote($(blob.handle).x)))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.x = v
            // ->
            DummyRuntime.eval(parseExpr(quote($(blob.handle).x = $(DummyRuntime.toExtern(v)))))
        }
    }

    public mut prop y: Float64 {
        get() {
            // blob.y
            // ->
            let x_handle: Handle = DummyRuntime.eval(parseExpr(quote($(blob.handle).y)))
            DummyRuntime.fromExtern<Float64>(x_handle)
        }
        set(v) {
            // blob.y = v
            // ->
            DummyRuntime.eval(parseExpr(quote($(blob.handle).y = $(DummyRuntime.toExtern(v)))))
        }
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
}
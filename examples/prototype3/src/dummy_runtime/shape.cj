package prototype3.dummy_runtime

import std.math.*

public class Point {
    public Point(public var x: Float64, public var y: Float64) { }

    public func distanceTo(other: Point): Float64 {
        sqrt((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y))
    }
}

public interface Shape {
    func area(): Float64
    func perimeter(): Float64
}

public class Rectangle <: Shape {
    public Rectangle(public var topLeft: Point, public var bottomRight: Point) { }

    public func area(): Float64 {
        (bottomRight.x - topLeft.x) * (bottomRight.y - topLeft.y)
    }

    public func perimeter(): Float64 {
        (bottomRight.x - topLeft.x) * 2.0 + (bottomRight.y - topLeft.y) * 2.0
    }
}

public class Circle <: Shape {
    public Circle(public let center: Point, public let radius: Float64) { }

    public func area(): Float64 {
        Float64.getPI() * radius * radius
    }

    public func perimeter(): Float64 {
        Float64.getPI() * radius * 2.0
    }
}

public class Triangle <: Shape {
    public Triangle(public let a: Point, public let b: Point, public let c: Point) { }

    public func area(): Float64 {
        let s = (a.distanceTo(b) + b.distanceTo(c) + c.distanceTo(a)) / 2.0
        sqrt(s * (s - a.distanceTo(b)) * (s - b.distanceTo(c)) * (s - c.distanceTo(a)))
    }

    public func perimeter(): Float64 {
        a.distanceTo(b) + b.distanceTo(c) + c.distanceTo(a)
    }
}
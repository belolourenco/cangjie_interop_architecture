import hilog from "@ohos.hilog"

export function my_arkts_function(): void {
  hilog.info(0, "MYLOG", "my_arkts_function called")
}

export interface LookupResult {
  coordinates: number[]
  name: string
  city: string
  category: string
}

export function lookup(lat: number, long: number): LookupResult {
  hilog.info(0, "MYLOG", `lookup called with ${lat}, ${long}`)
  return {
    coordinates: [long, lat],
    name: "Space Needle",
    city: "Seattle",
    category: "Landmark"
  }
}

// Abstract class Shape
export abstract class Shape {
  constructor() {
  }

  // Abstract method for calculating area
  abstract area(): number;

  // Abstract method for calculating perimeter
  abstract perimeter(): number;
}

// Derived class Circle
export class Circle extends Shape {
  private radius: number
  constructor(radius: number) {
    super()
    this.radius = radius
  }

  getRadius(): number {
    return this.radius;
  }

  // Implement the area method for Circle
  area(): number {
    return Math.PI * this.radius ** 2;
  }

  // Implement the perimeter method for Circle
  perimeter(): number {
    return 2 * Math.PI * this.radius;
  }
}

// Derived class Rectangle
export class Rectangle extends Shape {
  private width: number
  private height: number
  constructor(width: number, height: number) {
    super()
    this.width = width
    this.height = height
  }

  getWidth(): number {
    return this.width;
  }

  getHeight(): number {
    return this.height;
  }

  // Implement the area method for Rectangle
  area(): number {
    return this.width * this.height;
  }

  // Implement the perimeter method for Rectangle
  perimeter(): number {
    return 2 * (this.width + this.height);
  }
}

// Derived class Triangle
export class Triangle extends Shape {
  private base: number
  private height: number
  constructor(base: number, height: number) {
    super()
    this.base = base;
    this.height = height;
  }

  getBase(): number {
    return this.base;
  }

  getHeight(): number {
    return this.height;
  }

  // Implement the area method for Triangle
  area(): number {
    return (0.5 * this.base * this.height);
  }

  // Implement the perimeter method for Triangle (Assuming it's an equilateral triangle)
  perimeter(): number {
    return 3 * this.base;
  }
}

// Create instances of Circle, Rectangle, and Triangle
export const circle = new Circle(5);
export const rectangle = new Rectangle(4, 6);
export const triangle = new Triangle(3, 4);

export function createRectangle(): Rectangle {
  let width = 12
  let height = 13
  return new Rectangle(width, height);
}

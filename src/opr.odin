package perfect_freehand

import "core:math"

// Linear interpolation between two Point2D
lrp :: proc(a, b: Point2D, t: f64) -> Point2D {
    return Point2D{
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t,
        pressure = a.pressure,
    };
}

// Negate a vector
neg :: proc(a: Point2D) -> Point2D {
    return Point2D{ x = -a.x, y = -a.y, pressure = a.pressure };
}

// Add vectors
add :: proc(a, b: Point2D) -> Point2D {
    return Point2D{ x = a.x + b.x, y = a.y + b.y, pressure = a.pressure };
}

// Subtract vectors
sub :: proc(a, b: Point2D) -> Point2D {
    return Point2D{ x = a.x - b.x, y = a.y - b.y, pressure = a.pressure };
}

// Multiply vector by scalar
mul :: proc(a: Point2D, n: f64) -> Point2D {
    return Point2D{ x = a.x * n, y = a.y * n, pressure = a.pressure };
}

// Divide vector by scalar
div :: proc(a: Point2D, n: f64) -> Point2D {
    return Point2D{ x = a.x / n, y = a.y / n, pressure = a.pressure };
}

// Perpendicular rotation
per :: proc(a: Point2D) -> Point2D {
    return Point2D{ x = a.y, y = -a.x, pressure = a.pressure };
}

// Dot product
dpr :: proc(a, b: Point2D) -> f64 {
    return a.x * b.x + a.y * b.y;
}

// Check if two points are equal (ignoring pressure)
isEqual :: proc(a, b: Point2D) -> bool {
    return a.x == b.x && a.y == b.y;
}

// Length of the vector
len_ :: proc(a: Point2D) -> f64 {
    return math.hypot(a.x, a.y);
}

// Length squared
len2 :: proc(a: Point2D) -> f64 {
    return a.x * a.x + a.y * a.y;
}

// Distance squared between two points
dist2 :: proc(a, b: Point2D) -> f64 {
    return len2(sub(a, b));
}

// Normalize (unit vector)
uni :: proc(a: Point2D) -> Point2D {
    l := len_(a);
    if l == 0.0 {
        return Point2D{ x = 0.0, y = 0.0, pressure = a.pressure };
    }
    return div(a, l);
}

// Distance between two points
dist :: proc(a, b: Point2D) -> f64 {
    return math.hypot(a.x - b.x, a.y - b.y);
}

// Midpoint between two points
med :: proc(a, b: Point2D) -> Point2D {
    return mul(add(a, b), 0.5);
}

// Rotate a vector around another by r radians
rotAround :: proc(a, c: Point2D, r: f64) -> Point2D {
    s := math.sin(r);
    co := math.cos(r);
    px := a.x - c.x;
    py := a.y - c.y;
    nx := px * co - py * s;
    ny := px * s + py * co;
    return Point2D{ x = nx + c.x, y = ny + c.y, pressure = a.pressure };
}

// Project a point a in the direction b by scalar c
prj :: proc(a, b: Point2D, c: f64) -> Point2D {
    return add(a, mul(b, c));
}
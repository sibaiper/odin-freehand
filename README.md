# Odin-Freehand

__A port of Steve Ruiz's library [perfect-freehand](https://github.com/steveruizok/perfect-freehand) to Odin__  


### Usage
To use this library, import the perfect_freehand and call the getStroke function on an array of input points, such as those recorded from a user's mouse movement. The getStroke function will return a new array of outline points. These outline points will form a polygon (called a "stroke") that surrounds the input points.

```Odin
import perfect_freehand "perfect_freehand"

points: [dynamic]perfect_freehand.Point2D,

// collect user input into points, and pass them to getStroke():

smoothed := perfect_freehand.getStroke(points)

// render however you like
```
You then can render your stroke points using your technology of choice.  


### Rendering
I have attached a very basic example in the examples directory, which looks something like this:  
```odin

points: [dynamic]perfect_freehand.Point2D,

for !rl.WindowShouldClose() {
    handle_input(); //function to collect points 

    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)

    smoothed := perfect_freehand.getStroke(app.points)
    // Convert to [dynamic]rl.Vector2 for drawing
    pts: [dynamic]rl.Vector2 = nil;
    for p in smoothed {
        append(&pts, rl.Vector2{f32(i32(p.x)), f32(i32(p.y))});
    }

    if len(pts) >= 4 {
        smooth_pts := catmull_rom_spline(pts, 8);
        rl.DrawLineStrip(&smooth_pts[0], i32(len(smooth_pts)), rl.RED);
    }

    rl.EndDrawing()
}
```


__For filled strokes__: unfortunately in Odin, it isn't as simple. To render a filled stroke, you probably want to triangulate the polygon. But I couldn't find any triangulation package/library to use for the render example, and I don't have time to spend creating one for just an example. But if you do happen to have a triangulation library in Odin, rendering would _probably_ look something like this (**PSEUDOCODE**):
```odin

points: [dynamic]perfect_freehand.Point2D,

// stroke polygon from perfect-freehand
smoothed := perfect_freehand.getStroke(points)

// convert to raylib Vector2 array
pts: [dynamic]rl.Vector2 = nil
for p in smoothed {
    append(&pts, rl.Vector2{f32(p.x), f32(p.y)})
}

// triangulate polygon -> produce a list of triangle indices
tris := earcut(pts)

// draw each triangle
for i in 0..<tris.len/3 {
    let a = pts[tris[i*3+0]]
    let b = pts[tris[i*3+1]]
    let c = pts[tris[i*3+2]]
    rl.DrawTriangle(a, b, c, rl.RED)
}
```
_keep in mind that this is only in theory. I can't be 100% sure it will work_

---

## Acknowledgements

This project is a port of [perfect-freehand](https://github.com/steveruizok/perfect-freehand)  
by [Steve Ruiz](https://github.com/steveruizok). Huge thanks to him for the original work.

## License

This project is licensed __as the original__ under the [MIT License](./LICENSE).

---
Copyright (c) 2021 Steve Ruiz - Original  
Copyright (c) 2025 Sibai Eshak - Odin port
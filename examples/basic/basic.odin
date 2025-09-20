package basic

import rl "vendor:raylib"
import "core:fmt"
import perfect_freehand "../../src"

Point :: struct {
    x: f32,
    y: f32,
    t: f64,
    pressure:f32,
}

App :: struct {
    points: [dynamic]perfect_freehand.Point2D,
}

main :: proc() {
    rl.InitWindow(800, 600, "perfect freehand")
    defer rl.CloseWindow()

    //flags
    rl.SetConfigFlags(rl.ConfigFlags{
        rl.ConfigFlag.WINDOW_RESIZABLE,
        rl.ConfigFlag.MSAA_4X_HINT,
        rl.ConfigFlag.VSYNC_HINT,
    })

    app := App{
        points=nil,
    }

    // important as to not sample too many points.
    rl.SetTargetFPS(60);
    
    for !rl.WindowShouldClose() {
        handle_input(&app);

        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)

        smoothed := perfect_freehand.getStroke(app.points)
        // Convert to [dynamic]rl.Vector2 for drawing
        pts: [dynamic]rl.Vector2 = nil;
        for p in smoothed {
            append(&pts, rl.Vector2{f32(i32(p.x)), f32(i32(p.y))});
        }
        
        // draw smoothed path (just as circles for now)
        // for p in pts {
        //     rl.DrawCircleV(p, 1, rl.BLUE)
        // }

        // for p in smoothed {
        //     rl.DrawCircle(i32(p.x), i32(p.y), 1, rl.RED)
        // }

        // draw filled shape if there are enough points
        // if len(pts) >= 3 {
        //     rl.DrawTriangleFan(&pts[0], i32(len(pts)), rl.Color{0, 120, 255, 80});
        // }


        // draw outline (old, pixelated)
        // if len(pts) >= 2 {
        //     rl.DrawLineStrip(&pts[0], i32(len(pts)), rl.BLUE);
        // }

        // draw smooth outline using Catmull-Rom spline
        if len(pts) >= 4 {
            smooth_pts := catmull_rom_spline(pts, 8); // 8 segments per curve for smoothness
            rl.DrawLineStrip(&smooth_pts[0], i32(len(smooth_pts)), rl.RED);
        }

        rl.EndDrawing()
    }
}


handle_input :: proc(app: ^App) {
    
    if(rl.IsMouseButtonDown(rl.MouseButton.LEFT)) {
        p := perfect_freehand.Point2D{
            x=f64(rl.GetMouseX()),
            y=f64(rl.GetMouseY()),
            pressure=1.0,
        }
        append(&app.points, p)
    }
}

// Catmull-Rom spline interpolation for [dynamic]rl.Vector2
catmull_rom_spline :: proc(points: [dynamic]rl.Vector2, segments_per_curve: int) -> [dynamic]rl.Vector2 {
    result: [dynamic]rl.Vector2 = nil;
    n := len(points);
    if n < 4 {
        // Not enough points for spline, just return input
        return points;
    }
    for i in 1..<n-2 {
        p0 := points[i-1];
        p1 := points[i];
        p2 := points[i+1];
        p3 := points[i+2];
        for j in 0..<segments_per_curve {
            t := f32(j) / f32(segments_per_curve);
            t2 := t*t;
            t3 := t2*t;
            x := 0.5 * ((2*p1.x) + (-p0.x + p2.x)*t + (2*p0.x - 5*p1.x + 4*p2.x - p3.x)*t2 + (-p0.x + 3*p1.x - 3*p2.x + p3.x)*t3);
            y := 0.5 * ((2*p1.y) + (-p0.y + p2.y)*t + (2*p0.y - 5*p1.y + 4*p2.y - p3.y)*t2 + (-p0.y + 3*p1.y - 3*p2.y + p3.y)*t3);
            append(&result, rl.Vector2{x, y});
        }
    }
    return result;
}

// Helper to convert [dynamic]perfect_freehand.Point2D to [dynamic]rl.Vector2
points2d_to_vector2 :: proc(points: [dynamic]perfect_freehand.Point2D) -> [dynamic]rl.Vector2 {
    result: [dynamic]rl.Vector2 = nil;
    for p in points {
        append(&result, rl.Vector2{f32(p.x), f32(p.y)});
    }
    return result;
}

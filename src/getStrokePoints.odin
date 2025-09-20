package perfect_freehand

StrokePoint :: struct {
    point: Point2D,
    pressure: f64,
    vector: Point2D,
    distance: f64,
    running_length: f64,
}


getStrokePoints :: proc(points: [dynamic]Point2D) -> [dynamic]StrokePoint {
    streamline := 0.5;
    size := 16.0;
    is_complete := false;

    if len(points) == 0 {
        return nil;
    }

    t := 0.15 + (1.0 - streamline) * 0.85;

    pts := points;
    if len(pts) == 2 {
        first := pts[0];
        last := pts[1];
        tmp: [dynamic]Point2D;
        append(&tmp, first);
        for i in 1..=4 {
            interp := lrp(first, last, f64(i)/4.0); 
            append(&tmp, interp);
        }
        append(&tmp, last);
        pts = tmp;
        delete(tmp);
    }

    if len(pts) == 1 {
        p := pts[0];
        append(&pts, Point2D{ x = p.x + 1, y = p.y + 1, pressure = p.pressure });
    }

    stroke_points: [dynamic]StrokePoint = nil;
    first := pts[0];
    pressure := 0.0; 
    if first.pressure >= 0 {
        pressure = first.pressure
    } else { 
        pressure = 0.25
    }
    append(&stroke_points, StrokePoint{
        point = first,
        pressure = pressure,
        vector = Point2D{ x = 1, y = 1, pressure = 0 },
        distance = 0,
        running_length = 0,
    });

    has_reached_minimum_length := false;
    running_length := 0.0;
    prev := stroke_points[0];
    max := len(pts) - 1;

    for i in 1..<len(pts) {
        point: Point2D;
        if is_complete && i == max {
            point = pts[i];
        } else {
            point = lrp(prev.point, pts[i], t);
        }

        if isEqual(prev.point, point) {
            continue;
        }

        distance := dist(point, prev.point);
        running_length += distance;

        if i < max && !has_reached_minimum_length {
            if running_length < size {
                continue;
            }
            has_reached_minimum_length = true;
        }

        vec := uni(sub(prev.point, point));
        pressure := 0.0;
        if pts[i].pressure >= 0 {
            pressure = pts[i].pressure
        } else {
            pressure = 0.5
        };

        prev = StrokePoint{
            point = point,
            pressure = pressure,
            vector = vec,
            distance = distance,
            running_length = running_length,
        };
        append(&stroke_points, prev);
    }

    if len(stroke_points) > 1 {
        stroke_points[0].vector = stroke_points[1].vector;
    } else {
        stroke_points[0].vector = Point2D{ x = 0, y = 0, pressure = 0 };
    }
    
    return stroke_points;
}
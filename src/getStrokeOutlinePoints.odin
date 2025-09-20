package perfect_freehand

import "core:math"

RATE_OF_PRESSURE_CHANGE :: 0.275
FIXED_PI :: math.PI + 0.0001;

getStrokeOutlinePoints:: proc(points: [dynamic]StrokePoint) -> [dynamic]Point2D {
    size := 16
    smoothing := 0.5
    thinning := 0.5
    simulatePressure := true
    is_complete := false
    easing := proc(t: f64) -> f64 {
        return t;
    };
    taperStartEase := proc(t: f64) -> f64 {
        return t * (2 - t);
    };
    taperEndEase := proc(t: f64) -> f64 {
        t_ := t - 1;
        return t_ * t_ * t_ + 1;
    };
    capStart := true
    capEnd := true

    if( len(points) == 0 ) {
        return make([dynamic]Point2D, 0);
    }

    totalLength := points[len(points)-1].running_length


    // taper_start := 0.0;
    // taper_end := 0.0;
    // taper_start := 10.0;
    // taper_end := 10.0;
    taper_start := math.max(f64(size), totalLength);
    taper_end := math.max(f64(size), totalLength);
    
    // minimum allowed distance between points (squared)
    minDistance := math.pow_f64(f64(size) * smoothing, 2);

    
    // our collected left and right points
    leftPts : [dynamic]Point2D = nil;
    rightPts : [dynamic]Point2D = nil;

    prev_pressure := points[0].pressure    

    // the current radius
    radius := getStrokeRadius(f64(size), thinning, points[len(points) - 1].pressure, easing)

    // radius of the first saved point:
    firstRadius := 0.0;
    
    // previous vector
    prevVector := points[0].vector;
    
    // previous left and right points 
    pl := points[0].point;
    pr := pl;

    // temp left and righ points:
    tl := pl;
    tr := pr;

    // keep track of whether the previous point is a sharp corner
    // ... so that we don't detect the same corner twice
    isPrevPointSharpCorner := false;
    
    // short := true;

    /*
     Find the outline's left and right points

     Iterating through the points and poplate the rightPts and leftPts arrays,
     skipping the first and last pointsm, which will get caps later on
    */

    for i := 0; i < len(points); i += 1 {
        point := points[i].point;
        vector := points[i].vector;
        distance := points[i].distance;
        running_length := points[i].running_length;

        // Simulate pressure if needed
        pressure := points[i].pressure;
        if simulatePressure {
            sp := math.min(1.0, distance / f64(size));
            rp := math.min(1.0, 1.0 - sp);
            pressure = math.min(1.0, prev_pressure + (rp - prev_pressure) * (sp * RATE_OF_PRESSURE_CHANGE));
        }

        /*
         Calculate the radius

         If not thinning, the current point's radius will be half the size; or
         otherwise, the size will be based on the current (real or simulated)
         pressure.
        */
        if(thinning > 0.0) {
            radius = getStrokeRadius(f64(size), thinning, pressure, easing);
        } else {
            radius = f64(size) / 2;
        }

        if firstRadius <= 0.0 {
            firstRadius = radius;
        }

        /*
        Apply tapering

        If the current length is within the taper distance at either the
        start or the end, calculate the taper strengths. Apply the smaller 
        of the two taper strengths to the radius.
        */
        
        ts := running_length < taper_start ? taperStartEase(running_length / taper_start) : 1;
        te := totalLength - running_length < taper_end ? taperEndEase(totalLength - running_length / taper_end) : 1;
        radius = math.max(0.01, radius * math.min(ts, te));
        /* Add points to left and right */

        /*
        Handle sharp corners

        Find the difference (dot product) between the current and next vector.
        If the next vector is at more than a right angle to the current vector,
        draw a cap at the current point.
        */

        // Handle sharp corners
        nextVector := (i < len(points) - 1 ? points[i + 1] : points[i]).vector;
        nextDpr := i < len(points) - 1 ? dpr(vector, nextVector) : 1.0;
        prevDpr := dpr(vector, prevVector);
        isPointSharpCorner := prevDpr < 0 && !isPrevPointSharpCorner;
        isNextPointSharpCorner := nextDpr < 0 && nextDpr < 0;

        if isPointSharpCorner || isNextPointSharpCorner {
            // It's a sharp corner. Draw a rounded cap and move on to the next point
            // Considering saving these and drawing them later? So that we can avoid
            // crossing future points.
            offset := mul(per(prevVector), radius);
            step := 1.0 / 13.0;
            for t := 0.0; t <= 1.0; t += step {
                tl := rotAround(sub(point, offset), point, FIXED_PI * t);
                append(&leftPts, tl);
                tr := rotAround(add(point, offset), point, FIXED_PI * -t);
                append(&rightPts, tr);
            }
            pl = tl;
            pr = tr;
            if isNextPointSharpCorner {
                isPrevPointSharpCorner = true;
            }
            prev_pressure = pressure;
            prevVector = vector;
            continue;
        }

        isPrevPointSharpCorner = false;

        // Handle the last point
        if (i == len(points) - 1) {
            offset := mul(per(vector), radius);
            append(&leftPts, sub(point, offset));
            append(&rightPts, add(point, offset));
            prev_pressure = pressure;
            prevVector = vector;
            continue;
        }

        /* 
        Add regular points

        Project points to either side of the current point, using the
        calculated size as a distance. If a point's distance to the 
        previous point on that side greater than the minimum distance
        (or if the corner is kinda sharp), add the points to the side's
        points array.
        */
        offset := mul(per(lrp(nextVector, vector, nextDpr)), radius);
        tl = sub(point, offset);
        if i <= 1 || dist2(pl, tl) > minDistance {
            append(&leftPts, tl);
            pl = tl;
        }
        tr = add(point, offset);
        if i <= 1 || dist2(pr, tr) > minDistance {
            append(&rightPts, tr);
            pr = tr;
        }

        // set variables for next iteration
        prev_pressure = pressure;
        prevVector = vector;
    }

    /*
        Drawing caps
        
        Now that we have our points on either side of the line, we need to
        draw caps at the start and end. Tapered lines don't have caps, but
        may have dots for very short lines.
    */

    
    // Point2D; (x, y)
    firstPoint := points[0].point
    lastPoint := len(points) > 1 ? points[len(points) - 1].point : add(points[0].point, Point2D{x=1, y=1})

    startCap : [dynamic]Point2D = make([dynamic]Point2D)
    endCap : [dynamic]Point2D = make([dynamic]Point2D)
    
    /* 
        Draw a dot for very short or completed strokes
        
        If the line is too short to gather left or right points and if the line is
        not tapered on either side, draw a dot. If the line is tapered, then only
        draw a dot if the line is both very short and complete. If we draw a dot,
        we can just return those points.
    */


        /*
            If you want to check if both are zero (i.e., "not tapered"), do this:
            no_taper := taper_start == 0.0 && taper_end == 0.0;
            if (no_taper || is_complete) {
                // ...
            }
            Or, if you want to check if either is zero:
            either_no_taper := taper_start == 0.0 || taper_end == 0.0;
            if (either_no_taper || is_complete) {
                // ...
            }
        */

    if (len(points) == 1) {

    no_taper := taper_start == 0.0 && taper_end == 0.0;
    if (no_taper || is_complete) {
        r : f64 = 0.0;
        if(firstRadius > 0.0) {
            r = firstRadius
        } else {
            r = radius; 
        }
        start := prj(
                firstPoint,
                uni(per(sub(firstPoint, lastPoint))),
                -r
            )
        // const dotPts: number[][] = []
        dotPts:= make([dynamic]Point2D, 0);
        step := 1.0 / 13.0
        for t := 0.0; t <= 1.0; t += step {
            append(&dotPts, rotAround(start, firstPoint, FIXED_PI * 2 * t));
        }
        }
    } else {
        /*
            Draw a start cap

            Unless the line has a tapered start, or unless the line has a tapered end
            and the line is very short, draw a start cap around the first point. Use
            the distance between the second left and right point for the cap's radius.
            Finally remove the first left and right points. :psyduck:
        */

        tapered_start := taper_start > 0.0 || (taper_end > 0.0 && len(points) == 1);
        if tapered_start {
            // The start point is tapered, noop
        } else if capStart {
            step := 1.0 / 13.0;
            for t := step; t <= 1.0; t += step {
                pt := rotAround(rightPts[0], firstPoint, FIXED_PI * t);
                append(&startCap, pt);
            }
        } else {
            cornersVector := sub(leftPts[0], rightPts[0]);
            offsetA := mul(cornersVector, 0.5);
            offsetB := mul(cornersVector, 0.51);

            append(&startCap, sub(firstPoint, offsetA));
            append(&startCap, sub(firstPoint, offsetB));
            append(&startCap, add(firstPoint, offsetB));
            append(&startCap, add(firstPoint, offsetA));
        }

        /*
            Draw an end cap

            If the line does not have a tapered end, and unless the line has a tapered
            start and the line is very short, draw a cap around the last point. Finally,
            remove the last left and right points. Otherwise, add the last point. Note
            that This cap is a full-turn-and-a-half: this prevents incorrect caps on
            sharp end turns.
        */

        direction := per(neg(points[len(points) - 1].vector))
        
        if taper_end > 0.0 || (taper_start > 0.0 && len(points) == 1) {
            // Tapered end - push the last point to the line
            append(&endCap, lastPoint);
        } else if capEnd {
            // draw the round end cap:
            start := prj(lastPoint, direction, radius);
            step := 1.0 / 29.0;
            for t := step; t <= 1.0; t += step {
                append(&endCap, rotAround(start, lastPoint, FIXED_PI * 3 * t));
            }
        } else {
            // draw the flat end cap

            append(&endCap,
                add(lastPoint, mul(direction, radius)),
                add(lastPoint, mul(direction, radius * 0.99)),
                sub(lastPoint, mul(direction, radius * 0.99)),
                sub(lastPoint, mul(direction, radius))
            )
        }

    }
    
    
    
    /*
        Return the points in the correct winding order: begin on the left side, then 
        continue around the end cap, then come back along the right side, and finally 
        complete the start cap.
    */

    // behaviour to replicate in Odin:
    // return leftPts.concat(endCap, rightPts.reverse(), startCap)

    // reverse rightPts into a new slice
    rev_right := make([dynamic]Point2D, len(rightPts))
    for i := 0; i < len(rightPts); i += 1 {
        rev_right[i] = rightPts[len(rightPts) - 1 - i]
    }

    // concatenate all into one result slice
    result := make([dynamic]Point2D, 0, len(leftPts) + len(endCap) + len(rev_right) + len(startCap))

    // append(&result, leftPts)
    for pt in leftPts {
        append(&result, pt)
    }
    // append(&result, endCap)
    for pt in endCap {
        append(&result, pt)
    }
    // append(&result, rev_right)
    for pt in rev_right {
        append(&result, pt)
    }
    // append(&result, startCap)
    for pt in startCap {
        append(&result, pt)
    }

    delete(leftPts)
    delete(rightPts)
    delete(startCap)
    delete(endCap)
    delete(rev_right)

    return result
}
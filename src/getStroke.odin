package perfect_freehand

getStroke :: proc (points: [dynamic]Point2D) -> [dynamic]Point2D {
    return getStrokeOutlinePoints(getStrokePoints(points));
}
package perfect_freehand

identity_easing :: proc(t: f64) -> f64 {
    return t
}

getStrokeRadius :: proc(
    size: f64,
    thinning: f64,
    pressure: f64,
    easing: proc(t: f64) -> f64 = identity_easing,
) -> f64 {
    return size * easing(0.5 - thinning * (0.5 - pressure))
}
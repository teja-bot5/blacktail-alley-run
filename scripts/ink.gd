class_name Ink
extends RefCounted
## Hand-drawn comic helpers for CanvasItem._draw(): wobbly ink lines, plaster,
## cracks, exposed brick, union-outlined blobs (clouds, foliage).

const LINE := Color(0.12, 0.08, 0.06)
const W := 3.0


static func pts(arr: Array) -> PackedVector2Array:
	return PackedVector2Array(arr)


static func rect_pts(r: Rect2) -> PackedVector2Array:
	return pts([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Subdivide and jitter a path perpendicular to each segment.
static func wobble(rng: RandomNumberGenerator, p: PackedVector2Array, closed: bool, amp := 1.1, step := 14.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := p.size()
	var segs := n if closed else n - 1
	for i in segs:
		var a := p[i]
		var b := p[(i + 1) % n]
		var k := maxi(1, int(a.distance_to(b) / step))
		var nrm := (b - a).orthogonal().normalized()
		for j in k:
			var off := 0.0 if j == 0 else rng.randf_range(-amp, amp)
			out.append(a.lerp(b, float(j) / k) + nrm * off)
	if closed:
		out.append(out[0])
	else:
		out.append(p[n - 1])
	return out


static func line(ci: CanvasItem, rng: RandomNumberGenerator, p: PackedVector2Array, closed := false, width := W, col := LINE) -> void:
	ci.draw_polyline(wobble(rng, p, closed), col, width * rng.randf_range(0.85, 1.15), true)


static func poly(ci: CanvasItem, rng: RandomNumberGenerator, p: PackedVector2Array, fill: Color, width := W) -> void:
	ci.draw_colored_polygon(p, fill)
	if width > 0.0:
		line(ci, rng, p, true, width)


static func box(ci: CanvasItem, rng: RandomNumberGenerator, r: Rect2, fill: Color, width := W) -> void:
	poly(ci, rng, rect_pts(r), fill, width)


static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(rect_pts(r), PackedColorArray([top, top, bottom, bottom]))


static func ellipse(c: Vector2, rx: float, ry: float, n := 20, from := 0.0, to := TAU) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(from, to, float(i) / n)
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## Stains, speckles and dry-brush strokes inside `r`.
static func plaster(ci: CanvasItem, rng: RandomNumberGenerator, r: Rect2, base: Color) -> void:
	for i in int(r.get_area() / 18000.0) + 2:
		var p := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
		var edge := minf(minf(p.x - r.position.x, r.end.x - p.x), minf(p.y - r.position.y, r.end.y - p.y))
		var rad := minf(rng.randf_range(18.0, 60.0), edge)
		if rad > 4.0:
			ci.draw_circle(p, rad, Color(base.darkened(0.3), 0.07))
	for i in int(r.get_area() / 260.0):
		var p := Vector2(rng.randf_range(r.position.x, r.end.x - 3), rng.randf_range(r.position.y, r.end.y - 2))
		var c := base.darkened(0.35) if rng.randf() < 0.6 else base.lightened(0.25)
		ci.draw_rect(Rect2(p, Vector2(rng.randf_range(1.0, 3.5), 1.4)), Color(c, 0.35))
	for i in int(r.get_area() / 9000.0):
		var p := Vector2(rng.randf_range(r.position.x + 10, r.end.x - 30), rng.randf_range(r.position.y + 6, r.end.y - 6))
		ci.draw_line(p, p + Vector2(rng.randf_range(10, 26), rng.randf_range(-2, 2)), Color(base.darkened(0.25), 0.25), 1.2, true)


## Branching crack from `start` heading roughly along `dir`.
static func crack(ci: CanvasItem, rng: RandomNumberGenerator, start: Vector2, dir: Vector2, length: float, depth := 0) -> void:
	var p := start
	var path := PackedVector2Array([p])
	var steps := int(length / 7.0)
	for i in steps:
		dir = dir.rotated(rng.randf_range(-0.6, 0.6)).normalized()
		p += dir * rng.randf_range(5.0, 9.0)
		path.append(p)
		if depth < 2 and rng.randf() < 0.12:
			crack(ci, rng, p, dir.rotated(rng.randf_range(-1.2, 1.2)), length * 0.45, depth + 1)
	ci.draw_polyline(path, Color(1, 0.95, 0.85, 0.35), 1.0, true)
	for i in path.size():
		path[i] += Vector2(0.8, 0.8)
	ci.draw_polyline(path, LINE, maxf(0.8, 1.6 - depth * 0.4), true)


## Chipped plaster revealing brickwork, clipped to an irregular blob.
static func bricks(ci: CanvasItem, rng: RandomNumberGenerator, center: Vector2, size: Vector2, wall: Color) -> void:
	var blob := PackedVector2Array()
	for i in 11:
		var a := TAU * i / 11.0
		blob.append(center + Vector2(cos(a) * size.x, sin(a) * size.y) * rng.randf_range(0.65, 1.1))
	ci.draw_colored_polygon(blob, Color(0.45, 0.27, 0.2))
	var bw := 22.0
	var bh := 9.0
	var y := center.y - size.y
	var row := 0
	while y < center.y + size.y:
		var x := center.x - size.x - (bw * 0.5 if row % 2 else 0.0)
		while x < center.x + size.x:
			var r := Rect2(x + 1, y + 1, bw - 2, bh - 2)
			if Geometry2D.is_point_in_polygon(r.get_center(), blob):
				var c := Color(0.68, 0.32, 0.22).darkened(rng.randf_range(-0.1, 0.25))
				ci.draw_rect(r, c)
				ci.draw_line(r.position + Vector2(0, r.size.y), r.end, Color(0.25, 0.12, 0.08, 0.6), 1.2)
			x += bw
		y += bh
		row += 1
	line(ci, rng, blob, true, 4.0, wall.lightened(0.15))
	line(ci, rng, blob, true, 1.8)


## Union of circles with a single outer ink outline (clouds, trees, bushes).
static func blobs(ci: CanvasItem, circles: Array, fill: Color, shade: Color, width := 2.5) -> void:
	for c in circles:
		ci.draw_circle(c[0], c[1] + width, LINE)
	for c in circles:
		ci.draw_circle(c[0], c[1], fill)
	for c in circles:
		ci.draw_circle(c[0] + Vector2(c[1] * 0.15, c[1] * 0.3), c[1] * 0.75, shade)


## Script-like squiggles for shop signs (not real words).
static func squiggle(ci: CanvasItem, rng: RandomNumberGenerator, r: Rect2, col: Color, width := 3.0) -> void:
	var x := r.end.x - 6
	while x > r.position.x + 12:
		var w := rng.randf_range(14, 30)
		var p := PackedVector2Array()
		for i in 7:
			var t := float(i) / 6.0
			p.append(Vector2(x - w * t, r.get_center().y + sin(t * PI * rng.randf_range(1.0, 2.5)) * r.size.y * 0.28))
		ci.draw_polyline(p, col, width, true)
		if rng.randf() < 0.5:
			ci.draw_circle(Vector2(x - w * 0.5, r.position.y + r.size.y * 0.22), width * 0.7, col)
		x -= w + rng.randf_range(4, 9)

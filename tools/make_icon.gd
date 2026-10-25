extends SceneTree
## Dev tool: renders the BLACKTAIL app icons (hand-inked black cat head, amber
## eyes, terracotta background) into icons/. Run:
##   xvfb-run godot --rendering-driver opengl3 -s tools/make_icon.gd
## Outputs: icon.png (512, project icon), icons/android_192.png,
##          icons/adaptive_fg_432.png (transparent, head inside the safe zone),
##          icons/adaptive_bg_432.png

const N := 1024
const BG := Color(0.79, 0.4, 0.31)
const INK := Color(0.04, 0.035, 0.035)
const AMBER := Color(1.0, 0.71, 0.1)

var vp: SubViewport
var art: Node2D
var jobs := [
	# [head scale, draw background, draw head, outputs [[path, size], ...]]
	[1.3, true, true, [["res://icon.png", 512], ["res://icons/android_192.png", 192]]],
	[1.0, false, true, [["res://icons/adaptive_fg_432.png", 432]]],
	[1.0, true, false, [["res://icons/adaptive_bg_432.png", 432]]],
]
var job := 0
var frames := 0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://icons"))
	vp = SubViewport.new()
	vp.size = Vector2i(N, N)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	art = Node2D.new()
	art.draw.connect(_paint)
	vp.add_child(art)


func _process(_d: float) -> bool:
	if job >= jobs.size():
		return true
	frames += 1
	if frames == 1:
		art.queue_redraw()
	elif frames >= 4:
		var img := vp.get_texture().get_image()
		for out in jobs[job][3]:
			var copy := img.duplicate()
			copy.resize(out[1], out[1], Image.INTERPOLATE_LANCZOS)
			copy.save_png(out[0])
		job += 1
		frames = 0
	return false


func _paint() -> void:
	var j: Array = jobs[job]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	if j[1]:
		art.draw_rect(Rect2(0, 0, N, N), BG)
		for i in 120:  # dry-brush grain
			var p := Vector2(rng.randf() * N, rng.randf() * N)
			art.draw_circle(p, rng.randf_range(1.5, 4.0), Color(BG.darkened(0.18), 0.35))
	if j[2]:
		art.draw_set_transform(Vector2(N * 0.5, N * 0.52), 0.0, Vector2.ONE * j[0])
		_head(rng)
		art.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _head(rng: RandomNumberGenerator) -> void:
	# Head outline (centred on 0,0): ears, tufted cheeks, pointed chin.
	var right := [Vector2(0, -210), Vector2(120, -200), Vector2(270, -330), Vector2(250, -130),
		Vector2(235, -60), Vector2(290, 10), Vector2(240, 25), Vector2(275, 85), Vector2(215, 95),
		Vector2(220, 150), Vector2(150, 160), Vector2(95, 245)]
	var outline := PackedVector2Array([Vector2(0, 290)])
	for i in range(right.size() - 1, -1, -1):
		outline.append(right[i])
	for p in right.slice(1):
		outline.append(Vector2(-p.x, p.y))
	outline.reverse()
	# Hand-inked edge: subdivide and roughen, with small fur flicks.
	var rough := PackedVector2Array()
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var n := (b - a).orthogonal().normalized()
		var steps := maxi(2, int(a.distance_to(b) / 14.0))
		for k in steps:
			var off := rng.randf_range(-3.5, 3.5) + (7.0 if rng.randf() < 0.06 else 0.0)
			rough.append(a.lerp(b, float(k) / steps) - n * off)
	art.draw_colored_polygon(rough, INK)
	# Whiskers: tapered ink strokes past the cheeks.
	for side in [-1.0, 1.0]:
		for w in [[Vector2(70, 150), Vector2(330, 105)], [Vector2(75, 168), Vector2(345, 175)], [Vector2(65, 185), Vector2(300, 245)]]:
			var a: Vector2 = Vector2(w[0].x * side, w[0].y)
			var b: Vector2 = Vector2(w[1].x * side, w[1].y)
			var n := (b - a).orthogonal().normalized()
			art.draw_colored_polygon(PackedVector2Array([a + n * 5, b, a - n * 5]), INK)
	# Fierce amber eyes: flat, slanted upper lid, slit pupil, glint.
	for side in [-1.0, 1.0]:
		var c := Vector2(98 * side, 25)
		var inner := c + Vector2(-60 * side, 28)
		var outer := c + Vector2(70 * side, -30)
		var eye := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			eye.append(_quad(inner, c + Vector2(4 * side, -18), outer, t))
		for k in range(1, 12):
			var t := k / 12.0
			eye.append(_quad(outer, c + Vector2(12 * side, 60), inner, t))
		art.draw_colored_polygon(eye, AMBER)
		art.draw_colored_polygon(_ellipse(c + Vector2(6 * side, 8), 10, 28), INK)
		art.draw_circle(c + Vector2(-12 * side, 0), 7, Color(1, 0.97, 0.88))
	# Nose and a little dry-brush texture.
	art.draw_colored_polygon(PackedVector2Array([Vector2(-20, 128), Vector2(20, 128), Vector2(0, 150)]), Color(0.86, 0.47, 0.42))
	for i in 14:  # a few dry-brush flecks on the forehead and ears only
		var p := Vector2(rng.randf_range(-170, 170), rng.randf_range(-230, -90))
		if true:
			art.draw_circle(p, rng.randf_range(1.5, 3.0), Color(BG, 0.55))


func _quad(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out

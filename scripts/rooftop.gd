class_name Rooftop
extends Node2D
## One runnable building: roof line at local y = 0, facade drawn below,
## rooftop decor and obstacles above. Everything is drawn procedurally.

const WALLS := [
	Color(0.80, 0.60, 0.36),  # ochre
	Color(0.84, 0.55, 0.42),  # terracotta
	Color(0.87, 0.67, 0.50),  # peach tan
	Color(0.80, 0.54, 0.50),  # dusty pink
	Color(0.76, 0.63, 0.44),  # khaki
]
const ROOF := Color(0.80, 0.73, 0.62)
const DEPTH := 460.0
# Obstacle sizes (px). "rug" is a hanging rug on a rope: slide under it.
const KINDS := {
	"tank": Vector2(76, 96),
	"crate": Vector2(64, 54),
	"rug": Vector2(150, 128),
}
const RUG_CLEAR := 46.0  # gap under the rug

var w := 800.0
var obstacles: Array = []  # {kind, rect (local), hit}
var fish_spots: Array = []  # local positions
var wall: Color
var rng := RandomNumberGenerator.new()
var _seed := 0


func setup(width: float, seed_value: int, with_obstacles: bool) -> void:
	w = width
	_seed = seed_value
	rng.seed = seed_value
	wall = WALLS[rng.randi() % WALLS.size()]
	if with_obstacles:
		var x := rng.randf_range(480.0, 640.0)
		while x < w - 220.0:
			var kind: String = ["tank", "crate", "rug"][rng.randi() % 3]
			var s: Vector2 = KINDS[kind]
			var r := Rect2(x, -s.y, s.x, s.y)
			if kind == "rug":
				r = Rect2(x + 12, -s.y + 8, s.x - 24, s.y - 8 - RUG_CLEAR)
			obstacles.append({"kind": kind, "x": x, "rect": r, "hit": false})
			# Fish arc over jumpable obstacles, low row under rugs.
			for i in 3:
				var fx := x + s.x * 0.5 + (i - 1) * 46.0
				var fy := -24.0 if kind == "rug" else -s.y - 50.0 - (14.0 if i == 1 else 0.0)
				fish_spots.append(Vector2(fx, fy))
			x += s.x + rng.randf_range(380.0, 620.0)
	var fx2 := 150.0
	while fx2 < w - 120.0:
		if _free(fx2, 60.0) and rng.randf() < 0.35:
			for i in 4:
				fish_spots.append(Vector2(fx2 + i * 44.0, -36.0))
			fx2 += 260.0
		fx2 += 180.0
	queue_redraw()


func _free(x: float, margin: float) -> bool:
	for o in obstacles:
		if x > o.x - margin - 180.0 and x < o.x + o.rect.size.x + margin + 40.0:
			return false
	return true


func _draw() -> void:
	rng.seed = _seed * 7919 + 13
	var face := Rect2(0, 12, w, DEPTH)
	Ink.vgrad(self, Rect2(0, 12, w, 300), wall.lightened(0.04), wall.darkened(0.42))
	draw_rect(Rect2(0, 312, w, DEPTH - 300), wall.darkened(0.42))
	Ink.plaster(self, rng, face.grow_individual(-4, 0, -4, -DEPTH + 260), wall)
	_weathering()
	_features(face)
	# Dramatic diagonal shadow from a neighbouring building.
	var sx := rng.randf_range(0.25, 0.6) * w
	draw_colored_polygon(Ink.pts([Vector2(0, 30), Vector2(sx, 30), Vector2(sx * 0.35, DEPTH), Vector2(0, DEPTH)]), Color(0.25, 0.08, 0.04, 0.2))
	Ink.line(self, rng, Ink.pts([Vector2(0, 12), Vector2(0, DEPTH)]), false, 3.2)
	Ink.line(self, rng, Ink.pts([Vector2(w, 12), Vector2(w, DEPTH)]), false, 3.2)
	# Roof slab + parapet lip with cast shadow beneath.
	draw_rect(Rect2(0, 18, w, 26), Color(0.15, 0.06, 0.03, 0.38))
	Ink.box(self, rng, Rect2(-8, -5, w + 16, 24), ROOF)
	draw_rect(Rect2(-6, 10, w + 12, 7), ROOF.darkened(0.22))
	draw_line(Vector2(-4, -2), Vector2(w + 4, -2), ROOF.lightened(0.35), 2.0)
	for i in int(w / 120.0):
		var cx := rng.randf_range(10, w - 30)
		draw_line(Vector2(cx, 1), Vector2(cx + rng.randf_range(8, 24), rng.randf_range(4, 11)), Color(Ink.LINE, 0.45), 1.2, true)
	_decor()
	for o in obstacles:
		call("_obstacle_" + o.kind, o)


func _features(face: Rect2) -> void:
	var x := rng.randf_range(30.0, 90.0)
	while x < w - 120.0:
		var pick := rng.randf()
		if pick < 0.32:
			_window(Rect2(x, rng.randf_range(70, 110), rng.randf_range(70, 96), rng.randf_range(84, 110)))
			x += 140.0
		elif pick < 0.48:
			_ac(Vector2(x, rng.randf_range(60, 120)))
			x += 130.0
		elif pick < 0.62:
			_rug(Rect2(x, 36, rng.randf_range(96, 130), rng.randf_range(120, 160)))
			x += 170.0
		elif pick < 0.74:
			_sign(Rect2(x, rng.randf_range(60, 90), rng.randf_range(120, 170), 52))
			x += 200.0
		else:
			x += 90.0
		x += rng.randf_range(30.0, 110.0)


func _weathering() -> void:
	for i in rng.randi_range(1, 3):
		Ink.bricks(self, rng, Vector2(rng.randf_range(60, w - 60), rng.randf_range(60, 230)), Vector2(rng.randf_range(36, 70), rng.randf_range(22, 44)), wall)
	for i in rng.randi_range(2, 4):
		Ink.crack(self, rng, Vector2(rng.randf_range(20, w - 20), 30), Vector2(rng.randf_range(-0.4, 0.4), 1), rng.randf_range(40, 120))
	if rng.randf() < 0.6:  # drain pipe
		var px := rng.randf_range(20, w - 20)
		Ink.box(self, rng, Rect2(px, 28, 9, DEPTH), Color(0.55, 0.52, 0.48), 2.0)
		for k in 4:
			draw_rect(Rect2(px - 3, 60 + k * 90, 15, 5), Ink.LINE)


func _window(r: Rect2) -> void:
	Ink.box(self, rng, r.grow(7), wall.lightened(0.12), 2.6)
	Ink.box(self, rng, r, Color(0.2, 0.15, 0.13), 2.4)
	draw_colored_polygon(Ink.pts([r.position + Vector2(r.size.x * 0.55, 0), r.position + Vector2(r.size.x, 0), r.position + Vector2(r.size.x * 0.25, r.size.y)]), Color(0.45, 0.6, 0.62, 0.35))
	for k in range(1, 4):
		var gx := r.position.x + r.size.x * k / 4.0
		draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), Ink.LINE, 2.0)
	if rng.randf() < 0.5:  # teal shutter
		Ink.box(self, rng, Rect2(r.end.x + 4, r.position.y - 4, r.size.x * 0.4, r.size.y + 8), Color(0.24, 0.55, 0.56), 2.4)
	draw_rect(Rect2(r.position.x - 10, r.end.y + 7, r.size.x + 20, 7), Color(0.15, 0.06, 0.03, 0.3))


func _ac(p: Vector2) -> void:
	var r := Rect2(p, Vector2(92, 62))
	Ink.box(self, rng, r, Color(0.88, 0.87, 0.82), 2.6)
	draw_circle(r.position + Vector2(32, 31), 22, Color(0.3, 0.3, 0.3))
	draw_arc(r.position + Vector2(32, 31), 22, 0, TAU, 24, Ink.LINE, 2.2, true)
	for k in 5:
		var a := TAU * k / 5.0
		draw_line(r.position + Vector2(32, 31), r.position + Vector2(32, 31) + Vector2(cos(a), sin(a)) * 19, Color(0.75, 0.75, 0.72), 3.0)
	for k in 5:
		draw_line(r.position + Vector2(62, 12 + k * 9), r.position + Vector2(86, 12 + k * 9), Color(0.5, 0.5, 0.48), 2.0)
	draw_rect(Rect2(r.position.x, r.end.y, r.size.x, 6), Color(0.15, 0.06, 0.03, 0.3))
	Ink.line(self, rng, Ink.pts([r.position + Vector2(80, 62), r.position + Vector2(84, 110), r.position + Vector2(70, 160)]), false, 2.0)


func _rug(r: Rect2) -> void:
	Ink.box(self, rng, r, Color(0.62, 0.17, 0.13), 2.6)
	Ink.box(self, rng, r.grow(-8), Color(0.76, 0.48, 0.22), 1.6)
	Ink.box(self, rng, r.grow(-14), Color(0.55, 0.14, 0.12), 1.6)
	var c := r.get_center()
	var d := minf(r.size.x, r.size.y) * 0.3
	Ink.poly(self, rng, Ink.pts([c + Vector2(0, -d * 1.3), c + Vector2(d, 0), c + Vector2(0, d * 1.3), c + Vector2(-d, 0)]), Color(0.2, 0.25, 0.4), 1.6)
	Ink.poly(self, rng, Ink.pts([c + Vector2(0, -d * 0.6), c + Vector2(d * 0.45, 0), c + Vector2(0, d * 0.6), c + Vector2(-d * 0.45, 0)]), Color(0.86, 0.68, 0.3), 1.2)
	for k in 6:
		var y := r.position.y + 22 + k * (r.size.y - 44) / 5.0
		draw_circle(Vector2(r.position.x + 20, y), 3, Color(0.86, 0.68, 0.3))
		draw_circle(Vector2(r.end.x - 20, y), 3, Color(0.86, 0.68, 0.3))
	var fx := r.position.x + 4
	while fx < r.end.x - 2:
		draw_line(Vector2(fx, r.end.y), Vector2(fx + rng.randf_range(-1, 1), r.end.y + 9), Color(0.85, 0.75, 0.6), 1.6)
		fx += 5.0


func _sign(r: Rect2) -> void:
	var bg: Color = [Color(0.92, 0.88, 0.78), Color(0.78, 0.85, 0.86), Color(0.94, 0.82, 0.5)][rng.randi() % 3]
	Ink.box(self, rng, r, bg, 2.6)
	Ink.squiggle(self, rng, r.grow(-6), [Color(0.75, 0.15, 0.12), Color(0.2, 0.3, 0.55), Color(0.35, 0.2, 0.45)][rng.randi() % 3], 3.2)


func _decor() -> void:
	var x := rng.randf_range(40.0, 160.0)
	while x < w - 60.0:
		if _free(x, 30.0):
			match rng.randi() % 5:
				0: _plant(Vector2(x, 0))
				1: _dish(Vector2(x, 0))
				2: _antenna(Vector2(x, 0))
				_: pass
		x += rng.randf_range(140.0, 300.0)


func _plant(p: Vector2) -> void:
	var leaves := []
	for i in 6:
		leaves.append([p + Vector2(rng.randf_range(-16, 16), -34 - rng.randf_range(0, 22)), rng.randf_range(9, 14)])
	Ink.blobs(self, leaves, Color(0.42, 0.56, 0.24), Color(0.32, 0.45, 0.18), 2.0)
	Ink.poly(self, rng, Ink.pts([p + Vector2(-15, -30), p + Vector2(15, -30), p + Vector2(11, 0), p + Vector2(-11, 0)]), Color(0.72, 0.38, 0.24), 2.4)


func _dish(p: Vector2) -> void:
	Ink.line(self, rng, Ink.pts([p, p + Vector2(0, -38)]), false, 3.0)
	var bowl := Ink.ellipse(p + Vector2(0, -52), 26, 20, 16, -PI * 0.15, PI * 0.95)
	Ink.poly(self, rng, bowl, Color(0.82, 0.8, 0.76), 2.4)
	draw_line(p + Vector2(2, -50), p + Vector2(22, -66), Ink.LINE, 2.0)


func _antenna(p: Vector2) -> void:
	Ink.line(self, rng, Ink.pts([p, p + Vector2(0, -90)]), false, 2.6)
	for k in 4:
		var y := -60.0 - k * 9.0
		var half := 26.0 - k * 5.0
		draw_line(p + Vector2(-half, y), p + Vector2(half, y), Ink.LINE, 2.0, true)


func _obstacle_tank(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	Ink.box(self, rng, Rect2(r.position.x + 6, r.end.y - 22, r.size.x - 12, 22), Color(0.45, 0.4, 0.36), 2.4)
	var body := Rect2(r.position.x, r.position.y + 10, r.size.x, r.size.y - 32)
	Ink.vgrad(self, body, Color(0.2, 0.42, 0.72), Color(0.12, 0.26, 0.5))
	Ink.line(self, rng, Ink.rect_pts(body), true, 3.0)
	for k in 3:
		var y := body.position.y + 14 + k * 18
		draw_line(Vector2(body.position.x + 2, y), Vector2(body.end.x - 2, y), Color(0.08, 0.16, 0.35), 2.2)
	draw_rect(Rect2(body.position.x + 8, body.position.y + 6, 7, body.size.y - 12), Color(0.55, 0.72, 0.92, 0.6))
	Ink.poly(self, rng, Ink.ellipse(Vector2(r.get_center().x, r.position.y + 10), r.size.x * 0.5, 9, 18), Color(0.25, 0.5, 0.8), 2.6)


func _obstacle_crate(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	Ink.box(self, rng, r, Color(0.6, 0.42, 0.26), 2.8)
	for k in 3:
		var y := r.position.y + 6 + k * 16
		draw_line(Vector2(r.position.x + 3, y), Vector2(r.end.x - 3, y), Color(0.38, 0.24, 0.13), 2.0)
	Ink.line(self, rng, Ink.pts([r.position + Vector2(4, 4), r.end - Vector2(4, 4)]), false, 2.0)


func _obstacle_rug(o: Dictionary) -> void:
	var x: float = o.x
	var s: Vector2 = KINDS.rug
	for px in [x, x + s.x]:
		Ink.box(self, rng, Rect2(px - 4, -s.y - 6, 8, s.y + 6), Color(0.36, 0.24, 0.16), 2.2)
	var rope := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		rope.append(Vector2(x + s.x * t, -s.y + 4 + sin(t * PI) * 8))
	draw_polyline(rope, Ink.LINE, 2.4, true)
	_rug(Rect2(x + 14, -s.y + 10, s.x - 28, s.y - 10 - RUG_CLEAR - 9))

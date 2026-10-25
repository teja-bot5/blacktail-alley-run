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
# Obstacles: visible size (px) and the one action that clears them.
# Slide obstacles hang from ropes/cables, so their hitbox extends up to the
# rope: they must be slid under, not jumped.
const KINDS := {
	"crate": {"size": Vector2(66, 58), "act": "jump", "min_speed": 0.0},
	"wall": {"size": Vector2(56, 76), "act": "jump", "min_speed": 0.0},
	"rug": {"size": Vector2(124, 82), "act": "slide", "min_speed": 0.0},
	"tank": {"size": Vector2(80, 98), "act": "jump", "min_speed": 500.0},
	"cable": {"size": Vector2(104, 74), "act": "slide", "min_speed": 540.0},
	"ac": {"size": Vector2(104, 72), "act": "jump", "min_speed": 600.0},
}
const CLEAR := 46.0     # free height under slide obstacles
const ROPE_TOP := -420.0

var w := 800.0
var gap_after := 0.0
var obstacles: Array = []  # {kind, act, x, rect (hitbox, local), hit}
var fish_spots: Array = []  # local positions
var wall: Color
var rng := RandomNumberGenerator.new()
var _seed := 0


## speed: run speed when the cat will reach this roof (px/s).
func setup(width: float, seed_value: int, with_obstacles: bool, speed := 430.0) -> void:
	w = width
	_seed = seed_value
	rng.seed = seed_value
	wall = WALLS[rng.randi() % WALLS.size()]
	if with_obstacles:
		var pool := []
		for k in KINDS:
			if speed >= KINDS[k].min_speed:
				pool.append(k)
		# Fairness: nothing where the cat can land after a gap jump (~0.7 s of
		# travel) plus reaction time; spacing allows landing + reacting again.
		var x := maxf(560.0, speed * 1.25) + rng.randf_range(0.0, 140.0)
		while true:
			var kind: String = pool[rng.randi() % pool.size()]
			var k: Dictionary = KINDS[kind]
			var sz: Vector2 = k.size
			if x + sz.x + speed * 0.8 + 60.0 > w:
				break
			add_obstacle(kind, x)
			x += sz.x + speed * 1.15 + rng.randf_range(0.0, 280.0)
	var fx2 := 150.0
	while fx2 < w - 200.0:
		if _free(fx2, 60.0) and rng.randf() < 0.35:
			for i in 4:
				fish_spots.append(Vector2(fx2 + i * 44.0, -36.0))
			fx2 += 260.0
		fx2 += 180.0
	queue_redraw()


func add_obstacle(kind: String, x: float) -> void:
	var k: Dictionary = KINDS[kind]
	var sz: Vector2 = k.size
	var hit := Rect2(x, -sz.y, sz.x, sz.y)
	if k.act == "slide":
		hit = Rect2(x, ROPE_TOP, sz.x, -CLEAR - ROPE_TOP)
	obstacles.append({"kind": kind, "act": k.act, "x": x, "rect": hit, "hit": false})
	for i in 3:  # fish trace the right line: arc over jumps, low under slides
		var fx := x + sz.x * 0.5 + (i - 1) * 46.0
		var fy := -22.0 if k.act == "slide" else -sz.y - 52.0 - (16.0 if i == 1 else 0.0)
		fish_spots.append(Vector2(fx, fy))


func _free(x: float, margin: float) -> bool:
	for o in obstacles:
		if x > o.x - margin - 180.0 and x < o.x + KINDS[o.kind].size.x + margin + 40.0:
			return false
	return true


func _draw() -> void:
	rng.seed = _seed * 7919 + 13
	var face := Rect2(0, 12, w, DEPTH)
	if gap_after > 0.0:  # dark alley in the gap: the drop must be unmistakable
		var gap := Rect2(w, 6, gap_after, DEPTH)
		draw_polygon(Ink.rect_pts(gap), PackedColorArray([Color(0.1, 0.05, 0.04, 0.55), Color(0.1, 0.05, 0.04, 0.55), Color(0.06, 0.03, 0.03, 0.95), Color(0.06, 0.03, 0.03, 0.95)]))
		for k in 3:
			var y0 := 40.0 + k * 28.0
			var wire := PackedVector2Array()
			for i in 9:
				var t := i / 8.0
				wire.append(Vector2(w + gap_after * t, y0 + sin(t * PI) * 22.0))
			draw_polyline(wire, Color(0.05, 0.03, 0.02, 0.8), 1.6, true)
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
	for ex in [-8.0, w + 8.0]:  # bright worn corners mark the roof edges
		draw_line(Vector2(ex, -4), Vector2(ex, 18), ROOF.lightened(0.45), 3.0)
		Ink.bricks(self, rng, Vector2(ex + (12.0 if ex < 0.0 else -12.0), 30), Vector2(16, 12), wall)
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


func _base_shadow(x: float, wid: float) -> void:
	draw_colored_polygon(Ink.ellipse(Vector2(x + wid * 0.5, 1), wid * 0.62, 6, 16), Color(0.15, 0.06, 0.03, 0.35))


func _obstacle_tank(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	_base_shadow(r.position.x, r.size.x)
	Ink.box(self, rng, Rect2(r.position.x + 6, r.end.y - 22, 8, 22), Color(0.3, 0.3, 0.32), 2.4)
	Ink.box(self, rng, Rect2(r.end.x - 14, r.end.y - 22, 8, 22), Color(0.3, 0.3, 0.32), 2.4)
	Ink.box(self, rng, Rect2(r.position.x + 2, r.end.y - 26, r.size.x - 4, 6), Color(0.36, 0.36, 0.38), 2.2)
	var body := Rect2(r.position.x, r.position.y + 10, r.size.x, r.size.y - 36)
	Ink.vgrad(self, body, Color(0.2, 0.42, 0.72), Color(0.11, 0.24, 0.48))
	for k in 3:
		var y := body.position.y + 14 + k * 17
		draw_line(Vector2(body.position.x + 2, y), Vector2(body.end.x - 2, y), Color(0.08, 0.16, 0.35), 2.4)
	draw_rect(Rect2(body.position.x + 9, body.position.y + 6, 8, body.size.y - 12), Color(0.6, 0.76, 0.95, 0.6))
	Ink.line(self, rng, Ink.rect_pts(body), true, 3.6)
	Ink.poly(self, rng, Ink.ellipse(Vector2(r.get_center().x, r.position.y + 10), r.size.x * 0.5, 9, 18), Color(0.27, 0.52, 0.82), 3.2)
	Ink.box(self, rng, Rect2(r.get_center().x - 9, r.position.y + 1, 18, 8), Color(0.15, 0.3, 0.55), 2.0)


func _obstacle_crate(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	_base_shadow(r.position.x, r.size.x)
	Ink.box(self, rng, r, Color(0.66, 0.46, 0.27), 3.6)
	Ink.box(self, rng, r.grow(-7), Color(0.6, 0.41, 0.24), 2.0)
	for k in 2:
		var y := r.position.y + 20 + k * 16
		draw_line(Vector2(r.position.x + 7, y), Vector2(r.end.x - 7, y), Color(0.38, 0.24, 0.13), 2.0)
	Ink.line(self, rng, Ink.pts([r.position + Vector2(8, 8), r.end - Vector2(8, 8)]), false, 3.0)
	for c in [r.position + Vector2(4, 4), Vector2(r.end.x - 4, r.position.y + 4), r.end - Vector2(4, 4), Vector2(r.position.x + 4, r.end.y - 4)]:
		draw_circle(c, 2.2, Ink.LINE)


func _obstacle_wall(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	_base_shadow(r.position.x, r.size.x)
	# Broken brick wall stub with a jagged (but nearly level) top.
	var top := PackedVector2Array([Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.position.y + 6)])
	var steps := 5
	for i in range(1, steps):
		top.append(Vector2(r.position.x + r.size.x * i / steps, r.position.y + (0.0 if i % 2 else 7.0)))
	top.append(Vector2(r.end.x, r.position.y + 4))
	top.append(r.end)
	draw_colored_polygon(top, Color(0.66, 0.31, 0.22))
	var y := r.end.y - 10.0
	var row := 0
	while y > r.position.y + 6:
		draw_line(Vector2(r.position.x + 1, y), Vector2(r.end.x - 1, y), Color(0.35, 0.15, 0.1), 1.6)
		var xx := r.position.x + (9.0 if row % 2 else 0.0)
		while xx < r.end.x:
			draw_line(Vector2(xx, y), Vector2(xx, y + 10), Color(0.35, 0.15, 0.1), 1.4)
			xx += 18.0
		y -= 10.0
		row += 1
	Ink.box(self, rng, Rect2(r.position.x - 2, r.position.y + 30, r.size.x + 4, 18), wall.lightened(0.05), 2.0)
	Ink.line(self, rng, top, true, 3.6)


func _obstacle_ac(o: Dictionary) -> void:
	var r: Rect2 = o.rect
	_base_shadow(r.position.x, r.size.x)
	for lx in [r.position.x + 8, r.end.x - 16]:
		Ink.box(self, rng, Rect2(lx, r.end.y - 10, 8, 10), Color(0.3, 0.3, 0.32), 2.0)
	var body := Rect2(r.position.x, r.position.y, r.size.x, r.size.y - 10)
	Ink.box(self, rng, body, Color(0.9, 0.89, 0.84), 3.6)
	var c := body.position + Vector2(36, body.size.y * 0.5)
	draw_circle(c, 24, Color(0.28, 0.28, 0.3))
	for k in 5:
		var a := TAU * k / 5.0 + 0.3
		draw_line(c, c + Vector2.from_angle(a) * 21, Color(0.78, 0.78, 0.75), 4.0)
	draw_arc(c, 24, 0, TAU, 28, Ink.LINE, 2.6, true)
	for k in 6:
		draw_line(body.position + Vector2(70, 10 + k * 8), body.position + Vector2(98, 10 + k * 8), Color(0.5, 0.5, 0.48), 2.0)


func _hang_line(x0: float, x1: float, low: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		p.append(Vector2(lerpf(x0, x1, t), low - (1.0 - sin(t * PI)) * 70.0))
	return p


func _obstacle_rug(o: Dictionary) -> void:
	var x: float = o.x
	var sz: Vector2 = KINDS.rug.size
	# Poles stand at the back edge of the roof (drawn muted = behind the cat).
	for px in [x - 26.0, x + sz.x + 26.0]:
		Ink.box(self, rng, Rect2(px - 4, -sz.y - CLEAR - 70, 8, sz.y + CLEAR + 70), Color(0.45, 0.36, 0.28), 1.6)
	draw_polyline(_hang_line(x - 26.0, x + sz.x + 26.0, -sz.y - CLEAR - 4), Ink.LINE, 2.6, true)
	_rug(Rect2(x, -sz.y - CLEAR, sz.x, sz.y - 9))


func _obstacle_cable(o: Dictionary) -> void:
	var x: float = o.x
	var sz: Vector2 = KINDS.cable.size
	# Low-sagging cable bundle from off-screen poles, with a shop sign hanging off it.
	for k in 4:
		var line := PackedVector2Array()
		for i in 17:
			var t := i / 16.0
			line.append(Vector2(x - 260 + (sz.x + 520) * t, ROPE_TOP + 40 + k * 6 + sin(t * PI) * (-ROPE_TOP - sz.y - CLEAR - 36 + k * 3)))
		draw_polyline(line, Ink.LINE, 2.6, true)
	for sx in [x + 14, x + sz.x - 14]:
		draw_line(Vector2(sx, -sz.y - CLEAR - 22), Vector2(sx, -sz.y - CLEAR), Ink.LINE, 2.0)
	var board := Rect2(x, -sz.y - CLEAR, sz.x, sz.y)
	Ink.box(self, rng, board, Color(0.95, 0.83, 0.42), 3.4)
	Ink.squiggle(self, rng, board.grow(-8), Color(0.72, 0.16, 0.12), 3.4)

class_name Backdrop
extends Node2D
## One seamless parallax strip (TW wide), drawn procedurally by `kind`.

const TW := 2560.0
const H := 720.0

var kind := "sky"
var rng := RandomNumberGenerator.new()


func _init(k: String) -> void:
	kind = k


func _draw() -> void:
	rng.seed = hash(kind)
	call("_" + kind)


func _sky() -> void:
	Ink.vgrad(self, Rect2(-TW, 0, TW * 3, H * 0.55), Color(0.36, 0.64, 0.88), Color(0.62, 0.8, 0.9))
	Ink.vgrad(self, Rect2(-TW, H * 0.55, TW * 3, H * 0.45), Color(0.62, 0.8, 0.9), Color(0.86, 0.84, 0.74))


func _clouds() -> void:
	for i in 6:
		var c := Vector2(i * TW / 6.0 + rng.randf_range(40, 220), rng.randf_range(70, 220))
		var puffs := []
		var n := rng.randi_range(5, 8)
		for k in n:
			var t := float(k) / (n - 1)
			puffs.append([c + Vector2(t * 260 - 130, -sin(t * PI) * rng.randf_range(20, 46)), rng.randf_range(26, 46)])
		puffs.append([c + Vector2(0, 14), 40.0])
		Ink.blobs(self, puffs, Color(0.97, 0.96, 0.92), Color(0.86, 0.88, 0.9), 2.0)
	for i in 3:
		var y := rng.randf_range(40, 110)
		var x := rng.randf_range(0, TW - 300)
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(160, 300), y + 4), Color(1, 1, 1, 0.55), 6.0, true)


func _far() -> void:
	var x := 0.0
	while x < TW:
		var w := rng.randf_range(40, 110)
		var top := rng.randf_range(170, 330)
		var col := Color(0.55, 0.64, 0.74).lerp(Color(0.66, 0.74, 0.8), rng.randf())
		draw_rect(Rect2(x, top, w, H - top), col)
		if rng.randf() < 0.3:
			draw_rect(Rect2(x + w * 0.3, top - 30, w * 0.25, 30), col)
		for wy in range(int(top) + 12, 470, 18):
			for wx in range(int(x) + 8, int(x + w) - 8, 14):
				if rng.randf() < 0.45:
					draw_rect(Rect2(wx, wy, 6, 8), col.lightened(0.18))
		x += w + rng.randf_range(-10, 30)


func _city(scale: float, top_min: float, top_max: float, haze: float, outline: float) -> void:
	var x := -20.0
	while x < TW - 40:
		var w := rng.randf_range(150, 300) * scale
		w = minf(w, TW - 40 - x)
		var top := rng.randf_range(top_min, top_max)
		var col: Color = Rooftop.WALLS[rng.randi() % Rooftop.WALLS.size()]
		if rng.randf() < 0.25:
			col = Color(0.86, 0.6, 0.58)
		col = col.lerp(Color(0.8, 0.85, 0.88), haze)
		var r := Rect2(x, top, w, H - top)
		Ink.vgrad(self, r, col, col.darkened(0.3))
		Ink.line(self, rng, Ink.rect_pts(r), true, outline)
		Ink.box(self, rng, Rect2(x - 4, top - 6, w + 8, 10), col.lightened(0.12), outline)
		draw_rect(Rect2(x, top + 4, w, 8), Color(0.15, 0.06, 0.03, 0.25))
		var rows := int((H - top - 40) / (70 * scale))
		for ry in rows:
			for cx in range(int(x + 22 * scale), int(x + w - 40 * scale), int(70 * scale)):
				if rng.randf() < 0.55:
					var wr := Rect2(cx, top + 34 * scale + ry * 70 * scale, 30 * scale, 38 * scale)
					Ink.box(self, rng, wr, Color(0.25, 0.2, 0.18).lerp(col, haze), outline * 0.8)
					if rng.randf() < 0.3:
						draw_rect(Rect2(wr.end.x + 3, wr.position.y, wr.size.x * 0.45, wr.size.y), Color(0.24, 0.55, 0.56).lerp(col, haze))
		if rng.randf() < 0.18:
			Ink.box(self, rng, Rect2(x + w * 0.2, top + 30 * scale, w * 0.6, 34 * scale), Color(0.93, 0.88, 0.76).lerp(col, haze * 0.6), outline)
			Ink.squiggle(self, rng, Rect2(x + w * 0.2, top + 30 * scale, w * 0.6, 34 * scale).grow(-4), Color(0.7, 0.18, 0.15).lerp(col, haze), 2.4 * scale)
		# Rooftop clutter: water tanks, dishes, laundry.
		var roll := rng.randf()
		if roll < 0.55:
			var tw := 46.0 * scale
			var tx := x + rng.randf_range(10, maxf(12, w - tw - 10))
			var tank_col := Color(0.18, 0.38, 0.7).lerp(Color(0.25, 0.32, 0.38), rng.randf() * 0.4).lerp(col, haze * 0.7)
			Ink.box(self, rng, Rect2(tx, top - 50 * scale, tw, 44 * scale), tank_col, outline)
			Ink.poly(self, rng, Ink.ellipse(Vector2(tx + tw / 2, top - 50 * scale), tw / 2, 6 * scale, 14), tank_col.lightened(0.15), outline)
		elif roll < 0.7:
			var dx := x + rng.randf_range(20, maxf(22, w - 20))
			Ink.poly(self, rng, Ink.ellipse(Vector2(dx, top - 24 * scale), 18 * scale, 14 * scale, 12, -PI * 0.1, PI * 0.95), Color(0.85, 0.83, 0.8).lerp(col, haze), outline)
		elif roll < 0.82:
			var lx := x + 10
			draw_line(Vector2(lx, top - 30 * scale), Vector2(lx + w - 20, top - 26 * scale), Ink.LINE, 1.5)
			for k in int((w - 30) / (26 * scale)):
				var cc: Color = [Color(0.85, 0.3, 0.25), Color(0.95, 0.9, 0.8), Color(0.3, 0.5, 0.7), Color(0.9, 0.7, 0.3)][rng.randi() % 4]
				draw_rect(Rect2(lx + 6 + k * 26 * scale, top - 28 * scale, 16 * scale, 20 * scale), cc.lerp(col, haze))
		if rng.randf() < 0.25:  # tree between buildings
			var tx2 := x + w
			var puffs := []
			for k in 6:
				puffs.append([Vector2(tx2 + rng.randf_range(-30, 30) * scale, top + rng.randf_range(20, 80) * scale), rng.randf_range(24, 38) * scale])
			Ink.blobs(self, puffs, Color(0.4, 0.58, 0.3).lerp(col, haze * 0.5), Color(0.3, 0.46, 0.22).lerp(col, haze * 0.5), outline)
		x += w + rng.randf_range(0, 24) * scale


func _mid() -> void:
	_city(0.8, 260, 380, 0.26, 1.6)


func _near() -> void:
	_city(1.15, 330, 430, 0.06, 2.4)


func _wires() -> void:
	var poles := [0.0, 760.0, 1500.0, 2140.0, TW]
	for i in poles.size():
		var px: float = poles[i]
		if i < poles.size() - 1:
			Ink.box(self, rng, Rect2(px - 7, 70, 14, H), Color(0.33, 0.22, 0.15), 2.4)
			Ink.box(self, rng, Rect2(px - 34, 92, 68, 8), Color(0.33, 0.22, 0.15), 2.0)
			Ink.box(self, rng, Rect2(px - 10, 150, 20, 26), Color(0.55, 0.55, 0.5), 2.0)
		if i == 0:
			continue
		var a: float = poles[i - 1]
		for k in 3:
			var y0 := 96.0 + k * 9
			var sag := 40.0 + k * 14 + rng.randf_range(0, 20)
			var wire := PackedVector2Array()
			for s in 25:
				var t := s / 24.0
				wire.append(Vector2(lerpf(a, px, t), y0 + sin(t * PI) * sag))
			draw_polyline(wire, Ink.LINE, 2.0, true)
			if k == 1 and rng.randf() < 0.8:
				for b in rng.randi_range(1, 3):
					var t2 := rng.randf_range(0.2, 0.8)
					_bird(Vector2(lerpf(a, px, t2), y0 + sin(t2 * PI) * sag))


func _bird(p: Vector2) -> void:
	var c := Color(0.1, 0.09, 0.1)
	draw_colored_polygon(Ink.ellipse(p + Vector2(0, -9), 7, 6, 10), c)
	draw_circle(p + Vector2(5, -16), 4, c)
	draw_colored_polygon(Ink.pts([p + Vector2(8, -17), p + Vector2(13, -15), p + Vector2(8, -14)]), c)
	draw_colored_polygon(Ink.pts([p + Vector2(-5, -9), p + Vector2(-14, -2), p + Vector2(-4, -5)]), c)
	draw_line(p + Vector2(-1, -3), p + Vector2(-1, 1), c, 1.2)
	draw_line(p + Vector2(2, -3), p + Vector2(2, 1), c, 1.2)

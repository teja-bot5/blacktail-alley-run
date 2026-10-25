class_name Fish
extends Node2D
## Golden fish-bone token (collectible), also reused as the HUD icon.

var collected := false
var _t := randf() * TAU


static func paint(ci: CanvasItem, at: Vector2, s: float) -> void:
	var body := Ink.ellipse(at, 17 * s, 10 * s, 18)
	var gold := Color(1.0, 0.82, 0.18)
	ci.draw_colored_polygon(body, gold)
	ci.draw_colored_polygon(Ink.pts([at + Vector2(-14, 0) * s, at + Vector2(-27, -11) * s, at + Vector2(-24, 0) * s, at + Vector2(-27, 11) * s]), gold)
	ci.draw_polyline(body, Ink.LINE, 2.4 * s, true)
	ci.draw_polyline(Ink.pts([at + Vector2(-14, 0) * s, at + Vector2(-27, -11) * s, at + Vector2(-24, 0) * s, at + Vector2(-27, 11) * s, at + Vector2(-14, 0) * s]), Ink.LINE, 2.2 * s, true)
	ci.draw_line(at + Vector2(-12, 0) * s, at + Vector2(10, 0) * s, Ink.LINE, 2.0 * s)
	for k in 4:
		var x := -8.0 + k * 5.0
		ci.draw_line(at + Vector2(x, -6) * s, at + Vector2(x + 2, 6) * s, Ink.LINE, 1.6 * s)
	ci.draw_circle(at + Vector2(10, -2) * s, 2.6 * s, Ink.LINE)
	ci.draw_circle(at + Vector2(-4, -5) * s, 2.5 * s, Color(1, 1, 0.85, 0.8))


func _process(delta: float) -> void:
	_t += delta * 4.0
	rotation = sin(_t) * 0.12
	if collected:
		scale += Vector2.ONE * delta * 6.0
		modulate.a -= delta * 5.0
		if modulate.a <= 0.0:
			queue_free()


func _draw() -> void:
	paint(self, Vector2.ZERO, 1.0)

class_name Hud
extends Control
## In-game HUD drawn in the comic style: cat icon + hearts, fish counter,
## pause button and the two thumb buttons (jump, slide).

const BTN_R := 62.0

var hearts := 3
var fish := 0
var show_controls := true
var _font_size := 44
var _rng := RandomNumberGenerator.new()


func jump_center() -> Vector2:
	return Vector2(size.x - 250, size.y - 105)


func slide_center() -> Vector2:
	return Vector2(size.x - 100, size.y - 105)


func pause_rect() -> Rect2:
	return Rect2(size.x - 92, 20, 68, 68)


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	_rng.seed = 5
	_cat_icon(Vector2(64, 58))
	for i in 3:
		_heart(Vector2(150 + i * 62, 56), i < hearts)
	Fish.paint(self, Vector2(size.x - 300, 54), 1.5)
	var txt := "× %03d" % fish
	var font := get_theme_default_font()
	var pos := Vector2(size.x - 250, 72)
	draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, 10, Ink.LINE)
	draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color(1, 0.98, 0.92))
	var pr := pause_rect()
	draw_rect(pr, Color(0.2, 0.2, 0.2, 0.85))
	draw_rect(pr, Ink.LINE, false, 3.0)
	draw_rect(Rect2(pr.position + Vector2(20, 16), Vector2(10, 36)), Color.WHITE)
	draw_rect(Rect2(pr.position + Vector2(38, 16), Vector2(10, 36)), Color.WHITE)
	if show_controls:
		_button(jump_center(), true)
		_button(slide_center(), false)


func _cat_icon(c: Vector2) -> void:
	var black := Color(0.05, 0.05, 0.06)
	draw_colored_polygon(Ink.pts([c + Vector2(-34, -6), c + Vector2(-30, -42), c + Vector2(-10, -24)]), black)
	draw_colored_polygon(Ink.pts([c + Vector2(34, -6), c + Vector2(30, -42), c + Vector2(10, -24)]), black)
	draw_colored_polygon(Ink.ellipse(c, 36, 30, 24), black)
	for s in [-1.0, 1.0]:
		var e := c + Vector2(14 * s, -2)
		draw_colored_polygon(Ink.ellipse(e, 10, 8, 14), Color(1, 0.8, 0.1))
		draw_colored_polygon(Ink.ellipse(e, 2.6, 7, 10), black)
	draw_colored_polygon(Ink.pts([c + Vector2(-4, 10), c + Vector2(4, 10), c + Vector2(0, 15)]), Color(0.5, 0.25, 0.28))


func _heart(c: Vector2, full: bool) -> void:
	var col := Color(0.86, 0.12, 0.14) if full else Color(0.35, 0.3, 0.3, 0.7)
	var p := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		p.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * 1.45)
	draw_colored_polygon(p, col)
	draw_polyline(p, Ink.LINE, 3.5, true)
	if full:
		draw_circle(c + Vector2(-9, -9), 5, Color(1, 0.6, 0.6, 0.8))


func _button(c: Vector2, jump: bool) -> void:
	draw_circle(c, BTN_R, Color(0.1, 0.1, 0.1, 0.38))
	draw_arc(c, BTN_R, 0, TAU, 48, Color(1, 1, 1, 0.9), 4.0, true)
	var w := Color(1, 1, 1, 0.95)
	if jump:  # leaping cat silhouette
		draw_colored_polygon(Ink.ellipse(c + Vector2(-2, 2), 26, 10, 16), w)
		draw_colored_polygon(Ink.pts([c + Vector2(18, -4), c + Vector2(34, -14), c + Vector2(30, 4), c + Vector2(20, 8)]), w)
		draw_colored_polygon(Ink.pts([c + Vector2(28, -12), c + Vector2(30, -22), c + Vector2(34, -13)]), w)
		draw_line(c + Vector2(-24, 0), c + Vector2(-40, -14), w, 5.0, true)
		draw_line(c + Vector2(12, 8), c + Vector2(30, 18), w, 5.0, true)
		draw_line(c + Vector2(-16, 8), c + Vector2(-34, 16), w, 5.0, true)
	else:  # arrow down onto a line
		draw_line(c + Vector2(0, -26), c + Vector2(0, 14), w, 9.0)
		draw_colored_polygon(Ink.pts([c + Vector2(-18, 6), c + Vector2(18, 6), c + Vector2(0, 26)]), w)
		draw_line(c + Vector2(-26, 32), c + Vector2(26, 32), w, 6.0)

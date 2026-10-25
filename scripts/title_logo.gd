class_name TitleLogo
extends Control
## Home-screen title treatment: hand-inked BLACKTAIL lettering in a vintage
## street-poster style (Teko Bold, OFL), with a cat tail curling off the final
## "L", an "ALLEY RUN" ribbon and a small hand-painted best-score sign.

const FONT := preload("res://assets/fonts/Teko-Bold.woff2")
const CREAM := Color(0.98, 0.9, 0.72)
const TERRACOTTA := Color(0.66, 0.24, 0.15)
const TEAL := Color(0.2, 0.47, 0.48)

var best := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	_rng.seed = 7  # same "hand" every frame: no shimmering outline
	var fs := int(clampf(size.x * 0.13, 96.0, 168.0))
	var text := "BLACKTAIL"
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := Vector2((size.x - tw) * 0.5, size.y * 0.06 + fs * 0.95)
	# Offset print shadow, then a rough ink outline built from jittered strokes.
	draw_string(FONT, base + Vector2(7, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, TERRACOTTA)
	for i in 6:
		var j := Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.6, 1.6))
		draw_string_outline(FONT, base + j, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(fs * 0.11), Ink.LINE)
	draw_string(FONT, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, CREAM)
	# Worn-print highlight along the top of the letters.
	draw_string(FONT, base + Vector2(0, -2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.12))
	_tail(base + Vector2(tw - fs * 0.04, -fs * 0.06), fs)
	var ribbon_y := base.y + fs * 0.12
	_ribbon(Vector2(size.x * 0.5, ribbon_y + fs * 0.2), fs)
	_best_sign(Vector2(size.x * 0.5, ribbon_y + fs * 0.64), fs)


## Black cat tail sweeping out of the foot of the "L" and curling over it.
func _tail(foot: Vector2, fs: float) -> void:
	var s := fs / 150.0
	var p := PackedVector2Array()
	var p0 := foot
	var p1 := foot + Vector2(40, 6) * s
	var p2 := foot + Vector2(52, -64) * s
	var p3 := foot + Vector2(30, -80) * s
	for i in 19:  # sweep out and up along a cubic Bezier...
		var t := i / 18.0
		var u := 1.0 - t
		p.append(p0 * u * u * u + p1 * 3.0 * u * u * t + p2 * 3.0 * u * t * t + p3 * t * t * t)
	for i in range(1, 7):  # ...then a small hook at the tip
		var a := -PI * 0.5 + i * 0.42  # tip hooks outward, away from the letters
		p.append(p3 + Vector2(0, 10) * s + Vector2(cos(a) * 10, sin(a) * 10) * s)
	var widths := []
	for i in p.size():
		widths.append(lerpf(15.0, 6.0, float(i) / p.size()) * s)
	_stroke(p, widths, s * 4.0, Ink.LINE)
	_stroke(p, widths, 0.0, Color(0.05, 0.048, 0.055))
	draw_circle(p[p.size() - 1], widths[widths.size() - 1] * 0.5, Color(0.05, 0.048, 0.055))


func _stroke(p: PackedVector2Array, widths: Array, grow: float, col: Color) -> void:
	for i in p.size() - 1:
		draw_line(p[i], p[i + 1], col, widths[i] + grow * 2.0, true)
		draw_circle(p[i], (widths[i] + grow * 2.0) * 0.5, col)


func _ribbon(c: Vector2, fs: float) -> void:
	var text := "ALLEY  RUN"
	var ts := int(fs * 0.3)
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
	var hw := tw * 0.5 + ts * 0.9
	var hh := ts * 0.48
	var notch := hh * 0.9
	var poly := Ink.pts([c + Vector2(-hw - notch, -hh), c + Vector2(hw + notch, -hh), c + Vector2(hw, 0),
		c + Vector2(hw + notch, hh), c + Vector2(-hw - notch, hh), c + Vector2(-hw, 0)])
	Ink.poly(self, _rng, poly, TERRACOTTA, 3.0)
	draw_line(c + Vector2(-hw + 6, -hh + 5), c + Vector2(hw - 6, -hh + 5), Color(1, 0.85, 0.7, 0.35), 2.0)
	draw_string(FONT, c + Vector2(-tw * 0.5, ts * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, CREAM)


## Small hand-painted street sign: secondary to the title, still readable.
func _best_sign(c: Vector2, fs: float) -> void:
	var label := "BEST"
	var value := str(best)
	var ls := int(fs * 0.17)
	var vs := int(fs * 0.26)
	var lw := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, ls).x
	var vw := FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, vs).x
	var w := lw + vw + fs * 0.32
	var h := vs * 0.95
	draw_set_transform(c, -0.03, Vector2.ONE)
	var r := Rect2(-w * 0.5, -h * 0.5, w, h)
	draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.25))
	Ink.box(self, _rng, r, TEAL, 3.0)
	Ink.line(self, _rng, Ink.rect_pts(r.grow(-5)), true, 1.6, CREAM.darkened(0.1))
	for nx in [r.position.x + 8, r.end.x - 8]:
		draw_circle(Vector2(nx, r.position.y + 8), 2.6, Ink.LINE)
	var x := r.position.x + fs * 0.12
	draw_string(FONT, Vector2(x, vs * 0.3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, CREAM.darkened(0.12))
	draw_string_outline(FONT, Vector2(x + lw + fs * 0.08, vs * 0.34), value, HORIZONTAL_ALIGNMENT_LEFT, -1, vs, 6, Ink.LINE)
	draw_string(FONT, Vector2(x + lw + fs * 0.08, vs * 0.34), value, HORIZONTAL_ALIGNMENT_LEFT, -1, vs, CREAM)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

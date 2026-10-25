extends Node2D
## BLACKTAIL: ALLEY RUN — 2D side-scrolling rooftop runner.
## User args (after `--`): --demo (autopilot, auto-restart)  --test=SECONDS

const GRAVITY := 2900.0
const JUMP_V := 1010.0
const CUT_GRAVITY := 2.2       # extra gravity once jump is released (variable height)
const COYOTE := 0.1
const BUFFER := 0.12
const SLIDE_TIME := 0.62
const STAND_H := 62.0
const SLIDE_H := 32.0
const CAT_W := 76.0
const FOOT := 20.0             # half foot width for ledge support
const SPEED0 := 430.0
const SPEED_MAX := 720.0
const CAT_SCREEN_X := 330.0
const SAVE := "user://save.cfg"

var state := "title"
var rng := RandomNumberGenerator.new()
var buildings: Array[Rooftop] = []
var fish_nodes: Array[Fish] = []
var next_x := -400.0
var next_top := 500.0

var cat: CatView
var cam: Camera2D
var world: Node2D
var hud: Hud
var overlay: Control
var title_lbl: Label
var sub_lbl: Label
var retry_btn: Button

var speed := SPEED0
var x := 0.0
var y := 500.0
var vy := 0.0
var grounded := true
var coyote := 0.0
var buffer := 0.0
var jump_held := false
var slide_t := 0.0
var invuln := 0.0
var hearts := 3
var fish := 0
var run_time := 0.0
var best := 0
var death := ""
var _last_building: Rooftop
var _touch_jump := -1
var _touch_start := Vector2.ZERO

var autopilot := false
var demo := false
var test_seconds := 0.0
var stats := {"jumps": 0, "slides": 0, "gaps": 0, "hits": 0, "deaths": 0, "restarts": 0, "fish": 0, "nan": false}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--demo":
			demo = true
			autopilot = true
		elif a.begins_with("--test="):
			test_seconds = float(a.get_slice("=", 1))
			autopilot = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		best = cfg.get_value("score", "best", 0)
	process_mode = Node.PROCESS_MODE_ALWAYS  # input must reach us while paused
	_build_parallax()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	cat = CatView.new()
	cat.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cat)
	cam = Camera2D.new()
	add_child(cam)
	_build_ui()
	_reset()
	if autopilot:
		_start()


func _build_parallax() -> void:
	for spec in [["sky", 0.0], ["clouds", 0.04], ["far", 0.1], ["mid", 0.3], ["near", 0.55], ["wires", 0.8]]:
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(spec[1], 1)
		if spec[0] != "sky":
			p.repeat_size = Vector2(Backdrop.TW, 0)
			p.repeat_times = 2
		p.add_child(Backdrop.new(spec[0]))
		add_child(p)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	hud = Hud.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.12, 0.06, 0.03, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	title_lbl = _label(overlay, 112, Color(1, 0.74, 0.15), -120)
	sub_lbl = _label(overlay, 34, Color(1, 0.97, 0.9), 30)
	retry_btn = Button.new()
	retry_btn.text = "  RUN AGAIN  "
	retry_btn.add_theme_font_size_override("font_size", 40)
	retry_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	retry_btn.position.y += 170
	retry_btn.focus_mode = Control.FOCUS_NONE
	retry_btn.pressed.connect(_start)
	overlay.add_child(retry_btn)


func _label(parent: Control, size_px: int, col: Color, dy: float) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Ink.LINE)
	l.add_theme_constant_override("outline_size", maxi(8, size_px / 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position.y = dy
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _reset() -> void:
	for b in buildings:
		b.queue_free()
	for f in fish_nodes:
		if is_instance_valid(f):
			f.queue_free()
	buildings.clear()
	fish_nodes.clear()
	rng.seed = 2026 if (autopilot or test_seconds > 0.0) else randi()
	next_x = -400.0
	next_top = 500.0
	speed = SPEED0
	x = 0.0
	y = next_top
	vy = 0.0
	grounded = true
	slide_t = 0.0
	invuln = 0.0
	hearts = 3
	fish = 0
	run_time = 0.0
	_last_building = null
	_spawn()
	_update_view(1.0)
	_show_overlay()


func _start() -> void:
	if state == "over":
		stats.restarts += 1
		_reset()
	state = "run"
	get_tree().paused = false
	_show_overlay()


func _show_overlay() -> void:
	overlay.visible = state != "run"
	hud.show_controls = state == "run"
	retry_btn.visible = state == "over"
	match state:
		"title":
			title_lbl.text = "BLACKTAIL"
			sub_lbl.text = "ALLEY RUN\n\nTap to run   ·   Best %d" % best
		"paused":
			title_lbl.text = "PAUSED"
			sub_lbl.text = "Tap to keep running"
		"over":
			title_lbl.text = death
			sub_lbl.text = "Fish %d   ·   Distance %dm\nScore %d   ·   Best %d" % [fish, _distance(), _score(), best]


func _distance() -> int:
	return int(x / CatView.PX_PER_M)


func _score() -> int:
	return _distance() + fish * 10


# ---------------- Level ----------------

func _spawn() -> void:
	var view_right := x + 2200.0
	while next_x < view_right:
		var first := buildings.is_empty()
		var w := 1500.0 if first else rng.randf_range(560.0, 1150.0)
		var top := next_top
		var b := Rooftop.new()
		b.position = Vector2(next_x, top)
		world.add_child(b)
		b.setup(w, rng.randi(), not first)
		buildings.append(b)
		for s in b.fish_spots:
			_add_fish(b.position + s)
		# Gap sized to the current jump distance, with the next roof's height.
		var reach := speed * 2.0 * JUMP_V / GRAVITY
		var gap := rng.randf_range(0.28, 0.55) * reach
		next_top = clampf(top + rng.randf_range(-60.0, 50.0), 430.0, 540.0)
		var a := Vector2(next_x + w - 10, top - 50)
		var c := Vector2(next_x + w + gap + 10, next_top - 50)
		for i in 5:
			var t := (i + 0.5) / 5.0
			_add_fish(a.lerp(c, t) + Vector2(0, -sin(t * PI) * 110.0))
		next_x += w + gap
	while buildings.size() > 2 and buildings[0].position.x + buildings[0].w < x - 900.0:
		buildings.pop_front().queue_free()


func _add_fish(p: Vector2) -> void:
	var f := Fish.new()
	f.position = p
	world.add_child(f)
	fish_nodes.append(f)


func _building_at(px: float) -> Rooftop:
	for b in buildings:
		if px >= b.position.x - FOOT and px <= b.position.x + b.w + FOOT:
			return b
	return null


# ---------------- Input ----------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		var k: int = event.keycode
		if k in [KEY_UP, KEY_W, KEY_SPACE]:
			_jump_input(event.pressed)
		elif k in [KEY_DOWN, KEY_S] and event.pressed:
			_slide()
		elif k in [KEY_P, KEY_ESCAPE] and event.pressed:
			_toggle_pause()
		elif k == KEY_ENTER and event.pressed and state != "run":
			_start()
	elif event is InputEventScreenTouch:
		if event.pressed:
			if state != "run":
				if state == "title":
					_start()
				elif state == "paused":
					_toggle_pause()
				return
			if hud.pause_rect().has_point(event.position):
				_toggle_pause()
			elif event.position.distance_to(hud.slide_center()) < Hud.BTN_R * 1.2:
				_slide()
			else:
				_touch_jump = event.index
				_touch_start = event.position
				_jump_input(true)
		elif event.index == _touch_jump:
			_touch_jump = -1
			_jump_input(false)
	elif event is InputEventScreenDrag and event.index == _touch_jump:
		if event.position.y - _touch_start.y > 60.0:  # swipe down = slide
			_touch_jump = -1
			_jump_input(false)
			_slide()


func _jump_input(pressed: bool) -> void:
	if pressed and state == "title":
		_start()
		return
	jump_held = pressed
	if pressed and state == "run":
		buffer = BUFFER


func _slide() -> void:
	if state != "run":
		return
	if slide_t <= 0.0:
		stats.slides += 1
	slide_t = SLIDE_TIME
	buffer = 0.0
	if not grounded:
		vy = maxf(vy, 900.0)  # dive down into the slide


func _toggle_pause() -> void:
	if state == "run":
		state = "paused"
	elif state == "paused":
		state = "run"
	get_tree().paused = state == "paused"
	_show_overlay()


# ---------------- Simulation ----------------

func _physics_process(dt: float) -> void:
	if test_seconds > 0.0:
		_test_step(dt)
	if state != "run":
		_update_view(dt)
		return
	run_time += dt
	speed = minf(SPEED0 + run_time * 7.0, SPEED_MAX)
	if autopilot:
		_autopilot()
	x += speed * dt
	_spawn()
	buffer = maxf(buffer - dt, 0.0)
	coyote = maxf(coyote - dt, 0.0)
	invuln = maxf(invuln - dt, 0.0)

	var b := _building_at(x)
	if buffer > 0.0 and (grounded or coyote > 0.0):
		vy = -JUMP_V
		grounded = false
		coyote = 0.0
		buffer = 0.0
		slide_t = 0.0
		stats.jumps += 1
	if grounded:
		if b == null:
			grounded = false
			coyote = COYOTE
		else:
			y = b.position.y
			slide_t = maxf(slide_t - dt, 0.0)
	if not grounded:
		var g := GRAVITY * (1.0 if (jump_held and vy < 0.0) else CUT_GRAVITY)
		vy += g * dt
		var ny := y + vy * dt
		if b != null and vy >= 0.0 and y <= b.position.y + 2.0 and ny >= b.position.y:
			y = b.position.y
			vy = 0.0
			grounded = true
			if _last_building != null and b != _last_building:
				stats.gaps += 1
		elif b != null and ny > b.position.y + 14.0 and y > b.position.y + 14.0:
			_die("SPLAT!")  # ran into the side of a taller building
			return
		else:
			y = ny
		if y > 900.0:
			_die("YOU FELL!")
			return
	if grounded and b != null:
		_last_building = b
	_collide()
	_update_view(dt)


func _collide() -> void:
	var h := SLIDE_H if slide_t > 0.0 else STAND_H
	var box := Rect2(x - CAT_W * 0.5, y - h, CAT_W, h)
	if invuln <= 0.0:
		for b in buildings:
			for o in b.obstacles:
				if not o.hit and box.intersects(Rect2(b.position + o.rect.position, o.rect.size).grow(-4)):
					o.hit = true
					hearts -= 1
					stats.hits += 1
					invuln = 1.2
					cat.rig.flinch = 1.0
					if hearts <= 0:
						_die("KNOCKED OUT!")
						return
	var centre := Vector2(x, y - h * 0.5)
	for f in fish_nodes:
		if is_instance_valid(f) and not f.collected and f.position.distance_to(centre) < 50.0:
			f.collected = true
			fish += 1
			stats.fish += 1
	fish_nodes = fish_nodes.filter(func(f): return is_instance_valid(f) and f.position.x > x - 900.0)


func _die(reason: String) -> void:
	death = reason
	state = "over"
	stats.deaths += 1
	if _score() > best:
		best = _score()
		var cfg := ConfigFile.new()
		cfg.set_value("score", "best", best)
		cfg.save(SAVE)
	_show_overlay()
	if demo:
		get_tree().create_timer(1.2).timeout.connect(_start)


func _update_view(_dt: float) -> void:
	cat.position = Vector2(x, y)
	cat.drive(speed if state == "run" else 0.0, vy, grounded, slide_t > 0.0, buffer > 0.0 and grounded)
	cat.flash(invuln > 0.0 and fmod(invuln, 0.2) < 0.1)
	cam.position = Vector2(x - CAT_SCREEN_X + 640.0, 360.0)
	hud.hearts = hearts
	hud.fish = fish
	if not x == x or not y == y:
		stats.nan = true


# ---------------- Autopilot & test ----------------

func _autopilot() -> void:
	var b := _building_at(x)
	if grounded and b != null and b.position.x + b.w - x < speed * 0.09 + 12.0:
		_jump_input(true)
	for bb in buildings:
		for o in bb.obstacles:
			var d: float = bb.position.x + o.rect.position.x - (x + CAT_W * 0.5)
			if d > 0.0 and d < speed * 0.16 + 14.0 and grounded:
				if o.kind == "rug":
					if slide_t <= 0.0:
						_slide()
				else:
					_jump_input(true)
	if vy > 0.0:
		jump_held = false


var _test_t := 0.0
var _phase := 0


func _test_step(dt: float) -> void:
	_test_t += dt
	match _phase:
		0:  # autopilot run
			if state == "over":
				_finish(false)
			elif _test_t > test_seconds * 0.7:
				autopilot = false
				jump_held = false
				_phase = 1
		1:  # hands off: must eventually die (gap or obstacles)
			if state == "over":
				_phase = 2
				_test_t = test_seconds * 0.7
				_start()
				autopilot = true
			elif _test_t > test_seconds * 0.7 + 15.0:
				_finish(false)
		2:
			if _test_t > test_seconds * 0.7 + 2.0:
				_finish(state == "run")


func _finish(restart_ok: bool) -> void:
	print("TEST_REPORT ", JSON.stringify(stats), " fish=", fish, " restart_ok=", restart_ok)
	var ok: bool = restart_ok and not stats.nan and stats.jumps > 2 and stats.slides > 0 and stats.gaps >= 2 and stats.fish > 0 \
		and stats.deaths == 1 and stats.restarts == 1
	print("TEST_RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)

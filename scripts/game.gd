extends Node2D
## BLACKTAIL: ALLEY RUN — 2D side-scrolling rooftop runner.
## User args (after `--`):
##   --demo                     autopilot, auto-restart (for capturing video)
##   --test=SECONDS             endurance test: autopilot run, forced death, restart
##   --scenario=KIND:none|act   single-obstacle test (KIND = Rooftop kind, "gap" or "touch")
##   --speed=PX                 fixed run speed for scenarios

const GRAVITY := 2900.0
const JUMP_V := 1010.0         # fixed arc: same height every jump (predictable)
const ANTIC := 0.06            # anticipation crouch before takeoff
const COYOTE := 0.1
const BUFFER := 0.14
const SLIDE_TIME := 0.62
const STAND_H := 62.0
const SLIDE_H := 34.0
const CAT_W := 56.0            # torso width; legs/tail are forgiven
const FORGIVE := 6.0           # obstacle hitboxes shrink by this much
const FOOT := 20.0             # half foot width for ledge support
const SPEED0 := 430.0
const SPEED_MAX := 720.0
const LAUNCH := 0.6            # seconds to accelerate from a sit to full run
const CAT_SCREEN_X := 330.0
const PX_PER_M := 239.0
const SAVE := "user://save.cfg"

var state := "title"
var rng := RandomNumberGenerator.new()
var buildings: Array[Rooftop] = []
var fish_nodes: Array[Fish] = []
var next_x := -400.0
var next_top := 500.0

var cat: Cat2D
var dust: Dust
var cam: Camera2D
var world: Node2D
var hud: Hud
var overlay: Control
var shade: ColorRect
var title_lbl: Label
var sub_lbl: Label
var play_btn: Button

var speed := 0.0
var x := 0.0
var y := 500.0
var vy := 0.0
var grounded := true
var coyote := 0.0
var buffer := 0.0
var antic := -1.0
var slide_t := 0.0
var invuln := 0.0
var hearts := 3
var fish := 0
var run_time := 0.0
var launch_t := LAUNCH
var best := 0
var death := ""
var _shake := 0.0
var _dip := 0.0
var _last_building: Rooftop
var _touch_id := -1
var _touch_start := Vector2.ZERO

var autopilot := false
var demo := false
var test_seconds := 0.0
var scenario := ""
var fixed_speed := 0.0
var stats := {"jumps": 0, "slides": 0, "gaps": 0, "hits": 0, "deaths": 0, "restarts": 0, "fish": 0, "nan": false}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--demo":
			demo = true
			autopilot = true
		elif a.begins_with("--test="):
			test_seconds = float(a.get_slice("=", 1))
			autopilot = true
		elif a.begins_with("--scenario="):
			scenario = a.get_slice("=", 1)
		elif a.begins_with("--speed="):
			fixed_speed = float(a.get_slice("=", 1))
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		best = cfg.get_value("score", "best", 0)
	process_mode = Node.PROCESS_MODE_ALWAYS  # input must reach us while paused
	_build_parallax()
	world = Node2D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	cat = Cat2D.new()
	cat.process_mode = Node.PROCESS_MODE_PAUSABLE
	cat.footfall.connect(func(p: Vector2): dust.puff(p, 1, 0.6))
	add_child(cat)
	dust = Dust.new()
	dust.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(dust)
	cam = Camera2D.new()
	add_child(cam)
	_build_ui()
	_reset()
	if autopilot or (scenario != "" and not scenario.begins_with("touch")):
		_start()


func _build_parallax() -> void:
	for spec in [["sky", 0.0], ["clouds", 0.04], ["far", 0.1], ["mid", 0.3], ["near", 0.55], ["wires", 0.8]]:
		var p := Parallax2D.new()
		p.scroll_scale = Vector2(spec[1], 1)
		if spec[0] != "sky":
			p.repeat_size = Vector2(Backdrop.TW, 0)
			p.repeat_times = 2
		if spec[0] == "clouds":
			p.autoscroll = Vector2(-9, 0)  # gentle ambient drift, also on the home screen
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
	shade = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)
	title_lbl = _label(overlay, 120, Color(1, 0.74, 0.15), -170)
	sub_lbl = _label(overlay, 34, Color(1, 0.97, 0.9), -40)
	play_btn = Button.new()
	play_btn.add_theme_font_size_override("font_size", 48)
	play_btn.add_theme_color_override("font_color", Ink.LINE)
	play_btn.add_theme_color_override("font_hover_color", Ink.LINE)
	play_btn.add_theme_color_override("font_pressed_color", Ink.LINE)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.74, 0.15) if st != "pressed" else Color(0.92, 0.6, 0.1)
		sb.border_color = Ink.LINE
		sb.set_border_width_all(6)
		sb.set_corner_radius_all(18)
		sb.content_margin_left = 54
		sb.content_margin_right = 54
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = 6
		sb.shadow_offset = Vector2(4, 6)
		play_btn.add_theme_stylebox_override(st, sb)
	play_btn.focus_mode = Control.FOCUS_NONE
	play_btn.pressed.connect(_on_play)
	overlay.add_child(play_btn)


func _label(parent: Control, size_px: int, col: Color, dy: float) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Ink.LINE)
	l.add_theme_constant_override("outline_size", maxi(10, size_px / 5))
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
	speed = 0.0
	x = 0.0
	y = next_top
	vy = 0.0
	grounded = true
	antic = -1.0
	slide_t = 0.0
	invuln = 0.0
	hearts = 3
	fish = 0
	run_time = 0.0
	_last_building = null
	if scenario != "" and not scenario.begins_with("touch"):
		_build_scenario()
	else:
		_spawn()
	_update_view(1.0)
	_show_overlay()


func _on_play() -> void:
	if state == "paused":
		_toggle_pause()
	else:
		_start()


func _start() -> void:
	# From the home screen the cat stands up out of its sit; restarts are instant.
	launch_t = 0.0 if state == "title" else LAUNCH
	if state == "over":
		stats.restarts += 1
		_reset()
	state = "run"
	get_tree().paused = false
	_show_overlay()


func _show_overlay() -> void:
	overlay.visible = state != "run"
	hud.show_controls = state == "run"
	hud.visible = state != "title"
	shade.color = Color(0.12, 0.06, 0.03, 0.12 if state == "title" else 0.5)
	match state:
		"title":
			title_lbl.text = "BLACKTAIL"
			sub_lbl.text = "ALLEY RUN\nBest %d" % best
			play_btn.text = "PLAY"
		"paused":
			title_lbl.text = "PAUSED"
			sub_lbl.text = ""
			play_btn.text = "RESUME"
		"over":
			title_lbl.text = death
			sub_lbl.text = "Fish %d   ·   Distance %dm\nScore %d   ·   Best %d" % [fish, _distance(), _score(), best]
			play_btn.text = "RUN AGAIN"
	play_btn.reset_size()
	var vs := get_viewport_rect().size
	play_btn.position = Vector2((vs.x - play_btn.size.x) * 0.5, vs.y * 0.5 + (150.0 if state == "title" else 120.0))


func _distance() -> int:
	return int(maxf(x, 0.0) / PX_PER_M)


func _score() -> int:
	return _distance() + fish * 10


# ---------------- Level ----------------

func _spawn() -> void:
	var view_right := x + 2400.0
	while next_x < view_right:
		var first := buildings.is_empty()
		var sp := maxf(speed, SPEED0)
		var w := (6000.0 if scenario == "touch" else 1500.0) if first else rng.randf_range(700.0, 1250.0) + sp * 0.5
		var top := next_top
		# Gap sized to the jump distance at the speed the cat will have here.
		var reach := (sp + 60.0) * 2.0 * JUMP_V / GRAVITY
		var gap := rng.randf_range(0.3, 0.55) * reach
		next_top = clampf(top + rng.randf_range(-60.0, 50.0), 430.0, 540.0)
		_add_building(next_x, top, w, gap, not first, sp + 60.0)
		next_x += w + gap
	while buildings.size() > 2 and buildings[0].position.x + buildings[0].w < x - 900.0:
		buildings.pop_front().queue_free()


func _add_building(bx: float, top: float, w: float, gap: float, obstacles: bool, sp: float) -> Rooftop:
	var b := Rooftop.new()
	b.position = Vector2(bx, top)
	b.gap_after = gap
	world.add_child(b)
	b.setup(w, rng.randi(), obstacles, sp)
	buildings.append(b)
	for s in b.fish_spots:
		_add_fish(b.position + s)
	if gap > 0.0:
		var a := Vector2(bx + w - 10, top - 50)
		var c := Vector2(bx + w + gap + 10, next_top - 50)
		for i in 5:
			var t := (i + 0.5) / 5.0
			_add_fish(a.lerp(c, t) + Vector2(0, -sin(t * PI) * 110.0))
	return b


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
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k in [KEY_UP, KEY_W, KEY_SPACE]:
			if state == "run":
				_jump()
			elif state != "paused":
				_start()
		elif k in [KEY_DOWN, KEY_S]:
			_slide()
		elif k in [KEY_P, KEY_ESCAPE]:
			_toggle_pause()
		elif k == KEY_ENTER and state != "run":
			_on_play()
	elif event is InputEventScreenTouch and state == "run":
		if event.pressed:
			if hud.pause_rect().has_point(event.position):
				_toggle_pause()
			elif event.position.distance_to(hud.slide_center()) < Hud.BTN_R * 1.25:
				_slide()
			elif event.position.distance_to(hud.jump_center()) < Hud.BTN_R * 1.25:
				_jump()
			else:  # anywhere else: tap = jump, swipe down = slide (decided on drag)
				_touch_id = event.index
				_touch_start = event.position
				_jump()
		elif event.index == _touch_id:
			_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _touch_id and state == "run":
		if event.position.y - _touch_start.y > 50.0:
			_touch_id = -1
			if antic >= 0.0:  # the tap queued a jump: it was really a swipe down
				antic = -1.0
			buffer = 0.0
			_slide()


func _jump() -> void:
	if state == "run":
		buffer = BUFFER


func _slide() -> void:
	if state != "run":
		return
	if slide_t <= 0.0:
		stats.slides += 1
	slide_t = SLIDE_TIME
	buffer = 0.0
	antic = -1.0
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
	if scenario != "":
		_scenario_step(dt)
	if state != "run":
		_update_view(dt)
		return
	run_time += dt
	launch_t += dt
	var target := fixed_speed if fixed_speed > 0.0 else minf(SPEED0 + run_time * 7.0, SPEED_MAX)
	speed = target * smoothstep(0.0, LAUNCH, launch_t)
	if autopilot:
		_autopilot()
	x += speed * dt
	if scenario == "" or scenario.begins_with("touch"):
		_spawn()
	buffer = maxf(buffer - dt, 0.0)
	coyote = maxf(coyote - dt, 0.0)
	invuln = maxf(invuln - dt, 0.0)

	var b := _building_at(x)
	if buffer > 0.0 and antic < 0.0 and (grounded or coyote > 0.0) and launch_t > LAUNCH * 0.5:
		antic = 0.0 if grounded else ANTIC  # no crouch when leaving a ledge late
		buffer = 0.0
		slide_t = 0.0
	if antic >= 0.0:
		antic += dt
		if antic >= ANTIC:
			antic = -1.0
			vy = -JUMP_V
			grounded = false
			coyote = 0.0
			stats.jumps += 1
	if grounded:
		if b == null:
			grounded = false
			coyote = COYOTE
		else:
			y = b.position.y
			if slide_t > 0.0:
				slide_t = maxf(slide_t - dt, 0.0)
				if fmod(slide_t, 0.08) < dt:
					dust.puff(Vector2(x - 20, y), 1, 0.7)
	if not grounded:
		vy += GRAVITY * dt
		var ny := y + vy * dt
		if b != null and vy >= 0.0 and y <= b.position.y + 2.0 and ny >= b.position.y:
			y = b.position.y
			grounded = true
			dust.puff(Vector2(x, y), 6, clampf(vy / 900.0, 0.6, 1.3))
			_dip = clampf(vy / 1200.0, 0.3, 1.0) * 5.0
			vy = 0.0
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


func cat_box() -> Rect2:
	var h := SLIDE_H if slide_t > 0.0 else STAND_H
	return Rect2(x - CAT_W * 0.5, y - h, CAT_W, h)


func _collide() -> void:
	var box := cat_box()
	if invuln <= 0.0:
		for b in buildings:
			for o in b.obstacles:
				if not o.hit and box.intersects(Rect2(b.position + o.rect.position, o.rect.size).grow(-FORGIVE)):
					o.hit = true
					hearts -= 1
					stats.hits += 1
					invuln = 1.2
					cat.flinch = 1.0
					_shake = 1.0
					if hearts <= 0:
						_die("KNOCKED OUT!")
						return
	var centre := box.get_center()
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
	_shake = 1.0
	if _score() > best:
		best = _score()
		var cfg := ConfigFile.new()
		cfg.set_value("score", "best", best)
		cfg.save(SAVE)
	_show_overlay()
	if demo:
		get_tree().create_timer(1.2).timeout.connect(_start)


func _update_view(dt: float) -> void:
	cat.position = Vector2(x, y)
	cat.speed = speed if state == "run" else 0.0
	cat.vy = vy
	cat.grounded = grounded
	cat.sliding = slide_t > 0.0
	cat.sitting = state == "title" or (state == "run" and launch_t < LAUNCH * 0.35)
	cat.crouch = 1.0 if antic >= 0.0 else 0.0
	cat.modulate.a = 0.4 if invuln > 0.0 and fmod(invuln, 0.2) < 0.1 else 1.0
	_shake = move_toward(_shake, 0.0, dt * 4.0)
	_dip = move_toward(_dip, 0.0, dt * 30.0)
	var vw := get_viewport_rect().size.x
	cam.position = Vector2(x - CAT_SCREEN_X + vw * 0.5, 360.0)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 6.0 * _shake + Vector2(0, _dip)
	hud.hearts = hearts
	hud.fish = fish
	if not x == x or not y == y:
		stats.nan = true


# ---------------- Autopilot & tests ----------------

## Distance (cat front → obstacle hitbox) at which to press jump so the fixed
## arc clears an obstacle of this size, centred in the safe window.
func jump_trigger(o: Dictionary) -> float:
	var r: Rect2 = o.rect.grow(-FORGIVE)
	var h := -r.position.y + 2.0
	var disc := JUMP_V * JUMP_V - 2.0 * GRAVITY * h
	if disc <= 0.0:
		return -1.0
	var t1 := (JUMP_V - sqrt(disc)) / GRAVITY
	var t2 := (JUMP_V + sqrt(disc)) / GRAVITY
	var d_min := speed * t1
	var d_max := speed * t2 - r.size.x - CAT_W
	return (d_min + d_max) * 0.5 + speed * ANTIC


func _autopilot() -> void:
	var b := _building_at(x)
	if grounded and b != null and b.position.x + b.w - x < speed * 0.1 + 14.0:
		_jump()
	for bb in buildings:
		for o in bb.obstacles:
			var d: float = bb.position.x + o.rect.position.x + FORGIVE - (x + CAT_W * 0.5)
			if d <= 0.0 or not grounded:
				continue
			if o.act == "slide":
				if d < speed * 0.1 + 6.0 and slide_t <= 0.0:
					_slide()
			elif d < jump_trigger(o) and antic < 0.0:
				_jump()


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
	var ok: bool = restart_ok and not stats.nan and stats.jumps > 2 and stats.gaps >= 2 and stats.fish > 0 \
		and stats.deaths == 1 and stats.restarts == 1
	print("TEST_RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)


func _build_scenario() -> void:
	var kind := scenario.get_slice(":", 0)
	var sp := fixed_speed if fixed_speed > 0.0 else SPEED0
	if kind == "gap":
		var reach := sp * 2.0 * JUMP_V / GRAVITY
		next_top = 470.0
		_add_building(-400.0, 500.0, 1700.0, 0.55 * reach, false, sp)
		_add_building(1300.0 + 0.55 * reach, 470.0, 1500.0, 0.0, false, sp)
	else:
		var b := _add_building(-400.0, 500.0, 3000.0, 0.0, false, sp)
		b.add_obstacle(kind, 1500.0)
		b.queue_redraw()


var _sc_t := 0.0
var _sc_done := false


func _scenario_step(dt: float) -> void:
	if _sc_done:
		return
	_sc_t += dt
	var kind := scenario.get_slice(":", 0)
	var act := scenario.get_slice(":", 1)
	if kind == "touch":
		_touch_scenario()
		return
	autopilot = act == "act"
	var end_x := 2600.0 if kind == "gap" else 1100.0 + 800.0
	if state == "over" or x > end_x or _sc_t > 12.0:
		_sc_done = true
		var hit: bool = stats.hits > 0
		var died: bool = state == "over"
		var expect_ok: bool = (not hit and not died and x > end_x and (stats.gaps == 1 or kind != "gap")) if act == "act" else (died if kind == "gap" else hit)
		print("SCENARIO %s %s speed=%d hit=%s died=%s gaps=%d -> %s" % [kind, act, int(speed), hit, died, stats.gaps, "PASS" if expect_ok else "FAIL"])
		get_tree().quit(0 if expect_ok else 1)


## Drives the real input path with synthetic touch events: PLAY button,
## tap-to-jump, swipe-down-to-slide, and the on-screen buttons.
func _touch_scenario() -> void:
	var t := _sc_t
	var vs := get_viewport_rect().size
	var steps := [
		[0.3, "play"], [1.5, "tap"], [1.55, "release"], [1.7, "c_tap"], [2.6, "swipe"], [2.65, "drag"], [2.7, "lift"],
		[2.8, "c_swipe"], [3.6, "slide_btn"], [3.7, "c_slide"], [4.6, "jump_btn"], [4.8, "c_jump"], [5.6, "check"],
	]
	for s in steps:
		if t >= s[0] and t - (1.0 / 60.0) < s[0]:
			var mid := Vector2(vs.x * 0.3, vs.y * 0.45)
			match s[1]:
				"play":
					var c := play_btn.get_global_rect().get_center()
					_send_touch(c, true)
					_send_touch(c, false)
				"tap":
					stats["j0"] = stats.jumps
					_send_touch(mid, true)
				"release":
					_send_touch(mid, false)
				"c_tap":
					stats["tap_jump"] = stats.jumps > stats.j0
				"swipe":
					stats["s0"] = stats.slides
					_send_touch(mid, true)
				"drag":
					var d := InputEventScreenDrag.new()
					d.position = mid + Vector2(0, 90)
					Input.parse_input_event(d)
				"lift":
					_send_touch(mid + Vector2(0, 90), false)
				"c_swipe":
					stats["swipe_slide"] = stats.slides > stats.s0
				"slide_btn":
					stats["s1"] = stats.slides
					_send_touch(hud.slide_center(), true)
					_send_touch(hud.slide_center(), false)
				"c_slide":
					stats["slide_btn"] = stats.slides > stats.s1
				"jump_btn":
					stats["j1"] = stats.jumps
					_send_touch(hud.jump_center(), true)
					_send_touch(hud.jump_center(), false)
				"c_jump":
					stats["jump_btn"] = stats.jumps > stats.j1
				"check":
					_sc_done = true
					var ok: bool = stats.get("started", false) and stats.get("title_still", false) and stats.get("tap_jump", false) \
						and stats.get("swipe_slide", false) and stats.get("slide_btn", false) and stats.get("jump_btn", false)
					print("SCENARIO touch ", JSON.stringify(stats), " -> ", "PASS" if ok else "FAIL")
					get_tree().quit(0 if ok else 1)
	if t > 0.2 and t < 0.3:
		stats["title_still"] = state == "title" and x == 0.0 and speed == 0.0
	if t > 1.2 and state == "run":
		stats["started"] = true


func _send_touch(p: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = p
	e.pressed = pressed
	Input.parse_input_event(e)


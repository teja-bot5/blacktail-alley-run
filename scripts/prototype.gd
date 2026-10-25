extends Node3D
## Cat-movement prototype: rooftop strip, swipe controls, camera modes,
## slow-motion and an autopilot for hands-free review and automated checks.
##
## User args (after `--`): --demo  --cam=chase|side|front|cycle  --slowmo  --test=SECONDS

const CAMS := ["CHASE", "SIDE", "FRONT"]

var runner: CatRunner
var world: World
var cam: Camera3D
var cam_mode := 0
var cam_cycle := false
var autopilot := false
var slowmo := false
var fish_count := 0
var bumps := 0
var test_seconds := 0.0
var elapsed := 0.0
var stats := {"jumps": 0, "slides": 0, "lane_changes": 0, "max_lat_vel": 0.0, "nan": false}

var _hud: Label
var _btns := {}
var _touch_start := Vector2.ZERO
var _touching := false
var _hit_ids := {}
var _side_sign := -1.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--demo":
			autopilot = true
		elif a == "--slowmo":
			slowmo = true
		elif a.begins_with("--cam="):
			var m := a.get_slice("=", 1).to_upper()
			cam_cycle = m == "CYCLE"
			cam_mode = maxi(CAMS.find(m), 0)
		elif a.begins_with("--test="):
			test_seconds = float(a.get_slice("=", 1))
			autopilot = true
	_setup_environment()
	world = World.new()
	add_child(world)
	runner = CatRunner.new()
	add_child(runner)
	cam = Camera3D.new()
	cam.fov = 62.0
	cam.near = 0.05
	cam.far = 120.0
	add_child(cam)
	_setup_hud()
	world.update(runner.position.z)
	_place_camera(1.0)
	_apply_timescale()


func _setup_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.48, 0.70, 0.86)
	sm.sky_horizon_color = Color(0.93, 0.84, 0.74)
	sm.ground_horizon_color = Color(0.86, 0.74, 0.62)
	sm.ground_bottom_color = Color(0.55, 0.42, 0.33)
	sm.sun_angle_max = 20.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.92, 0.82, 0.70)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.90, 0.76)
	sun.light_energy = 1.25
	sun.rotation_degrees = Vector3(-38, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 18.0
	add_child(sun)


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(24, 120)
	_hud.add_theme_font_size_override("font_size", 30)
	_hud.add_theme_color_override("font_color", Color(0.15, 0.1, 0.08))
	_hud.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.88))
	_hud.add_theme_constant_override("outline_size", 8)
	layer.add_child(_hud)
	var row := HBoxContainer.new()
	row.position = Vector2(16, 36)
	row.add_theme_constant_override("separation", 12)
	layer.add_child(row)
	for id in ["SLOW-MO", "CAMERA", "AUTO"]:
		var b := Button.new()
		b.text = id
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(200, 72)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_on_button.bind(id))
		row.add_child(b)
		_btns[id] = b
	var hint := Label.new()
	hint.text = "Swipe ← → to switch lanes · ↑ jump · ↓ slide"
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(1, 0.96, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.08))
	hint.add_theme_constant_override("outline_size", 6)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position.y -= 70
	layer.add_child(hint)


func _on_button(id: String) -> void:
	match id:
		"SLOW-MO":
			slowmo = not slowmo
			_apply_timescale()
		"CAMERA":
			cam_mode = (cam_mode + 1) % CAMS.size()
		"AUTO":
			autopilot = not autopilot


func _apply_timescale() -> void:
	Engine.time_scale = 0.3 if slowmo else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touching = true
		elif _touching:
			_touching = false
			_swipe(event.position - _touch_start)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A: _act("left")
			KEY_RIGHT, KEY_D: _act("right")
			KEY_UP, KEY_W, KEY_SPACE: _act("jump")
			KEY_DOWN, KEY_S: _act("slide")


func _swipe(d: Vector2) -> void:
	if d.length() < 40.0:
		return
	if absf(d.x) > absf(d.y):
		_act("right" if d.x > 0 else "left")
	else:
		_act("slide" if d.y > 0 else "jump")


func _act(a: String) -> void:
	match a:
		"left":
			if runner.lane > -1: stats.lane_changes += 1
			runner.move_lane(-1)
		"right":
			if runner.lane < 1: stats.lane_changes += 1
			runner.move_lane(1)
		"jump":
			if runner.grounded: stats.jumps += 1
			runner.jump()
		"slide":
			if not runner.is_sliding(): stats.slides += 1
			runner.do_slide()


func _physics_process(delta: float) -> void:
	elapsed += delta
	world.update(runner.position.z)
	if autopilot:
		_autopilot()
	_check_collisions()
	stats.max_lat_vel = maxf(stats.max_lat_vel, absf(runner.lat_vel))
	if not runner.position.is_finite() or not runner.rig.body.rotation.is_finite():
		stats.nan = true
	if cam_cycle:
		cam_mode = int(elapsed / 4.0) % CAMS.size()
	if test_seconds > 0.0 and elapsed >= test_seconds:
		_finish_test()


func _process(delta: float) -> void:
	_place_camera(delta)
	for f in world.fish:
		if is_instance_valid(f.node):
			f.node.rotation.y += delta * 3.0
	_hud.text = "FISH %d   BUMPS %d\n%s CAM%s%s" % [fish_count, bumps, CAMS[cam_mode],
		"  ·  SLOW-MO" if slowmo else "", "  ·  AUTO" if autopilot else ""]


func _place_camera(delta: float) -> void:
	var p := runner.position
	var pos: Vector3
	var look: Vector3
	match CAMS[cam_mode]:
		"CHASE":
			pos = Vector3(p.x * 0.6, 0.85 + p.y * 0.45, p.z + 1.75)
			look = Vector3(p.x * 0.8, 0.26 + p.y * 0.55, p.z - 1.3)
		"SIDE":
			if absf(p.x) > 0.3:
				_side_sign = -signf(p.x)
			pos = Vector3(p.x + 1.25 * _side_sign, 0.32 + p.y * 0.6, p.z - 0.05)
			look = p + Vector3(0, 0.2, 0)
		"FRONT":
			pos = p + Vector3(0.55, 0.42, -1.25)
			pos.y = 0.42 + p.y * 0.5
			look = p + Vector3(0, 0.24, 0)
	var t := 1.0 - exp(-12.0 * delta)
	cam.position = cam.position.lerp(pos, t) if delta < 1.0 else pos
	cam.look_at(look, Vector3.UP)


func _check_collisions() -> void:
	var p := runner.position
	for o in world.obstacles:
		var id: int = o.node.get_instance_id()
		if _hit_ids.has(id):
			continue
		if runner.collides(o.kind, o.lane, o.z, o.depth):
			_hit_ids[id] = true
			bumps += 1
			runner.rig.flinch = 1.0
	for f in world.fish:
		if is_instance_valid(f.node) and absf(f.z - p.z) < 0.35 and absf(f.lane * CatRunner.LANE_W - p.x) < 0.45 and p.y < 0.9:
			f.node.queue_free()
			fish_count += 1


## Simple reactive pilot: dodges whatever is ahead in the lane, chases fish otherwise.
func _autopilot() -> void:
	var p := runner.position
	var threat = null
	for o in world.obstacles:
		var d: float = p.z - o.z
		if d > 0.1 and d < 3.2 and (o.lane == runner.lane) and not _hit_ids.has(o.node.get_instance_id()):
			if threat == null or d < p.z - threat.z:
				threat = o
	if threat != null:
		var d: float = p.z - threat.z
		match threat.kind:
			"jump":
				if d < 1.5 and runner.grounded: _act("jump")
			"slide":
				if d < 1.2 and runner.grounded and not runner.is_sliding(): _act("slide")
			"wall":
				if d < 3.0: _dodge_to_free_lane()
		return
	# Chase the nearest fish ahead if its lane is clear.
	var best = null
	for f in world.fish:
		var d: float = p.z - f.z
		if d > 1.0 and d < 7.0 and (best == null or d < p.z - best.z):
			best = f
	if best != null and best.lane != runner.lane and _lane_clear(best.lane, 4.0):
		_act("right" if best.lane > runner.lane else "left")


func _dodge_to_free_lane() -> void:
	for dir in [1, -1]:
		var l: int = runner.lane + dir
		if l >= -1 and l <= 1 and _lane_clear(l, 3.5):
			_act("right" if dir > 0 else "left")
			return


func _lane_clear(lane: int, dist: float) -> bool:
	for o in world.obstacles:
		var d: float = runner.position.z - o.z
		if o.lane == lane and d > -0.5 and d < dist:
			return false
	return true


func _finish_test() -> void:
	var report := {
		"seconds": snappedf(elapsed, 0.01), "distance_m": snappedf(runner.distance, 0.1),
		"fish": fish_count, "bumps": bumps, "max_height_m": snappedf(runner.max_height, 0.01),
		"jumps": stats.jumps, "slides": stats.slides, "lane_changes": stats.lane_changes,
		"max_lat_vel": snappedf(stats.max_lat_vel, 0.01), "nan": stats.nan,
	}
	print("TEST_REPORT ", JSON.stringify(report))
	var ok: bool = not stats.nan and stats.jumps > 0 and stats.slides > 0 and stats.lane_changes > 0 \
		and fish_count > 0 and runner.max_height > 0.5
	print("TEST_RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
